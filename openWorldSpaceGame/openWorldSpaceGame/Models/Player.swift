//
//  Player.swift
//  openWorldSpaceGame
//
//  Created by Christian  Cordy on 12/16/23.
//
import SpriteKit

class Player: SKSpriteNode, ObservableObject {
    //Published properties
    @Published var exp: Int = 0
    
    //Properties
    var thrustModifier: CGFloat = 5.0
    var shouldMoveFowards: Bool = false
    var shouldMoveBackwards: Bool = false
    var shouldBoost: Bool = false
    var isGrabbing: Bool = false
    var angle: CGFloat = 0.0
    var nodeGrabbed: SKNode?
    var isDocked: Bool = false
    var framesUntilCanShoot = 0
    var framesUntilCanDeposit = 0
    var depositWaitTime = 7
    var shootWaitTime = 15
    var cargoHoldDelegate: CargoHold?
    var scoreLabelDelegate: SKLabelNode?
    var health = 10
    var particleBirthrate = 0.0
    
    var playerSpeed: CGFloat {
        if let pb = self.physicsBody {
            return pb.velocity.magnitude
        } else {
            return 0.0
        }
    }
    
    var getVelocity: CGVector {
        if let pb = self.physicsBody {
            return pb.velocity
        } else {
            return .zero
        }
    }
    
    // Initialize with default values
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        // Custom initialization code here
        self.name = "player"
        self.zPosition = 1
        let playerPB = SKPhysicsBody(rectangleOf: self.size)
        playerPB.affectedByGravity = false
        playerPB.linearDamping = 1.0
        playerPB.mass = 1
        playerPB.categoryBitMask = PhysicsCategory.player
        playerPB.collisionBitMask = PhysicsCategory.enemy | PhysicsCategory.wall
        playerPB.contactTestBitMask = PhysicsCategory.orb | PhysicsCategory.enemyProjectile
        playerPB.fieldBitMask = PhysicsCategory.player
        
        playerPB.allowsRotation = false
        
        let orbField = SKFieldNode.radialGravityField()
        orbField.isEnabled = true
        orbField.categoryBitMask = PhysicsCategory.orb
        orbField.name = "orbField"
        orbField.falloff = 1
        orbField.strength = 5
        
