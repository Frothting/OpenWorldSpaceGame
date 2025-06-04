//
//  Asteroid.swift
//  openWorldSpaceGame
//
//  Created by Christian  Cordy on 12/21/23.
//

import SpriteKit

protocol grabbable {
    // Nothing right now. Just a category that can be put on a node to make things easier.
}

enum AsteroidType: CaseIterable {
    case small
    case medium
    case large
    case superLarge
}

class Asteroid: SKSpriteNode, grabbable {
    let textureImageName = "asteroid"
    var health = 5
    var type: AsteroidType
    private var lBound: CGFloat
    private var uBound: CGFloat
    // Custom initializer with texture
    init(type: AsteroidType = .small) {
        self.type = type
        switch type {
        case .small:
            lBound = 75
            uBound = 200
            health = 5
        case .medium:
            lBound = 175
            uBound = 275
            health = 10
        case .large:
            lBound = 250
            uBound = 325
            health = 15
        case .superLarge:
            lBound = 500
            uBound = 700
            health = 25
        }
        
        let size = CGFloat.random(in: lBound...uBound)
        let mySize = CGSize(width: size, height: size)
        let textureImage = SKTexture(imageNamed: textureImageName)
        super.init(texture: textureImage, color: UIColor.white, size: mySize)
        self.setupAsteroid()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAsteroid() {
        //Physics Body
        let newPB = SKPhysicsBody(circleOfRadius: self.size.width/2)
        newPB.categoryBitMask = PhysicsCategory.enemy
        newPB.fieldBitMask = PhysicsCategory.enemy
        newPB.collisionBitMask = PhysicsCategory.enemy | PhysicsCategory.player | PhysicsCategory.wall
        
        newPB.affectedByGravity = false
        newPB.mass = 1
        self.physicsBody = newPB
        
        //Z position
        self.zPosition = 1
        
        //Name
        self.name = "obstacle"
        
        let dir = CGFloat.random(in: -1...1)
        let rotationAction = SKAction.applyTorque(15 * dir, duration: 0.01)
        self.run(rotationAction)
    }
    
    private func makeOrb() {
        let newOrbSize = OrbSize.allCases.randomElement()!
        let newOrb = ExpOrb(size: newOrbSize)
        let xOffset = CGFloat.random(in: -15...15)
        let yOffset = CGFloat.random(in: -15...15)
        newOrb.position = self.position
        newOrb.position.x += xOffset
        newOrb.position.y += yOffset
        
        let vect = CGVector(dx: xOffset*10, dy: yOffset*10)
        newOrb.physicsBody?.velocity = vect
        
        //an orb should disappear after <int> seconds
        let waitAction = SKAction.wait(forDuration: 15)
        let removeAction = SKAction.removeFromParent()
        let removeAfterAWhile = SKAction.sequence([waitAction, removeAction])
        newOrb.run(removeAfterAWhile)
        
        if let parent = self.parent {
            
            parent.addChild(newOrb)
        }
    }
    
    
}

extension Asteroid: Damageable {
    func takeDamage(_ damage: Int) {
        self.health -= damage
        if self.health <= 0 {
            self.death()
        }
    }
    
    func heal(_ heal: Int) {
        return //doesnt heal
    }
    
    func death() {
        var orbUbound = 5
        self.health -= 1
        //        self.decreaseSize(self)
        if self.health <= 0 {
            switch self.type {
            case .small:
                orbUbound = 5
            case .medium:
                orbUbound = 10
            case .large:
                orbUbound = 15
            case .superLarge:
                orbUbound = 25
            }
            
            if self.type != .small {
                let childPos = self.position
                let ast1 = Asteroid(type: .small)
                let ast2 = Asteroid(type: .small)
                
                ast1.position = childPos
                ast2.position = childPos
                
                let xOffset1 = CGFloat.random(in: -15...15)
                let yOffset1 = CGFloat.random(in: -15...15)
                let xOffset2 = CGFloat.random(in: -15...15)
                let yOffset2 = CGFloat.random(in: -15...15)
                
                ast1.physicsBody?.velocity = CGVector(dx: xOffset1*10, dy: yOffset1*10)
                ast2.physicsBody?.velocity = CGVector(dx: xOffset2*10, dy: yOffset2*10)
                
                self.parent?.addChild(ast1)
                self.parent?.addChild(ast2)
            }
            
            
            for _ in 0...orbUbound {
                makeOrb()
            }
            self.removeFromParent()
            
        }
    }
    
    
}
