//
//  PhysicsCategory.swift
//  openWorldSpaceGame
//
//  Created by Christian  Cordy on 12/22/23.
//

import Foundation

enum PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 1 << 0 // 1
    static let enemy: UInt32 = 1 << 1 // 2
    static let wall: UInt32 = 1 << 2 // 4
    static let background: UInt32 = 1 << 3 //8?
    static let projectile: UInt32 = 1 << 4 //16?
    static let orb: UInt32 = 1 << 5 // 32?
    static let cargoHold: UInt32 = 1 << 6
    static let station: UInt32 = 1 << 7
    static let catcher: UInt32 = 1 << 8
    static let drone: UInt32 = 1 << 9
    static let enemyProjectile: UInt32 = 1 << 10
    // and so on...
}
