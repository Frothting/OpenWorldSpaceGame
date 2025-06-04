import SpriteKit

enum EnemyState {
    case idle
    case approaching
    case circling
}

class Enemy: SKSpriteNode {
    
    // Properties
    weak var player: Player?
    var state: EnemyState = .idle
    var maxSpeed: CGFloat = 100.0
    var firingRange: CGFloat = 300.0
    var circlingRadius: CGFloat = 200.0
    var timeSinceLastShot: TimeInterval = 0.0
    var shootingInterval: TimeInterval = 40.0
    var health = 5
    // New property to track the current angle around the player
    var currentAngle: CGFloat = 0.0
    
    var angleAdjustment: CGFloat {
        // Adjust this value based on your sprite's default orientation
//        return 0 // No adjustment needed if the sprite faces upwards
         return -CGFloat.pi / 2 // Use if the sprite faces rightwards
        // return CGFloat.pi // Use if the sprite faces downwards
    }
    // Initialize
    init(player: Player) {
        // Initialize with texture, color, size
        let texture = SKTexture(imageNamed: "enemyShip") // Ensure you have an image named "enemyShip"
        let size = CGSize(width: 150, height: 150)
        super.init(texture: texture, color: .clear, size: size)
        // Setup physics body
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.linearDamping = 0.5
        self.physicsBody?.mass = 1.0
        self.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        self.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.wall
        self.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.projectile
        self.physicsBody?.fieldBitMask = PhysicsCategory.none
        self.physicsBody?.allowsRotation = false
        self.player = player
        self.name = "enemy"
        
        // Initialize the current angle based on initial position
        let dx = self.position.x - player.position.x
        let dy = self.position.y - player.position.y
        self.currentAngle = atan2(dy, dx)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Update method
    func update(deltaTime: TimeInterval) {
        guard let player = player else { return }
        let distanceToPlayer = distanceBetween(nodeA: self, nodeB: player)
        switch state {
        case .idle:
            if distanceToPlayer < 400.0 {
                state = .approaching
            }
        case .approaching:
            // Move towards player
            moveTowardsPlayer()
            if distanceToPlayer < firingRange {
                state = .circling
            }
            if distanceToPlayer >= 600 {
                state = .idle
            }
        case .circling:
            // Circle around player
            circleAroundPlayer(deltaTime: deltaTime)
            timeSinceLastShot += 1
            if timeSinceLastShot > shootingInterval {
                shootAtPlayer()
                timeSinceLastShot = 0.0
            }
            
            if distanceToPlayer >= 400 {
                state = .approaching
            }
            
            
        }
        
    
    }
    
    // Movement methods
    func moveTowardsPlayer() {
        guard let player = player else { return }
        
        let direction = (player.position - self.position).normalized()
        let velocity = CGVector(dx: direction.dx * maxSpeed, dy: direction.dy * maxSpeed)
        self.physicsBody?.velocity = velocity
        
        let angle = atan2(direction.dy, direction.dx)
        self.zRotation = angle + angleAdjustment
    }
    
    func circleAroundPlayer(deltaTime: TimeInterval) {
        guard let player = player else { return }

        // Compute the vector from player to enemy
        let radialVector = CGVector(dx: self.position.x - player.position.x, dy: self.position.y - player.position.y)
        let currentDistance = radialVector.magnitude

        // Desired distance from player
        let desiredDistance = circlingRadius

        // Calculate the distance error
        let distanceError = desiredDistance - currentDistance

        // Adjust position only if the distance error is significant
        let kDistance: CGFloat = 0.002 // Reduced to lessen snapping effect
        let distanceAdjustment = CGVector(
            dx: radialVector.dx * distanceError * kDistance,
            dy: radialVector.dy * distanceError * kDistance
        )

        // Calculate tangential velocity for circling
        let angularSpeed: CGFloat = 1.5 // Adjust for circling speed
        let tangentialSpeed = angularSpeed * desiredDistance

        // Calculate the perpendicular (tangential) direction
        let tangentialDirection = CGVector(dx: -radialVector.dy, dy: radialVector.dx).normalized()
        let desiredTangentialVelocity = CGVector(
            dx: tangentialDirection.dx * tangentialSpeed,
            dy: tangentialDirection.dy * tangentialSpeed
        )

        // Smoothly adjust velocity towards desired tangential velocity
        let currentVelocity = self.physicsBody?.velocity ?? .zero
        let kVelocity: CGFloat = 0.05 // Reduced to smooth out velocity changes
        let velocityAdjustment = CGVector(
            dx: (desiredTangentialVelocity.dx - currentVelocity.dx) * kVelocity,
            dy: (desiredTangentialVelocity.dy - currentVelocity.dy) * kVelocity
        )

        // Combine adjustments
        let totalAdjustment = CGVector(
            dx: velocityAdjustment.dx + distanceAdjustment.dx,
            dy: velocityAdjustment.dy + distanceAdjustment.dy
        )

        // Apply adjustments to current velocity
        self.physicsBody?.velocity = CGVector(
            dx: currentVelocity.dx + totalAdjustment.dx,
            dy: currentVelocity.dy + totalAdjustment.dy
        )

        // Limit the speed to maxSpeed
        if let velocity = self.physicsBody?.velocity {
            let speed = velocity.magnitude
            if speed > maxSpeed {
                let scaledVelocity = CGVector(
                    dx: (velocity.dx / speed) * maxSpeed,
                    dy: (velocity.dy / speed) * maxSpeed
                )
                self.physicsBody?.velocity = scaledVelocity
            }
        }

        // Face towards the movement direction
        if let velocity = self.physicsBody?.velocity, velocity.magnitude > 0 {
            self.zRotation = atan2(velocity.dy, velocity.dx)
        }
    }
    
    func shootAtPlayer() {
        guard let player = player else { return }
        // Create a projectile
        let bullet = SKShapeNode(circleOfRadius: 5)
        bullet.fillColor = .yellow
        bullet.position = self.position
        bullet.name = "enemyBullet"
        bullet.zPosition = 3
        let bulletPhysicsBody = SKPhysicsBody(circleOfRadius: 5)
        bulletPhysicsBody.affectedByGravity = false
        bulletPhysicsBody.categoryBitMask = PhysicsCategory.enemyProjectile
        bulletPhysicsBody.collisionBitMask = PhysicsCategory.player
        bulletPhysicsBody.contactTestBitMask = PhysicsCategory.player
        bulletPhysicsBody.fieldBitMask = PhysicsCategory.none
        bulletPhysicsBody.linearDamping = 0
        bullet.physicsBody = bulletPhysicsBody
        // Set bullet velocity towards player
        let direction = (player.position - self.position).normalized()
        let bulletSpeed: CGFloat = 500.0
        bullet.physicsBody?.velocity = CGVector(dx: direction.dx * bulletSpeed, dy: direction.dy * bulletSpeed)
        // Add bullet to scene
        if let scene = self.scene {
            scene.addChild(bullet)
        }
        // Bullet removal after some time
        let waitAction = SKAction.wait(forDuration: 5.0)
        let removeAction = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([waitAction, removeAction]))
    }
    
    // Helper methods
    func distanceBetween(nodeA: SKNode, nodeB: SKNode) -> CGFloat {
        let dx = nodeA.position.x - nodeB.position.x
        let dy = nodeA.position.y - nodeB.position.y
        return sqrt(dx*dx + dy*dy)
    }
}

extension Enemy: Damageable {
    
    func takeDamage(_ damage: Int) {
        self.health -= damage
        if self.health <= 0 {
            self.death()
        }
    }
    
    func heal(_ heal: Int) {
        self.health += heal
    }
    
    func death() {
        self.removeFromParent()
    }
    
    
}
