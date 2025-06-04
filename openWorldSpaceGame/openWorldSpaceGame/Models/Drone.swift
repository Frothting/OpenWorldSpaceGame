//
//  Drone.swift
//  openWorldSpaceGame
//
//  Created by Christian  Cordy on 12/23/23.
//
import SpriteKit

class Drone: SKShapeNode {
    // Custom initializer with texture
    var target: SKNode?
    var isThrottle: Bool = false
    var isShooting: Bool = true
    override init() {
        super.init()
        self.setupDrone()
        
        let repeatShootingAction = SKAction.customAction(withDuration: .leastNonzeroMagnitude) { node, _ in
            if let target = self.target{
                self.shoot(towards: target)
                print("Shoot!")
            }
        }
        
        let waitAction = SKAction.wait(forDuration: 2)
        
        let seq = SKAction.sequence([waitAction, repeatShootingAction])
        
        let r = SKAction.repeatForever(seq)
        
        self.run(r)
    }
    
    func update() {
        if let target = target {
            let moveToTargetAction = SKAction.move(to: target.position, duration: 5)
            self.run(moveToTargetAction)
            
            if let hmm = target as? Asteroid{
                if hmm.health <= 0 {
                    self.target = nil
                }
            }
            
            print("distance to target: \(distanceBetween(nodeA: self, nodeB: target))")
            if distanceBetween(nodeA: self, nodeB: target) > 100 {
                self.target = nil
            }
            
            if target is Player {
                self.target = nil
            }
        }
        
        self.zRotation = 0
        throttle()
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupDrone() {
        
        let pb = SKPhysicsBody(rectangleOf: self.frame.size)
        pb.categoryBitMask = PhysicsCategory.drone
        pb.contactTestBitMask = PhysicsCategory.drone
        pb.collisionBitMask = PhysicsCategory.drone
        pb.fieldBitMask = PhysicsCategory.drone
        self.physicsBody = pb
        print("droneSetup")
    }
    
    private func rotateTowardsTarget(){
        
    }
    
    public func throttle() {
//        let impulseAction = SKAction.applyImpulse(CGVector(dx: 0, dy: 500), duration: 0.2)
//        self.run(impulseAction)
        if let pb = self.physicsBody {
            pb.velocity = CGVector(dx: 100, dy: 0)
            print("throttling")
        } else {
            print("no pb")
            self.setupDrone()
        }
    }
    
    private func navigateToTarget(){
        
    }
    
    func shoot(towards node: SKNode) {
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
}
