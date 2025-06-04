//
//  TestScene.swift
//  openWorldSpaceGame
//
//  Created by Christian  Cordy on 12/10/23.
//

import SpriteKit
import SwiftUI
import GameController

class TestScene: SKScene, SKPhysicsContactDelegate, ObservableObject {
    //published properties
    @Published var showUpgradeScreen: Bool = false
    
    //properties
    var enemy: Enemy?
    var player: Player = Player(texture: SKTexture(imageNamed: "PlayerShip"), color: .white, size: CGSize(width: 100, height: 100))
    var scoreLabel = SKLabelNode(text: "Score: 0")
    
    var depot = DropOffDepot(rectOf: CGSize(width: 300, height: 300), cornerRadius: 15)
    //    var drone = Drone(rectOf: CGSize(width: 50, height: 75))
    
    var initialTouch: CGPoint = CGPoint(x: 0, y: 0)
    var sceneCamera = SKCameraNode()
    var cargoHold = CargoHold()
    
    var controlsManager: ControlsManager!
    
    override func didMove(to view: SKView) {
        // Scene setup
        view.isMultipleTouchEnabled = true
        physicsWorld.contactDelegate = self
        scaleMode = .aspectFit
        backgroundColor = .black

        // Player setup
        makePlayer()

        // Obstacles
        setupObstacles()
        setupStation()
        setupPlanet()
        makeBoundary()

        // Camera
        addChild(sceneCamera)
        camera = sceneCamera

        // Cargo hold
        cargoHold.position = CGPoint(x: -frame.width / 3, y: -frame.height / 3)
        cargoHold.setScale(0.3)
        sceneCamera.addChild(cargoHold)
        player.cargoHoldDelegate = cargoHold
        player.scoreLabelDelegate = scoreLabel

        // Controls
        controlsManager = ControlsManager(scene: self, player: player, camera: sceneCamera)

        // Depot
        addChild(depot)

        // Score label
        scoreLabel.position = CGPoint(
            x: 0,
            y: (frame.height / 2) - scoreLabel.frame.height * 3
        )
        sceneCamera.addChild(scoreLabel)

        // Enemy
        enemy = Enemy(player: player)
        if let enemy {
            enemy.position = CGPoint(x: 0, y: -frame.height / 2)
            addChild(enemy)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        
        //        self.drone.update()
        //        if drone.target == nil {
        //            print("need new target")
        //            drone.target = closestNode(to: drone)
        //        }
        
        //Zooming out the camera based on the player's speed
        let playerSpeedRatio = min(3, 1.5 + (player.playerSpeed / 597.0))
        sceneCamera.setScale(playerSpeedRatio)
        
        //Setting the position of the scene camera
        sceneCamera.position = player.position
        
        // Updating controls
        controlsManager.update(currentTime)
        
        //checking the depot
        if player.intersects(depot){
            player.isDocked = true
        } else {
            player.isDocked = false
        }
        
        //check depot for asteroids. If they are there, give points to the player
//        checkDropOffDepotForAsteroids()
        
        //Updating the player
        player.update()
        
        //updating the background
        updateBackground()
        
        updateEnemies(currentTime)
        
        //Updating the grab line
        if let grabLine = self.childNode(withName: "grabLine") as? SKShapeNode, let nodeGrabbed = player.nodeGrabbed {
            let path = CGMutablePath()
            path.addLines(between: [player.position, nodeGrabbed.position])
            grabLine.path = path
        }
    }
}

//MARK: - Setup functions
extension TestScene {
    
    //    func setupDrone() {
    //
    //        drone.position = CGPoint(x: 0, y: 150)
    //        drone.target = closestNode(to: drone)
    //        drone.constraints = [SKConstraint.distance(SKRange(lowerLimit: 0, upperLimit: 200), to: player)]
    //        self.addChild(drone)
    //    }
    
    func makePlayer() {
        player.position = CGPoint(x: frame.midX, y: frame.midY)
        self.addChild(player)
    }
    
    func setupObstacles() {
        
        for _ in 0 ..< 100 {
            let newAsteroid = Asteroid(type: AsteroidType.allCases.randomElement()!)
            let xPos = CGFloat.random(in: -1000..<1000)
            let yPos = CGFloat.random(in: -1000..<21000)
            
            newAsteroid.name = "obstacle"
            newAsteroid.position = CGPoint(x: xPos, y: yPos)
            self.addChild(newAsteroid)
        }
    }
    
    func setupStation() {
        self.enumerateChildNodes(withName: "station") { node, stop in
            if let pb = node.physicsBody{
                pb.applyTorque(200)
                pb.categoryBitMask = PhysicsCategory.wall
                pb.fieldBitMask = PhysicsCategory.wall
                pb.contactTestBitMask = PhysicsCategory.player
                pb.collisionBitMask = PhysicsCategory.enemy | PhysicsCategory.player
            } else {
                print("No Station found")
            }
        }
    }
    
