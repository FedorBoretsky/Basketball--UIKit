//
//  ViewController.swift
//  Basketball (UIKit)
//
//  Created by Fedor Boretskiy on 14.03.2022.
//

import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - IBOutlet
    
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: - Properties
    
    // Phases of game.
    enum AppMode {
        case placeBackboard
        case throwBalls
    }
    var appMode: AppMode = .placeBackboard
    
    // AR configuration.
    let configuration = ARWorldTrackingConfiguration()
    
    // MARK: - ViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Planes detection
        configuration.planeDetection = [.vertical]
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - AR Vertical plane visualisation
    
    func makeDetectedPlaneNode(for anchor: ARPlaneAnchor) -> SCNNode {
        // Create mesh
        let width = CGFloat(anchor.extent.x)
        let height = CGFloat(anchor.extent.z)
        let mesh = SCNPlane(width: width, height: height)
        
        // Setup appearance
        let texture = UIColor(red: 0, green: 1, blue: 0, alpha: 0.75)
        mesh.firstMaterial?.diffuse.contents = texture
        
        // Create and setup node
        let node = SCNNode(geometry: mesh)
        node.simdPosition = anchor.center
        node.eulerAngles.x -= .pi / 2
        
        return node
    }
    
    func updateDetectedPlaneNode(parentNode: SCNNode, anchor: ARPlaneAnchor) {
        // Get plane objects
        guard let detectedPlaneNode = parentNode.childNodes.first,
              let planeMesh = detectedPlaneNode.geometry as? SCNPlane
        else { return }
        
        // Update size
        let extent = anchor.extent
        planeMesh.width = CGFloat(extent.x)
        planeMesh.height = CGFloat(extent.z)
        
        // Update center
        detectedPlaneNode.simdPosition = anchor.center
    }
    
    // MARK: - AR Basketball visualization
    
    func makeBackboardNode() -> SCNNode {
        return extractNodeFromScene(named: "art.scnassets/backboard.scn")
    }
    
    func makeBallNode() -> SCNNode {
        return extractNodeFromScene(named: "art.scnassets/ball.scn")
    }
    
    func extractNodeFromScene(named sceneName: String) -> SCNNode {
        let scene = SCNScene(named: sceneName)!
        let node = scene.rootNode.clone()
        return node
    }
    
    func makeBallByCode() -> SCNNode {
        // Create geometry.
        let geometry = SCNSphere(radius: 0.125)
        geometry.firstMaterial?.diffuse.contents = UIImage(named: "ball_texture")
        
        // Create node.
        let node = SCNNode(geometry: geometry)
        
        // Output result.
        return node
    }
    

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Check type of recognition
        guard let planeAnchor = anchor as? ARPlaneAnchor,
              planeAnchor.alignment == .vertical
        else { return }
        
        // Show detected plane
        node.addChildNode(makeDetectedPlaneNode(for: planeAnchor))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Check type of recognition
        guard let planeAnchor = anchor as? ARPlaneAnchor,
              planeAnchor.alignment == .vertical
        else { return }
        
        // Update plane
        updateDetectedPlaneNode(parentNode: node, anchor: planeAnchor)
    }
    
    // MARK: - IBAction
    
    @IBAction func tapScreen(_ sender: UITapGestureRecognizer) {
        //
        let hitPoint = sender.location(in: sceneView)
        
        guard let result = sceneView.hitTest(hitPoint, types: .existingPlaneUsingExtent).first
        else { return }
        
        guard let anchor = result.anchor as? ARPlaneAnchor, anchor.alignment == .vertical
        else { return }
        
        switch appMode {
        case .placeBackboard:
            
            // Create and arrange Backboard
            let backboardNode = makeBackboardNode()
            backboardNode.simdTransform = result.worldTransform
            backboardNode.eulerAngles.x -= .pi / 2
            let scale = 0.25
            backboardNode.scale = SCNVector3(scale, scale, scale)
            
            // Show Backboard
            sceneView.scene.rootNode.addChildNode(backboardNode)
            
            // Remove vertical planes visualisation.
            configuration.planeDetection = []
            sceneView.session.run(configuration, options: .removeExistingAnchors)
            
            // Change game phase.
            appMode = .throwBalls

        case .throwBalls:
            break
        }
    }
    
    
}
