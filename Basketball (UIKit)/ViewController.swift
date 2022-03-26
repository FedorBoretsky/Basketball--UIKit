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
    
    // Scale factor for AR object.
    var scaleFactor = 0.25
    
    // Scale vector for AR object.
    var scaleVector: SCNVector3 {
        SCNVector3(scaleFactor, scaleFactor, scaleFactor)
    }

    
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
        let backboardNode =  extractNodeFromScene(named: "art.scnassets/backboard.scn")
        
        // Add phisics.
        backboardNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: backboardNode))
        
        // Output result.
        return backboardNode
    }
    
    func makeBallNode() -> SCNNode {
        return extractNodeFromScene(named: "art.scnassets/ball.scn")
    }
    
    func extractNodeFromScene(named sceneName: String) -> SCNNode {
        let scene = SCNScene(named: sceneName)!
        let node = scene.rootNode.clone()
        return node
    }
    
//    func makeBallByCode() -> SCNNode {
//        // Create geometry.
//        let geometry = SCNSphere(radius: 0.125)
//        geometry.firstMaterial?.diffuse.contents = UIImage(named: "ball_texture")
//
//        // Create node.
//        let node = SCNNode(geometry: geometry)
//
//        // Output result.
//        return node
//    }
        
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
        switch appMode {
        case .placeBackboard:
            
            let hitPoint = sender.location(in: sceneView)
            
            guard let result = sceneView.hitTest(hitPoint, types: .existingPlaneUsingExtent).first
            else { return }
            
            guard let anchor = result.anchor as? ARPlaneAnchor, anchor.alignment == .vertical
            else { return }

            // Create and arrange Backboard
            let backboardNode = makeBackboardNode()
            backboardNode.simdTransform = result.worldTransform
            backboardNode.eulerAngles.x -= .pi / 2
            backboardNode.scale = scaleVector
            
            // Show Backboard
            sceneView.scene.rootNode.addChildNode(backboardNode)
            
            // Remove vertical planes visualisation.
            configuration.planeDetection = []
            sceneView.session.run(configuration, options: .removeExistingAnchors)
            
            // Change game phase.
            appMode = .throwBalls

        case .throwBalls:
            throwBall()
        }
    }
    
    func throwBall() {
        // Get current frame.
        guard let frame = sceneView.session.currentFrame
        else { return }
        
        // Get camera transform.
        let cameraTransform = frame.camera.transform
        let matrixCameraTransfor = SCNMatrix4(cameraTransform)
        
        // Get ball node.
        let ball = makeBallNode()
        
        // Arrange ball.
        ball.simdTransform = cameraTransform
        ball.scale = scaleVector
        
        // Add phisics.
        ball.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape())
        
        // Apply force.
        let force: Float = -2
        let x = matrixCameraTransfor.m31 * force
        let y = matrixCameraTransfor.m32 * force
        let z = matrixCameraTransfor.m33 * force
        ball.physicsBody?.applyForce(SCNVector3(x, y, z), asImpulse: true)
        
        // Show ball.
        sceneView.scene.rootNode.addChildNode(ball)
    }

}
