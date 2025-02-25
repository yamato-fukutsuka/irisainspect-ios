// ARRealityView.swift
import SwiftUI
import RealityKit
import ARKit
import Amplify
import ZIPFoundation

struct ARRealityView: UIViewRepresentable {
    @Binding var isScanning: Bool
    let project: Project
    
    let onFinishUpload: ((String) -> Void)?
    let onFastMovement: ((Bool) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(isScanning: $isScanning,
                           project: project,
                           onFinishUpload: onFinishUpload,
                           onFastMovement: onFastMovement)
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false
        
        let config = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        }
        config.environmentTexturing = .automatic
        
        arView.session.delegate = context.coordinator
        arView.session.run(config)
        
        arView.debugOptions.insert(.showSceneUnderstanding)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        let scanningNow = isScanning
        if context.coordinator.wasScanning != scanningNow {
            if scanningNow {
                context.coordinator.startCapture()
            } else {
                context.coordinator.stopCaptureAndUpload(arView: uiView)
            }
            context.coordinator.wasScanning = scanningNow
        }
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        @Binding var isScanning: Bool
        let project: Project
        
        let onFinishUpload: ((String) -> Void)?
        let onFastMovement: ((Bool) -> Void)?
        
        var wasScanning = false
        
        private var frameIndex = 0
        private let captureInterval = 30
        
        private var tempFolder: URL!
        private var lastCameraPosition: SIMD3<Float>?
        private var lastTimestamp: Double?
        
        private let speedThreshold: Float = 0.2
        
        init(isScanning: Binding<Bool>,
             project: Project,
             onFinishUpload: ((String) -> Void)?,
             onFastMovement: ((Bool) -> Void)?) {
            self._isScanning = isScanning
            self.project = project
            self.onFinishUpload = onFinishUpload
            self.onFastMovement = onFastMovement
            super.init()
            
            let uuid = UUID().uuidString
            tempFolder = FileManager.default.temporaryDirectory.appendingPathComponent("ARData_\(uuid)")
            try? FileManager.default.createDirectory(at: tempFolder, withIntermediateDirectories: true, attributes: nil)
        }
        
        func startCapture() {
            print("[AR] 撮影開始")
            frameIndex = 0
            lastCameraPosition = nil
            lastTimestamp = nil
        }
        
        func stopCaptureAndUpload(arView: ARView) {
            print("[AR] 撮影停止 → アップロード開始")
            // セッションのリセット
            let config = ARWorldTrackingConfiguration()
            arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
            arView.session.pause()
            
            guard let zipURL = zipTempFolder() else {
                onFinishUpload?("[AR] zip失敗")
                return
            }
            let keyName = "arData/\(UUID().uuidString).zip"
            
            Task {
                do {
                    // uploadFile は完了クロージャを受け取らず、タスクオブジェクトを返すので、.value を await する
                    let uploadedKey = try await Amplify.Storage.uploadFile(
                        key: keyName,
                        local: zipURL,
                        options: .init(accessLevel: .private)
                    ).value
                    
                    // getURL も同様に async/await で結果を取得
                    let url = try await Amplify.Storage.getURL(
                        key: uploadedKey,
                        options: .init(accessLevel: .private)
                    )
                    
                    let msg = "[AR] ARデータアップロード完了: \(url.absoluteString)"
                    DispatchQueue.main.async {
                        self.onFinishUpload?(msg)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.onFinishUpload?("アップロード失敗: \(error)")
                    }
                }
            }
        }

        
        private func zipTempFolder() -> URL? {
            let zipName = "arData_\(UUID().uuidString).zip"
            let zipURL = tempFolder.appendingPathComponent(zipName)
            do {
                guard let archive = Archive(url: zipURL, accessMode: .create) else { return nil }
                let fileURLs = try FileManager.default.contentsOfDirectory(at: tempFolder, includingPropertiesForKeys: nil)
                for fileURL in fileURLs {
                    if fileURL.lastPathComponent == zipName { continue }
                    try archive.addEntry(with: fileURL.lastPathComponent,
                                         fileURL: fileURL,
                                         compressionMethod: .deflate)
                }
                return zipURL
            } catch {
                print("zipエラー: \(error.localizedDescription)")
                return nil
            }
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard isScanning else { return }
            captureFrame(frame)
        }
        
        private func captureFrame(_ frame: ARFrame) {
            frameIndex += 1
            checkCameraSpeed(frame)
            
            // フレーム間引き
            guard frameIndex % captureInterval == 0 else { return }
            
            let fileURL = tempFolder.appendingPathComponent("frame_\(frameIndex).png")
            let pixelBuffer = frame.capturedImage
            
            DispatchQueue.global(qos: .utility).async {
                if let data = self.convertFrameToPNG(pixelBuffer: pixelBuffer) {
                    do {
                        try data.write(to: fileURL)
                        print("[AR] frame \(self.frameIndex) 保存完了")
                    } catch {
                        print("frame保存失敗: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        private func convertFrameToPNG(pixelBuffer: CVPixelBuffer) -> Data? {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage.pngData()
        }
        
        private func checkCameraSpeed(_ frame: ARFrame) {
            let nowPos = frame.camera.transform.position3
            let nowTime = frame.timestamp
            if let lastPos = lastCameraPosition, let lastTime = lastTimestamp {
                let dist = distance(nowPos, lastPos)
                let dt = Float(nowTime - lastTime)
                if dt > 0 {
                    let speed = dist / dt
                    onFastMovement?(speed > speedThreshold)
                }
            }
            lastCameraPosition = nowPos
            lastTimestamp = nowTime
        }
    }
}

// 拡張
extension simd_float4x4 {
    var position3: SIMD3<Float> {
        SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

