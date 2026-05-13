import Foundation
import CoreGraphics

enum AsteroidsPhase {
    case menu, playing, gameOver
}

enum AsteroidSize: Equatable {
    case large, medium, small
    var radius: CGFloat {
        switch self {
        case .large:  return 36
        case .medium: return 22
        case .small:  return 12
        }
    }
    var points: Int {
        switch self {
        case .large:  return 20
        case .medium: return 50
        case .small:  return 100
        }
    }
}

struct AsteroidsShip: Identifiable, Equatable {
    let id: Int
    let owner: Int
    var x: CGFloat
    var y: CGFloat
    var angle: CGFloat
    var vx: CGFloat = 0
    var vy: CGFloat = 0
    var lives: Int
    var invulnUntilTick: Int = 0
    var thrusting: Bool = false
    var alive: Bool { lives > 0 }
    static let radius: CGFloat = 9
}

struct Asteroid: Identifiable, Equatable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var size: AsteroidSize
    let shape: [CGPoint]
    var rotation: CGFloat
    var rotationSpeed: CGFloat
}

struct AsteroidsBullet: Identifiable, Equatable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var life: Int
    let owner: Int
}

class AsteroidsGame: ObservableObject {
    static let courtWidth: CGFloat = 820
    static let courtHeight: CGFloat = 560

    @Published var phase: AsteroidsPhase = .menu
    @Published var playerCount: Int = 1
    @Published var ships: [AsteroidsShip] = []
    @Published var asteroids: [Asteroid] = []
    @Published var bullets: [AsteroidsBullet] = []
    @Published var p1Score: Int = 0
    @Published var p2Score: Int = 0
    @Published var wave: Int = 1
    @Published var isPaused: Bool = false
    @Published var endReason: String = ""

    var p1Rotate: Int = 0
    var p1Thrust: Bool = false
    var p2Rotate: Int = 0
    var p2Thrust: Bool = false

    private var tickCount: Int = 0
    private var nextID: Int = 0

    func startGame(players: Int) {
        playerCount = max(1, min(2, players))
        wave = 1
        p1Score = 0
        p2Score = 0
        bullets = []
        endReason = ""
        isPaused = false
        tickCount = 0
        spawnShips()
        spawnWave()
        phase = .playing
    }

    func returnToMenu() {
        phase = .menu
        ships = []
        asteroids = []
        bullets = []
    }

    func togglePause() {
        guard phase == .playing else { return }
        isPaused.toggle()
    }

    private func spawnShips() {
        ships.removeAll()
        if playerCount == 1 {
            ships.append(AsteroidsShip(
                id: nextID, owner: 1,
                x: Self.courtWidth / 2, y: Self.courtHeight / 2,
                angle: 0, lives: 3, invulnUntilTick: tickCount + 120
            ))
            nextID += 1
        } else {
            ships.append(AsteroidsShip(
                id: nextID, owner: 1,
                x: Self.courtWidth * 0.35, y: Self.courtHeight / 2,
                angle: 0, lives: 3, invulnUntilTick: tickCount + 120
            ))
            nextID += 1
            ships.append(AsteroidsShip(
                id: nextID, owner: 2,
                x: Self.courtWidth * 0.65, y: Self.courtHeight / 2,
                angle: 0, lives: 3, invulnUntilTick: tickCount + 120
            ))
            nextID += 1
        }
    }

    private func spawnWave() {
        asteroids.removeAll()
        let count = 4 + (wave - 1)
        for _ in 0..<count {
            asteroids.append(makeAsteroid(size: .large, atEdge: true))
        }
    }

    private func makeAsteroid(size: AsteroidSize, atEdge: Bool, x: CGFloat? = nil, y: CGFloat? = nil) -> Asteroid {
        let pos: (CGFloat, CGFloat)
        if let x, let y {
            pos = (x, y)
        } else if atEdge {
            pos = randomEdgePosition()
        } else {
            pos = (CGFloat.random(in: 0..<Self.courtWidth), CGFloat.random(in: 0..<Self.courtHeight))
        }

        let speed: CGFloat = {
            switch size {
            case .large:  return CGFloat.random(in: 0.6...1.4)
            case .medium: return CGFloat.random(in: 1.0...2.0)
            case .small:  return CGFloat.random(in: 1.6...2.6)
            }
        }()
        let dir = CGFloat.random(in: 0..<(.pi * 2))

        let asteroid = Asteroid(
            id: nextID,
            x: pos.0, y: pos.1,
            vx: cos(dir) * speed, vy: sin(dir) * speed,
            size: size,
            shape: Self.randomShape(radius: size.radius),
            rotation: CGFloat.random(in: 0..<(.pi * 2)),
            rotationSpeed: CGFloat.random(in: -0.04...0.04)
        )
        nextID += 1
        return asteroid
    }

