//
//  UtilityFunctions.swift
//  openWorldSpaceGame
//
//  Created by Christian  Cordy on 9/26/24.
//

import Foundation
import SpriteKit

//MARK: - Utility Functions TODO: Refactor

func drawLineBetweenNodes(nodeA: SKNode, nodeB: SKNode, in scene: SKScene) {
    let line = SKShapeNode()
    line.name = "grabLine"
    
    let path = CGMutablePath()
    path.addLines(between: [nodeA.position, nodeB.position])
    
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



extension CGVector {
    // Computed property to calculate the magnitude of the vector
    var magnitude: CGFloat {
        return sqrt(dx*dx + dy*dy)
    }
}

func rotationDirection(previousAngle: Double, currentAngle: Double) -> CGFloat {
    let normalizedPrevious = previousAngle.truncatingRemainder(dividingBy: 2 * .pi)
    let normalizedCurrent = currentAngle.truncatingRemainder(dividingBy: 2 * .pi)
    let delta = normalizedCurrent - normalizedPrevious

    if delta > 0 && delta <= .pi || delta <= -(.pi) {
//        print("right")
        return 1
    } else if delta < 0 && delta >= -(.pi) || delta >= .pi {
//        print("left")
        return -1
    } else {
        return 1
    }
}

extension CGPoint {
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGVector {
        return CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }
}

extension CGVector {

    func normalized() -> CGVector {

        let mag = self.magnitude

        return mag > 0 ? CGVector(dx: dx / mag, dy: dy / mag) : .zero

    }

}
