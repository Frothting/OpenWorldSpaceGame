//
//  takeDamage.swift
//  openWorldSpaceGame
//
//  Created by Christian  Cordy on 10/2/24.
//

import Foundation

protocol Damageable {
    var health: Int { get set }
    func takeDamage(_ damage: Int)
    func heal(_ heal: Int)
    func death()
}
