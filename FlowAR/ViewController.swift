//
//  ViewController.swift
//  FlowAR
//
//  Created by Josh Bourke on 8/5/19.
//  Copyright © 2019 Josh Bourke. All rights reserved.
//

// What we are going to need.


//First we will need to create a tab bar for the app to navigate between views.
//Second we will need the AR Screen or the camera to be able to identify what flower is in the view. Also label the flower in augmented reality
//Third we will need the app to be able to send the name of the flower and possibly a picture of that flower into our discovered flowers tab.
//Fourth we will need to make sure the app will save the flowers that the person has already discovered.

//Things we will need to know for this

//how to create 3d text in augmented reality
//how to perform a vision request so we are able to run a photo through a core ML model.
//How to persist data into a table view.
//How to save data to user default to make sure the persons discovered flowers will remain in the table view.



import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    
    private var flowerModel = FLowerClassifier()
    
    private var hitTestResult : ARHitTestResult!
    
    private var visionRequest = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView = ARSCNView(frame: self.view.frame)
        self.view.addSubview(self.sceneView)
        
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        registerGestureRecognizers()
    }
    
    
    private func registerGestureRecognizers(){
        
        let tapGestureRecognizers = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizers)
    
    }
    @objc func tapped(recognizers: UIGestureRecognizer){
        
        let sceneView = recognizers.view as! ARSCNView
        let touchLocation = self.sceneView.center
        
        guard let currentFrame = sceneView.session.currentFrame else{
            return
        }
        
        let hitTestResults = sceneView.hitTest(touchLocation, types: .featurePoint)
        
        if hitTestResults.isEmpty{
            return
        }
        
        guard let hitTestResult = hitTestResults.first else {
            return
        }
        
       self.hitTestResult = hitTestResult
        
        let pixelBuffer = currentFrame.capturedImage
        
        performVisionRequest(pixelBuffer: pixelBuffer)
    }
    
    
    private func performVisionRequest(pixelBuffer: CVPixelBuffer) {
        
        
        let visionModel = try! VNCoreMLModel(for: self.flowerModel.model)
        
        let request = VNCoreMLRequest(model: visionModel) {(request, error) in
            
            if error != nil{
                return
            }
            
            guard let observations = request.results else {
                return
                
            }
            
            let observation = observations.first as! VNClassificationObservation
            
            print("Name \(observation.identifier) and confidence is \(observation.confidence)")
            
            DispatchQueue.main.async {
                self.displayPredictions(text: observation.identifier)
            }
        }
       
        request.imageCropAndScaleOption = .centerCrop
        self.visionRequest = [request]
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: [:])
        
        DispatchQueue.global().async {
            try! imageRequestHandler.perform(self.visionRequest)
        }
    }
    
    @objc func pixelBuffer(){
        
        guard let currentFrame = sceneView.session.currentFrame else {
            return
        }
        
        let pixelBufferCaptured = currentFrame.capturedImage
        
        performVisionRequest(pixelBuffer: pixelBufferCaptured)
    }
    
    
    private func displayPredictions(text: String){
        
        let node = createText(text: text)
        
    }
    
    
    private func createText(text: String) -> SCNNode{
        
        let parentNode = SCNNode()
        
        return parentNode
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

 
}
