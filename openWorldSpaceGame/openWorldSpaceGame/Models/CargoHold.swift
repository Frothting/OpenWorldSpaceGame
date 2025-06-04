//
//  CargoHold.swift
//  openWorldSpaceGame
//
//  Created by Christian  Cordy on 12/22/23.
//

import SpriteKit

class CargoHold: SKNode {
    
    var numOrbs: Int {
        return self.children.filter({$0.name == "heldOrb"}).count
    }
    // Custom initializer with texture
    override init() {
        super.init()
        self.setupCargoHold()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCargoHold() {
        //Z position
        self.zPosition = 5
        let leftWall = SKShapeNode(rectOf: CGSize(width: 5, height: 150))
        let rightWall = SKShapeNode(rectOf: CGSize(width: 5, height: 150))
        let bottomWall = SKShapeNode(rectOf: CGSize(width: 160, height: 5))
        let catcher = SKShapeNode(rectOf: CGSize(width: 1000, height: 5))
        
        leftWall.position = CGPoint(x: -160/2, y: 0)
        rightWall.position = CGPoint(x: 160/2, y: 0)
        bottomWall.position = CGPoint(x: 0, y: -150/2)
        catcher.position = CGPoint(x: 0, y: -100)
        
        leftWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 5, height: 150))
        rightWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 5, height: 150))
        bottomWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 160, height: 5))
        catcher.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1000, height: 5))
        
        leftWall.physicsBody?.affectedByGravity = false
        rightWall.physicsBody?.affectedByGravity = false
        bottomWall.physicsBody?.affectedByGravity = false
        catcher.physicsBody?.affectedByGravity = false
        
        leftWall.physicsBody?.isDynamic = false
        rightWall.physicsBody?.isDynamic = false
        bottomWall.physicsBody?.isDynamic = false
        catcher.physicsBody?.isDynamic = false
        
        leftWall.physicsBody?.categoryBitMask = PhysicsCategory.cargoHold
        rightWall.physicsBody?.categoryBitMask = PhysicsCategory.cargoHold
        bottomWall.physicsBody?.categoryBitMask = PhysicsCategory.cargoHold
        catcher.physicsBody?.categoryBitMask = PhysicsCategory.catcher
        
        leftWall.physicsBody?.collisionBitMask = PhysicsCategory.cargoHold
        rightWall.physicsBody?.collisionBitMask = PhysicsCategory.cargoHold
        bottomWall.physicsBody?.collisionBitMask = PhysicsCategory.cargoHold
        catcher.physicsBody?.collisionBitMask = PhysicsCategory.cargoHold
        
        leftWall.physicsBody?.fieldBitMask = PhysicsCategory.cargoHold
        rightWall.physicsBody?.fieldBitMask = PhysicsCategory.cargoHold
        bottomWall.physicsBody?.fieldBitMask = PhysicsCategory.cargoHold
        catcher.physicsBody?.fieldBitMask = PhysicsCategory.cargoHold
        
        catcher.alpha = 0.0
        
        catcher.name = "catcher"
        
        self.addChild(leftWall)
        self.addChild(rightWall)
        self.addChild(bottomWall)
        self.addChild(catcher)

    }
    
    public func makeHeldOrb(kind orb: Cargoable) {
        
        if let pb = orb.physicsBody {
            pb.categoryBitMask = PhysicsCategory.cargoHold
            pb.collisionBitMask = PhysicsCategory.cargoHold
            pb.fieldBitMask = PhysicsCategory.cargoHold
            pb.contactTestBitMask = PhysicsCategory.catcher
            pb.affectedByGravity = true
        }
        orb.position.x = 25 + CGFloat.random(in: -2...2)
        orb.position.y = 200
        orb.name = "heldOrb"
        
        self.addChild(orb)
    }
    
    public func deposit() -> Int{
        
        if !self.hasActions() && self.numOrbs > 0 {
            //Locate the bottom-most orb
            let heldOrbs = self.children.filter({$0 is Cargoable})
            let sortedOrbs = heldOrbs.sorted(by: {$0.position.y < $1.position.y})
            guard let bottomOrb = sortedOrbs.first as? any Cargoable else { return 0 }
            let bottomOrbValue = bottomOrb.value
            
            //setup the remove action
            let waitAction = SKAction.wait(forDuration: 0.0)
            let removeAction = SKAction.removeFromParent()
            let seq = SKAction.sequence([waitAction, removeAction])
            bottomOrb.run(removeAction)
            
            //Setup the floating label
            let floatingLabel = SKLabelNode(text: "+\(bottomOrbValue)")
            floatingLabel.position.x = bottomOrb.position.x
            floatingLabel.position.y = bottomOrb.position.y + 10
            floatingLabel.position.x += CGFloat.random(in: -15...15)
            floatingLabel.position.y += CGFloat.random(in: -15...15)
            floatingLabel.zPosition = 100
            
            floatingLabel.physicsBody = SKPhysicsBody()
            floatingLabel.physicsBody?.velocity = CGVector(dx: 0, dy: 27)
            floatingLabel.physicsBody?.affectedByGravity = false
            floatingLabel.physicsBody?.fieldBitMask = PhysicsCategory.cargoHold
            
            self.addChild(floatingLabel)
            
            //Setup floating label fade action
            let fadeAction = SKAction.fadeOut(withDuration: 2.0)
            let removeLabelAction = SKAction.removeFromParent()
            let waitAction2 = SKAction.wait(forDuration: 2.0)
            let fadeSeq = SKAction.sequence([fadeAction, waitAction2, removeLabelAction])
            floatingLabel.run(fadeSeq)
 
            //return true if we made it this far
            return bottomOrbValue
        }
        return 0
    }
}
