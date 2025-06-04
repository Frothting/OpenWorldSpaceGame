//
//  SpecialPickup.swift
//  openWorldSpaceGame
//
//  Created by Christian  Cordy on 10/3/24.
//

import Foundation
import SpriteKit
import UIKit

class SpecialPickup: SKNode, Cargoable {
    var value: Int = 1
    
    init(textureName: String) {
        let textureImage = SKTexture(imageNamed: "spaceCrate")
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
