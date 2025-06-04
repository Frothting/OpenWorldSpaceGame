import SpriteKit
import GameController

class ControlsManager {
    // Properties
    var scene: SKScene
    var player: Player
    var sceneCamera: SKCameraNode
    var physicalController: GCController?
    
    // Control UI Elements
    var controller: SKShapeNode
    var forwardButton: SKSpriteNode
    var fireButton: SKSpriteNode
    var grabButton: SKSpriteNode
    
    // Other properties
    var circleRadius: CGFloat = 100
    var circleAngle: CGFloat = 0.0
    
    //Other
    var activeTouches = [UITouch: String]()
    var fireTimer: Timer?
    
    
    init(scene: SKScene, player: Player, camera: SKCameraNode) {
        self.scene = scene
        self.player = player
        self.sceneCamera = camera
        self.controller = SKShapeNode()
        self.forwardButton = SKSpriteNode()
        self.fireButton = SKSpriteNode()
        self.grabButton = SKSpriteNode()
        
        setupControls()
        setupPhysicalController()
        
        // Setup controller detection
        NotificationCenter.default.addObserver(self, selector: #selector(controllerConnected), name: NSNotification.Name.GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnectController), name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupControls() {
        makeController()
        makeForwardButton()
        makeFireButton()
        makeGrabButton()
    }
    
    func makeController() {
        self.circleRadius = scene.frame.width / 4
        let circle = SKShapeNode(circleOfRadius: self.circleRadius)
        circle.position = CGPoint(x: -scene.frame.width / 4, y: -scene.frame.height / 3)
        circle.name = "controller"
        
        let subCircle = SKShapeNode(circleOfRadius: 20)
        subCircle.position = CGPoint(x: circleRadius, y: 0)
        subCircle.fillColor = .yellow
        
        circle.addChild(subCircle)
        
        self.controller = circle
        
        sceneCamera.addChild(circle)
    }
    
    func makeForwardButton() {
        self.forwardButton = SKSpriteNode(color: .blue, size: CGSize(width: 100, height: 100))
        forwardButton.position = CGPoint(x: scene.frame.width / 4, y: (-scene.frame.height / 3) + 110)
        forwardButton.zPosition = 3
        forwardButton.name = "forwardButton"
        sceneCamera.addChild(forwardButton)
    }
    
    func makeFireButton() {
        self.fireButton = SKSpriteNode(color: .red, size: CGSize(width: 100, height: 100))
        fireButton.position = CGPoint(x: scene.frame.width / 4, y: -scene.frame.height / 3)
        fireButton.zPosition = 3
        fireButton.name = "fireButton"
        sceneCamera.addChild(fireButton)
    }
    
    func makeGrabButton() {
        self.grabButton = SKSpriteNode(color: .gray, size: CGSize(width: 100, height: 100))
        grabButton.position = CGPoint(x: scene.frame.width / 4, y: (-scene.frame.height / 3) - 110)
        grabButton.zPosition = 3
        grabButton.name = "grabButton"
        sceneCamera.addChild(grabButton)
    }
    
    func setupPhysicalController() {
        if let existingController = GCController.current {
            let extendedGamepad = existingController.extendedGamepad

            // Handle left thumbstick for rotation
            extendedGamepad?.leftThumbstick.valueChangedHandler = { [weak self] thumbstick, xValue, yValue in
                guard let self = self else { return }
                if xValue == 0 && yValue == 0 {
                    // Thumbstick is in neutral position, do nothing
                    return
                }
                let newAngle = atan2(yValue, xValue)
                let oldAngle = self.player.angle

                let diffAngle = abs(CGFloat(newAngle) - oldAngle).truncatingRemainder(dividingBy: 2 * CGFloat.pi)
                let angleToRotateBy = min(diffAngle, 2 * CGFloat.pi - diffAngle)
                let sign = self.rotationDirection(previousAngle: oldAngle, currentAngle: CGFloat(newAngle))
                self.player.rotate(by: angleToRotateBy * sign)
                self.circleAngle = CGFloat(newAngle)
                self.player.angle = CGFloat(newAngle)
            }

            // Button A for shooting
            extendedGamepad?.buttonA.pressedChangedHandler = { [weak self] button, value, pressed in
                guard let self = self else { return }
                if pressed {
                    // Start firing timer
                    if self.fireTimer == nil {
                        self.fireTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
                            guard let self = self else { return }
                            if let nodeToShoot = self.closestNode(to: self.player) {
                                self.player.shoot(towards: nodeToShoot)
                            }
                        }
                    }
                } else {
                    // Button released, stop firing
                    self.fireTimer?.invalidate()
                    self.fireTimer = nil
                }
            }
            
            // Button B for boosting
            extendedGamepad?.buttonB.pressedChangedHandler = { [weak self] button, value, pressed in
                guard let self = self else { return }
                if pressed {
                    // Start boosting
                    player.shouldBoost = true
                } else {
                    // Button released, stop boosting
                    player.shouldBoost = false
                }
            }

            // Button B for thrusting (moving forward)
            extendedGamepad?.rightTrigger.pressedChangedHandler = { [weak self] button, value, pressed in
                guard let self = self else { return }
                if pressed {
                    self.player.shouldMoveFowards = true
                    self.player.shouldMoveBackwards = false
                } else {
                    // Button released, stop moving forward
                    self.player.shouldMoveFowards = false
                    self.player.shouldMoveBackwards = false
                }
            }

            // Optional: Map other buttons if needed
            // For example, map the "X" button to grab
            extendedGamepad?.leftTrigger.pressedChangedHandler = { [weak self] button, value, pressed in
                guard let self = self else { return }
                if pressed {
                    if !self.player.isGrabbing {
                        if let nodeToGrab = self.closestNode(to: self.player) {
                            self.player.isGrabbing = true
                            self.player.grab(node: nodeToGrab)
                            self.drawLineBetweenNodes(nodeA: self.player, nodeB: nodeToGrab, in: self.scene)
                        }
                    }
                }
                else {
                    self.player.isGrabbing = false
                    self.scene.physicsWorld.removeAllJoints()
                    if let grabLine = self.scene.childNode(withName: "grabLine") as? SKShapeNode {
                        grabLine.removeFromParent()
                    }
                }
            }
            
        }
    }
    
