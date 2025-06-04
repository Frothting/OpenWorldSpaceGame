//
//  CargoHold.swift
//  openWorldSpaceGame
//
//  Created by Christian  Cordy on 12/22/23.
//

import SpriteKit

class DropOffDepot: SKShapeNode {
    // Custom initializer with texture
    override init() {
        super.init()
        self.setupDropOffDepot()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupDropOffDepot() {
        let pb = SKPhysicsBody(rectangleOf: self.frame.size)
        pb.contactTestBitMask = PhysicsCategory.player
        self.physicsBody = pb
    }
    
}
