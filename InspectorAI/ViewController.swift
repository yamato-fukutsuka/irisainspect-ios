//
//  ViewController.swift
//  (もしStoryboard/UIViewControllerベースを使う場合の例)
//
import UIKit
import ARKit
import RealityKit

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 例: ARセッションの構成
        arView.session.delegate = self
        arView.automaticallyConfigureSession = false
        
        let configuration = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            configuration.sceneReconstruction = .meshWithClassification
        }
        configuration.environmentTexturing = .automatic
        
        arView.session.run(configuration)
        arView.debugOptions.insert(.showSceneUnderstanding)
        
        arView.renderOptions = [.disableMotionBlur]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // 例: フレーム更新処理
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("ARSession failed: \(error.localizedDescription)")
    }
}

