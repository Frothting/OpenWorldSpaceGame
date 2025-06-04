//
//  StarryBackground.swift
//  openWorldSpaceGame
//
//  Created by Christian  Cordy on 12/22/23.
//

import SpriteKit

class StarryBackground: SKNode {
    // Custom initializer with texture
    private let colors: [UIColor] = [.white, .yellow, .brown, .blue, .red]
    override init() {
        super.init()
        self.setupStarryBackground()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupStarryBackground() {
        //Z position
        self.zPosition = -1
        for _ in 0..<1000 {
            makeStar()
        }
    }
    
    
    
    private func makeStar() {
        self.name = "starryBackground"
        let size = CGFloat.random(in: 0...5)
        let star = SKShapeNode(circleOfRadius: size)
        star.fillColor = colors.randomElement()!
        star.strokeColor = star.fillColor
        star.alpha = CGFloat.random(in: 0...1)
        let xPos = CGFloat.random(in: -1000...1000)
        let yPos = CGFloat.random(in: -1000...1000)
        star.position = CGPoint(x: xPos, y: yPos)
        self.addChild(star)
    }
}