    func setupPlanet() {
        self.enumerateChildNodes(withName: "planet") { node, stop in
            node.physicsBody?.applyTorque(400)
            node.physicsBody?.fieldBitMask = PhysicsCategory.wall
        }
    }
    
    func setupBackground() -> SKSpriteNode {
        let background = SKSpriteNode(imageNamed: "space")
        background.scale(to: CGSize(width: 2000, height: 2000))
        background.name = "background"
        background.zPosition = .leastNonzeroMagnitude
        return background
    }
    
    func updateBackground() {
        let playerVelocity = player.getVelocity
        
        if let background = self.childNode(withName: "starryBackground"){
            background.position.x += playerVelocity.dx/100
            background.position.y += playerVelocity.dy/100
        }
    }
    
    private func makeBoundary() {
        // Define the sizes of the walls
        let wallThickness: CGFloat = 5
        let horizontalWallLength: CGFloat = 2000
        let verticalWallHeight: CGFloat = 21000 // From -1000 to +20000
        
        // Define the positions
        let bottomY: CGFloat = -1000
        let topY: CGFloat = 20000
        let leftX: CGFloat = -1000
        let rightX: CGFloat = 1000
        let centerX: CGFloat = 0
        let centerY: CGFloat = (topY + bottomY) / 2 // Center between bottom and top

        // Create the wall nodes
        let top = SKShapeNode(rectOf: CGSize(width: horizontalWallLength, height: wallThickness))
        let bottom = SKShapeNode(rectOf: CGSize(width: horizontalWallLength, height: wallThickness))
        let left = SKShapeNode(rectOf: CGSize(width: wallThickness, height: verticalWallHeight))
        let right = SKShapeNode(rectOf: CGSize(width: wallThickness, height: verticalWallHeight))
        
        // Position the wall nodes
        top.position = CGPoint(x: centerX, y: topY)
        bottom.position = CGPoint(x: centerX, y: bottomY)
        left.position = CGPoint(x: leftX, y: centerY)
        right.position = CGPoint(x: rightX, y: centerY)
        
        // Create physics bodies for the walls
        let pbTop = SKPhysicsBody(rectangleOf: top.frame.size)
        let pbBottom = SKPhysicsBody(rectangleOf: bottom.frame.size)
        let pbLeft = SKPhysicsBody(rectangleOf: left.frame.size)
        let pbRight = SKPhysicsBody(rectangleOf: right.frame.size)
        
        // Set collision bit masks
        let collisionMask = PhysicsCategory.player | PhysicsCategory.orb | PhysicsCategory.enemy
        pbTop.collisionBitMask = collisionMask
        pbBottom.collisionBitMask = collisionMask
        pbLeft.collisionBitMask = collisionMask
        pbRight.collisionBitMask = collisionMask
        
        // Set category bit masks
        let wallCategory = PhysicsCategory.wall
        pbTop.categoryBitMask = wallCategory
        pbBottom.categoryBitMask = wallCategory
        pbLeft.categoryBitMask = wallCategory
        pbRight.categoryBitMask = wallCategory
        
        // Make the walls static
        pbTop.isDynamic = false
        pbBottom.isDynamic = false
        pbLeft.isDynamic = false
        pbRight.isDynamic = false
        
        // Assign the physics bodies to the wall nodes
        top.physicsBody = pbTop
        bottom.physicsBody = pbBottom
        left.physicsBody = pbLeft
        right.physicsBody = pbRight
        
        // Add the wall nodes to the scene
        self.addChild(top)
        self.addChild(bottom)
        self.addChild(left)
        self.addChild(right)
    }
}

//MARK: - Collisions
extension TestScene {
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        //        print(bodyA)
        //        print(bodyB)
        