    @objc func controllerConnected() {
        setupPhysicalController()
        let controller = sceneCamera.childNode(withName: "controller")
        let fireButton = sceneCamera.childNode(withName: "fireButton")
        let forwardButton = sceneCamera.childNode(withName: "forwardButton")
        let grabButton = sceneCamera.childNode(withName: "grabButton")
        
        controller?.alpha = 0.0
        fireButton?.alpha = 0.0
        forwardButton?.alpha = 0.0
        grabButton?.alpha = 0.0
    }
    
    @objc func disconnectController() {
        print("Controller disconnected")
        let controller = sceneCamera.childNode(withName: "controller")
        let fireButton = sceneCamera.childNode(withName: "fireButton")
        let forwardButton = sceneCamera.childNode(withName: "forwardButton")
        let grabButton = sceneCamera.childNode(withName: "grabButton")
        
        controller?.alpha = 1.0
        fireButton?.alpha = 1.0
        forwardButton?.alpha = 1.0
        grabButton?.alpha = 1.0
    }
    
    func update(_ currentTime: TimeInterval) {
        controller.zRotation = circleAngle
        player.angle = circleAngle
    }
    
    // Touch handling methods
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            let touchLocationInScene = touch.location(in: scene)
            let touchNodes = scene.nodes(at: touchLocationInScene)
            
            if touchNodes.contains(where: { $0.name == "forwardButton" }) {
                activeTouches[touch] = "forwardButton"
                player.shouldMoveFowards = true
                player.shouldMoveBackwards = false
            }
            