    private static func randomShape(radius: CGFloat) -> [CGPoint] {
        var pts: [CGPoint] = []
        let n = 9
        for i in 0..<n {
            let a = CGFloat(i) / CGFloat(n) * .pi * 2
            let r = radius * CGFloat.random(in: 0.72...1.05)
            pts.append(CGPoint(x: cos(a) * r, y: sin(a) * r))
        }
        return pts
    }

    private func randomEdgePosition() -> (CGFloat, CGFloat) {
        switch Int.random(in: 0..<4) {
        case 0: return (CGFloat.random(in: 0..<Self.courtWidth), 0)
        case 1: return (CGFloat.random(in: 0..<Self.courtWidth), Self.courtHeight)
        case 2: return (0, CGFloat.random(in: 0..<Self.courtHeight))
        default: return (Self.courtWidth, CGFloat.random(in: 0..<Self.courtHeight))
        }
    }

    func tick() {
        guard phase == .playing, !isPaused else { return }
        tickCount += 1
        moveShips()
        moveAsteroids()
        moveBullets()
        resolveCollisions()
        checkWaveEnd()
        checkGameEnd()
    }

    func setRotate(owner: Int, dir: Int) {
        if owner == 1 { p1Rotate = dir } else { p2Rotate = dir }
    }

    func setThrust(owner: Int, on: Bool) {
        if owner == 1 { p1Thrust = on } else { p2Thrust = on }
    }

    func fire(owner: Int) {
        guard phase == .playing, !isPaused else { return }
        guard let ship = ships.first(where: { $0.owner == owner && $0.alive }) else { return }
        let myBullets = bullets.filter { $0.owner == owner }.count
        if myBullets >= 4 { return }
        let bulletSpeed: CGFloat = 8
        let nx = ship.x + sin(ship.angle) * 14
        let ny = ship.y - cos(ship.angle) * 14
        bullets.append(AsteroidsBullet(
            id: nextID,
            x: nx, y: ny,
            vx: ship.vx + sin(ship.angle) * bulletSpeed,
            vy: ship.vy - cos(ship.angle) * bulletSpeed,
            life: 60,
            owner: owner
        ))
        nextID += 1
    }

    private func moveShips() {
        let rotateSpeed: CGFloat = 0.10
        let thrustAccel: CGFloat = 0.18
        let drag: CGFloat = 0.992
        let maxSpeed: CGFloat = 6

        for i in 0..<ships.count where ships[i].alive {
            let rot = ships[i].owner == 1 ? p1Rotate : p2Rotate
            let thrust = ships[i].owner == 1 ? p1Thrust : p2Thrust

            ships[i].angle += CGFloat(rot) * rotateSpeed
            ships[i].thrusting = thrust

            if thrust {
                ships[i].vx += sin(ships[i].angle) * thrustAccel
                ships[i].vy -= cos(ships[i].angle) * thrustAccel
            }

            ships[i].vx *= drag
            ships[i].vy *= drag

            let speed = hypot(ships[i].vx, ships[i].vy)
            if speed > maxSpeed {
                ships[i].vx *= maxSpeed / speed
                ships[i].vy *= maxSpeed / speed
            }

            ships[i].x += ships[i].vx
            ships[i].y += ships[i].vy
            let w = Self.wrapped(ships[i].x, ships[i].y)
            ships[i].x = w.0
            ships[i].y = w.1
        }
    }

    private func moveAsteroids() {
        for i in 0..<asteroids.count {
            asteroids[i].x += asteroids[i].vx
            asteroids[i].y += asteroids[i].vy
            asteroids[i].rotation += asteroids[i].rotationSpeed
            let w = Self.wrapped(asteroids[i].x, asteroids[i].y)
            asteroids[i].x = w.0
            asteroids[i].y = w.1
        }
    }

