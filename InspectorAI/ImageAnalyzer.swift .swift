import Foundation
import UIKit
import CoreML
import Vision

class ImageAnalyzer {
    private let model: VNCoreMLModel

    init?() {
        // ここでは TinyYOLOv3 という生成されたモデルクラスを利用しています
        guard let coreMLModel = try? YOLOv3(configuration: MLModelConfiguration()).model,
              let vnModel = try? VNCoreMLModel(for: coreMLModel) else {
            return nil
        }
        self.model = vnModel
    }

    /// UIImage を解析し、検出結果を非同期で返す
    func analyze(image: UIImage, completion: @escaping ([VNRecognizedObjectObservation]?) -> Void) {
        guard let ciImage = CIImage(image: image) else {
            completion(nil)
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                print("Vision リクエストエラー: \(error.localizedDescription)")
                completion(nil)
                return
            }
            let observations = request.results as? [VNRecognizedObjectObservation]
            completion(observations)
        }
        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Vision リクエスト実行失敗: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
}