        if let nodeA = bodyA.node, let nodeB = bodyB.node { //bullet collision
            if nodeA.name == "bullet" && nodeB.name == "obstacle"{
                if let asteroid = nodeB as? Asteroid {
                    asteroid.takeDamage(1)
                    addAsteroidHitEffect(at: nodeA.position)
                    nodeA.removeFromParent()
                }
            } else if nodeB.name == "bullet" && nodeA.name == "obstacle"{
                if let asteroid = nodeA as? Asteroid{
                    asteroid.takeDamage(1)
                    addAsteroidHitEffect(at: nodeB.position)
                    nodeB.removeFromParent()
                }
            }
            
            //exp orbs
            if nodeA.name == "orb" && nodeB.name == "player"{
                nodeA.removeFromParent()
                if let orb = nodeA as? ExpOrb {
                    player.addToCargo([ExpOrb(size: orb.orbSize)])
                }
            } else if nodeB.name == "orb" && nodeA.name == "player"{
                nodeB.removeFromParent()
                if let orb = nodeB as? ExpOrb {
                    player.addToCargo([ExpOrb(size: orb.orbSize)])
                }
            }
            
            //out of bounds held orbs
            //should trigger once the orbs hit an invisible wall placed below the cargohold
            collisionNodeCheck(nodeA: nodeA, nodeB: nodeB, name1: "heldOrb", name2: "catcher") { node in
                let fadeSeq = SKAction.sequence([SKAction.fadeOut(withDuration: 2.0), SKAction.removeFromParent()])
                node.run(fadeSeq)
            } actionOnName2: { node in
                let fadeSeq = SKAction.sequence([SKAction.fadeOut(withDuration: 2.0), SKAction.removeFromParent()])
                node.run(fadeSeq)
            }
            
            //enemy bullets and the player
            collisionNodeCheck(nodeA: nodeA, nodeB: nodeB, name1: "player", name2: "enemyBullet",
                               actionOnName1: {node in
                guard let player = node as? Player else { return }
                addAsteroidHitEffect(at: nodeB.position)
                
                player.takeDamage(amount: 1)
                
            },
                               actionOnName2: {node in
                node.removeFromParent()
            })
            
            //enemy and player's bullets
            collisionNodeCheck(nodeA: nodeA, nodeB: nodeB, name1: "enemy", name2: "bullet") { node in
                guard let enemy = node as? Enemy else { return }
                enemy.takeDamage(1)
                addAsteroidHitEffect(at: enemy.position)
            } actionOnName2: { node in
                node.removeFromParent()
            }
            
        }
    }
}

//MARK: - Node Methods

extension TestScene {
    
    func addAsteroidHitEffect(at position: CGPoint) {
        if let emitter = SKEmitterNode(fileNamed: "AsteroidHitEffect") {
            let removeEmitterAction = SKAction.sequence([SKAction.wait(forDuration: 0.1), SKAction.fadeOut(withDuration: 0.1),SKAction.removeFromParent()])
            emitter.position = position
            emitter.run(removeEmitterAction)
            self.addChild(emitter)
        }
    }
    
    func collisionNodeCheck(
        nodeA: SKNode,
        nodeB: SKNode,
        name1: String?,
        name2: String?,
        actionOnName1: (SKNode) -> Void,
        actionOnName2: (SKNode) -> Void
    ) {
        guard let nameA = nodeA.name, let nameB = nodeB.name else { return }
        
        // Check for the first condition
        if nameA == name1 && nameB == name2 {
            actionOnName1(nodeA)
            actionOnName2(nodeB)
            return
        }
        
        // Check for the second condition
        if nameB == name1 && nameA == name2 {
            actionOnName1(nodeB)
            actionOnName2(nodeA)
        }
    }
    
    fileprivate func updateEnemies(_ currentTime: TimeInterval) {
        //updating enemies
        if let enemy {
            enemy.update(deltaTime: currentTime)
        }
    }
    
    
    func attachObjects(nodeA: SKNode, nodeB: SKNode) {
        if let bodyA = nodeA.physicsBody, let bodyB = nodeB.physicsBody {
            let joint = SKPhysicsJointLimit.joint(withBodyA: bodyA, bodyB: bodyB, anchorA: .zero, anchorB: .zero)
            
            joint.maxLength = distanceBetween(nodeA: nodeA, nodeB: nodeB) + 5
            
            if let thisScene = scene {
                thisScene.physicsWorld.add(joint)
            }
        }
    }
    
    func closestNode(to node: SKNode) -> SKNode? {
        //        let obstacleNodes = self.children.filter({$0.name == "obstacle"}) // could replace this with a protocol called "grabbable"
        let obstacleNodes = self.children.filter({$0 is grabbable})
        if let nodeToGrab = obstacleNodes.sorted(by: {distanceBetween(nodeA: $0, nodeB: player) < distanceBetween(nodeA: $1, nodeB: player)}).first {
            return nodeToGrab
        }
        
        return nil
    }
    
    func distanceBetween(nodeA: SKNode, nodeB: SKNode) -> CGFloat {
        let dx = nodeA.position.x - nodeB.position.x
        let dy = nodeA.position.y - nodeB.position.y
        return sqrt(dx*dx + dy*dy)
    }
    
    func checkDropOffDepotForAsteroids() {
        //checking the depot for astroids
        let asteroidsInDepot = children.filter({ $0.name == "obstacle" && $0.intersects(depot)})
        
        asteroidsInDepot.forEach { asteroid in
            player.addToCargo([ExpOrb(size: .large)])
            asteroid.removeFromParent()
        }
    }
}

//MARK: - Touches

extension TestScene {
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        controlsManager.touchesMoved(touches, with: event)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        controlsManager.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        controlsManager.touchesEnded(touches, with: event)
    }
}
