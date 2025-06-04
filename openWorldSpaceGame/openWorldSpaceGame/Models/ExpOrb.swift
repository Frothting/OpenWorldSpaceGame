//
//  ExpOrb.swift
//  openWorldSpaceGame
//
//  Created by Christian  Cordy on 12/20/23.
//
import SpriteKit

enum OrbSize: CaseIterable {
    case small
    case medium
    case large
    case mega
}

class ExpOrb: SKSpriteNode, Cargoable {
    var orbSize: OrbSize
    var value: Int = 10
    private var textureName: String = "orb"
    private var orbWidthHeight: CGFloat = 25
    // Custom initializer with texture
    init(size: OrbSize) {
        self.orbSize = size
        switch size {
        case .small:
            textureName = "smallOrb"
            orbWidthHeight = 20
            value = 1
        case .medium:
            textureName = "mediumOrb"
            orbWidthHeight = 30
            value = 5
        case .large:
            textureName = "largeOrb"
            orbWidthHeight = 40
            value = 10
        case .mega:
            textureName = "megaOrb"
            orbWidthHeight = 80
            value = 50
        }
        let texture = SKTexture(imageNamed: textureName)
        super.init(texture: texture, color: UIColor.white, size: CGSize(width: orbWidthHeight, height: orbWidthHeight))
        self.setupNode()
        // Additional setup can be done here
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Additional custom methods can be added here
    private func setupNode() {
        // Customize this method to add child nodes, set up physics, etc.
        let pb = SKPhysicsBody(circleOfRadius: orbWidthHeight/2)
        print("orb mass: \(pb.mass)")
        pb.affectedByGravity = false
        pb.categoryBitMask = PhysicsCategory.orb
        pb.contactTestBitMask = PhysicsCategory.player
        pb.collisionBitMask = PhysicsCategory.player | PhysicsCategory.wall | PhysicsCategory.enemy
        pb.fieldBitMask = PhysicsCategory.orb
        pb.restitution = 0.7
        
        self.name = "orb"
        self.physicsBody = pb
    }
}