            if touchNodes.contains(where: { $0.name == "fireButton" }) {
                activeTouches[touch] = "fireButton"
                // Start the firing timer if it's not already running
                if fireTimer == nil {
                    fireTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
                        guard let self = self else { return }
                        if let nodeToShoot = self.closestNode(to: self.player) {
                            self.player.shoot(towards: nodeToShoot)
                        }
                    }
                }
            }
            
            if touchNodes.contains(where: { $0.name == "grabButton" }) {
                activeTouches[touch] = "grabButton"
                if !player.isGrabbing {
                    if let nodeToGrab = closestNode(to: player) {
                        player.isGrabbing = true
                        player.grab(node: nodeToGrab)
                        drawLineBetweenNodes(nodeA: player, nodeB: nodeToGrab, in: scene)
                    }
                } else {
                    player.isGrabbing = false
                    scene.physicsWorld.removeAllJoints()
                    if let grabLine = scene.childNode(withName: "grabLine") as? SKShapeNode {
                        grabLine.removeFromParent()
                    }
                }
            }
        }
    }

    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let buttonName = activeTouches[touch] {
                activeTouches.removeValue(forKey: touch)
                
                if buttonName == "forwardButton" {
                    // Stop moving forward if no other touches are active on the forward button
                    if !activeTouches.values.contains("forwardButton") {
                        player.shouldMoveFowards = false
                        player.shouldMoveBackwards = false
                    }
                }
                
                if buttonName == "fireButton" {
                    // Invalidate the firing timer if no other touches are active on the fire button
                    if !activeTouches.values.contains("fireButton") {
                        fireTimer?.invalidate()
                        fireTimer = nil
                    }
                }
                
                if buttonName == "grabButton" {
                    // Handle releasing the grab button if needed
                    if !activeTouches.values.contains("grabButton") && player.isGrabbing {
                        player.isGrabbing = false
                        scene.physicsWorld.removeAllJoints()
                        if let grabLine = scene.childNode(withName: "grabLine") as? SKShapeNode {
                            grabLine.removeFromParent()
                        }
                    }
                }
            }
        }
    }
    
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let convertedTouchLocation = touch.location(in: sceneCamera)
            if convertedTouchLocation.x < 0 { // control stick
                let oldAngle = controller.zRotation
                let controllerPosition = controller.position
                let newAngle = calculateAngle(center: controllerPosition, point: convertedTouchLocation)
                
                let diffAngle = abs(newAngle - oldAngle).truncatingRemainder(dividingBy: 2 * .pi)
                
                let angleToRotateBy = min(diffAngle, 2 * Double.pi - diffAngle)
                
                let sign = rotationDirection(previousAngle: oldAngle, currentAngle: newAngle)
                player.rotate(by: angleToRotateBy * sign)
                self.circleAngle = newAngle
            }
        }
    }
    
    // Helper methods
    func calculateAngle(center: CGPoint, point: CGPoint) -> CGFloat {
        let dx = point.x - center.x
        let dy = point.y - center.y
        return atan2(dy, dx)
    }
    
    func rotationDirection(previousAngle: CGFloat, currentAngle: CGFloat) -> CGFloat {
        let normalizedPrevious = previousAngle.truncatingRemainder(dividingBy: 2 * .pi)
        let normalizedCurrent = currentAngle.truncatingRemainder(dividingBy: 2 * .pi)
        let delta = normalizedCurrent - normalizedPrevious
        
        if delta > 0 && delta <= .pi || delta <= -(.pi) {
            // Right
            return 1
        } else if delta < 0 && delta >= -(.pi) || delta >= .pi {
            // Left
            return -1
        } else {
            return 1
        }
    }
    
    func closestNode(to node: SKNode) -> SKNode? {
        let obstacleNodes = scene.children.filter { $0.name == "obstacle" || $0.name == "enemy"}
        if let nodeToGrab = obstacleNodes.sorted(by: { distanceBetween(nodeA: $0, nodeB: player) < distanceBetween(nodeA: $1, nodeB: player) }).first {
            return nodeToGrab
        }
        return nil
    }
    
    func drawLineBetweenNodes(nodeA: SKNode, nodeB: SKNode, in scene: SKScene) {
        let path = CGMutablePath()
        path.addLines(between: [nodeA.position, nodeB.position])
        
        let line = SKShapeNode()
        line.name = "grabLine"
        line.path = path
        line.strokeColor = SKColor.white
        line.lineWidth = 2
        
        scene.addChild(line)
    }
    
    func distanceBetween(nodeA: SKNode, nodeB: SKNode) -> CGFloat {
        let dx = nodeA.position.x - nodeB.position.x
        let dy = nodeA.position.y - nodeB.position.y
        return sqrt(dx*dx + dy*dy)
    }
}