        self.addChild(orbField)
        self.physicsBody = playerPB
    }
    
    // Required initializer for decoding
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Custom decoding initialization
    }
    
    // Custom methods here
    public func update() {
        self.zRotation = self.angle
        if self.shouldMoveFowards {
            self.thrust()
        } else {
            self.stopThrust()
        }
        
        //Not really used. Could be removed
        if self.shouldMoveBackwards {
            self.reverseThrust()
        }
        
        //Deposit orbs when player is docked
        if self.isDocked && self.framesUntilCanDeposit <= 0{
            self.framesUntilCanDeposit = self.depositWaitTime
            if let cargoHoldDelegate = cargoHoldDelegate {
                let depositValue = cargoHoldDelegate.deposit()
                self.exp += depositValue
                if let pb = self.physicsBody {
                    pb.mass = CGFloat(1.0 + Double(cargoHoldDelegate.numOrbs) * 0.01)
                }
                if let sld = scoreLabelDelegate {
                    sld.text = String(self.exp)
                }
            }
        } else {
            self.framesUntilCanDeposit -= 1
        }
        
        self.framesUntilCanShoot -= 1
        framesUntilCanShoot = max(framesUntilCanShoot, 0) //should never be below 0
    }
    
    func rotate(by ang: CGFloat) {
        let rotation = SKAction.rotate(byAngle: ang, duration: 0.001)
        self.run(rotation)
    }
    
    func rotateRight() {
        let rotation = SKAction.rotate(byAngle: -0.01, duration: 0.1)
        self.run(rotation)
    }
    
    fileprivate func enableThrustEffect() {
        if self.childNode(withName: "ThrustEffect") == nil {
            guard let thrustEmitter = SKEmitterNode(fileNamed: "ThrustEffect") else { return }
            self.particleBirthrate = thrustEmitter.particleBirthRate
            thrustEmitter.name = "ThrustEffect"
            thrustEmitter.position = CGPoint(x: -self.size.width / 2, y: 0) // Position it behind the player
            thrustEmitter.zRotation = self.zRotation // Adjust if needed
            thrustEmitter.targetNode = self.parent // Emit particles into the scene
            self.addChild(thrustEmitter)
        } else {
            if let thrustEmitter = self.childNode(withName: "ThrustEffect") as? SKEmitterNode {
                thrustEmitter.particleBirthRate = self.particleBirthrate
            }
        }
    }
    
    fileprivate func disableThrustEffect() {
        if let thrustEmitter = self.childNode(withName: "ThrustEffect") as? SKEmitterNode {
            thrustEmitter.particleBirthRate = 0
        }
    }
    
    func thrust() {
        var dx = cos(self.angle) * thrustModifier
        var dy = sin(self.angle) * thrustModifier
        
        if shouldBoost {
            dx *= 2
            dy *= 2
        }
        
        self.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
        
        enableThrustEffect()
    }
    
    
    
    func stopThrust() {
        disableThrustEffect()
    }
    
    func reverseThrust() {
        let dx = -cos(self.angle)
        let dy = -sin(self.angle)
        self.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
    }
    
    func shoot(towards node: SKNode) {
        print(framesUntilCanShoot)
        if framesUntilCanShoot > 0 {
            return
        }
        
        framesUntilCanShoot = self.shootWaitTime
        
        let bullet = SKShapeNode(circleOfRadius: 10)
        let pb = SKPhysicsBody(circleOfRadius: 10)
        
        let angle = calculateAngle(center: self.position, point: node.position)
        pb.velocity = CGVector(dx: cos(angle)*500, dy: sin(angle)*500)
        pb.affectedByGravity = false
        pb.mass = 1.0001
        pb.linearDamping = 0
        pb.collisionBitMask = PhysicsCategory.enemy
        pb.categoryBitMask = PhysicsCategory.projectile
        pb.contactTestBitMask = PhysicsCategory.enemy
        pb.fieldBitMask = PhysicsCategory.projectile
        
        
        
        bullet.physicsBody = pb
        bullet.fillColor = .red
        bullet.zPosition = 3
        bullet.position = self.position
        bullet.name = "bullet"
        
        let waitAction = SKAction.wait(forDuration: 15)
        let removeBulletAction = SKAction.removeFromParent()
        let actionSequence = SKAction.sequence([waitAction, removeBulletAction])
        
        bullet.run(actionSequence)
//        bullet.position.y += self.frame.height + 5
        
        if let parent = self.parent{
            parent.addChild(bullet)
        }
    }
    
    func grab(node: SKNode) {
        if let nodeBody = node.physicsBody, let myBody = self.physicsBody {
            let joint = SKPhysicsJointSpring.joint(withBodyA: nodeBody, bodyB: myBody, anchorA: node.position, anchorB: self.position)//
            joint.damping = 0
            joint.frequency = 1
            if let thisScene = self.scene {
                thisScene.physicsWorld.add(joint)
            }
            
            self.nodeGrabbed = node
        }
    }
    
    func addToCargo(_ orbs: [Cargoable]) {
        print("Player Experience: \(self.exp)")
        if let cargoHoldDelegate = cargoHoldDelegate {
            var massTotal: CGFloat = self.physicsBody!.mass
            for orb in orbs {
                cargoHoldDelegate.makeHeldOrb(kind: orb)
                massTotal += (orb.physicsBody?.mass ?? 0) / 10
            }
            if let pb = self.physicsBody {
                pb.mass = massTotal
            }
        }
    }
    
    func takeDamage(amount: Int) {
        self.health -= amount
        print(self.health)
        if self.health <= 0 {
            print("GAME OVER")
            //TODO change this to game over state
        }
    }
    
}

extension Player: Damageable {
    func heal(_ amount: Int) {
        self.health += amount
    }
    
    func death() {
        print("GAMEOVER")
        self.removeFromParent()
    }
    
    public func takeDamage(_ damage: Int) {
        self.health -= damage
        if self.health <= 0 {
            self.death()
        }
    }
}