    private func moveBullets() {
        for i in 0..<bullets.count {
            bullets[i].x += bullets[i].vx
            bullets[i].y += bullets[i].vy
            bullets[i].life -= 1
            let w = Self.wrapped(bullets[i].x, bullets[i].y)
            bullets[i].x = w.0
            bullets[i].y = w.1
        }
        bullets.removeAll { $0.life <= 0 }
    }

    private static func wrapped(_ x: CGFloat, _ y: CGFloat) -> (CGFloat, CGFloat) {
        var rx = x, ry = y
        if rx < 0 { rx += courtWidth }
        if rx >= courtWidth { rx -= courtWidth }
        if ry < 0 { ry += courtHeight }
        if ry >= courtHeight { ry -= courtHeight }
        return (rx, ry)
    }

    private func resolveCollisions() {
        var bulletsToRemove: Set<Int> = []
        var asteroidsToReplace: [(Int, [Asteroid])] = []

        for bIdx in 0..<bullets.count {
            let bullet = bullets[bIdx]
            for aIdx in 0..<asteroids.count {
                let asteroid = asteroids[aIdx]
                let d = hypot(bullet.x - asteroid.x, bullet.y - asteroid.y)
                if d < asteroid.size.radius {
                    bulletsToRemove.insert(bullet.id)
                    if bullet.owner == 1 { p1Score += asteroid.size.points }
                    else if bullet.owner == 2 { p2Score += asteroid.size.points }
                    asteroidsToReplace.append((aIdx, splitAsteroid(asteroid)))
                    break
                }
            }
        }

        let toRemoveIds = Set(asteroidsToReplace.map { asteroids[$0.0].id })
        let newChildren = asteroidsToReplace.flatMap { $0.1 }
        if !toRemoveIds.isEmpty {
            asteroids.removeAll { toRemoveIds.contains($0.id) }
            asteroids.append(contentsOf: newChildren)
        }
        if !bulletsToRemove.isEmpty {
            bullets.removeAll { bulletsToRemove.contains($0.id) }
        }

        for sIdx in 0..<ships.count {
            let ship = ships[sIdx]
            guard ship.alive, tickCount >= ship.invulnUntilTick else { continue }
            for asteroid in asteroids {
                let d = hypot(ship.x - asteroid.x, ship.y - asteroid.y)
                if d < asteroid.size.radius + AsteroidsShip.radius {
                    ships[sIdx].lives -= 1
                    ships[sIdx].invulnUntilTick = tickCount + 120
                    ships[sIdx].vx = 0
                    ships[sIdx].vy = 0
                    if ships[sIdx].alive {
                        ships[sIdx].x = Self.courtWidth / 2 + (ship.owner == 2 ? 60 : -60)
                        ships[sIdx].y = Self.courtHeight / 2
                        ships[sIdx].angle = 0
                    }
                    break
                }
            }
        }
    }

    private func splitAsteroid(_ a: Asteroid) -> [Asteroid] {
        switch a.size {
        case .large:
            return [
                makeAsteroid(size: .medium, atEdge: false, x: a.x, y: a.y),
                makeAsteroid(size: .medium, atEdge: false, x: a.x, y: a.y)
            ]
        case .medium:
            return [
                makeAsteroid(size: .small, atEdge: false, x: a.x, y: a.y),
                makeAsteroid(size: .small, atEdge: false, x: a.x, y: a.y)
            ]
        case .small:
            return []
        }
    }

    private func checkWaveEnd() {
        if asteroids.isEmpty {
            wave += 1
            for i in 0..<ships.count where ships[i].alive {
                ships[i].invulnUntilTick = tickCount + 90
            }
            spawnWave()
        }
    }

    private func checkGameEnd() {
        let totalLives = ships.reduce(0) { $0 + max(0, $1.lives) }
        if totalLives <= 0 {
            endReason = "All ships destroyed"
            phase = .gameOver
        }
    }

    func isShipFlashing(_ ship: AsteroidsShip) -> Bool {
        ship.alive && tickCount < ship.invulnUntilTick && (tickCount / 4) % 2 == 0
    }
}
