import Foundation
import CoreGraphics

enum InvadersPhase {
    case menu, playing, gameOver
}

enum AlienType: Equatable {
    case small, medium, large
    var points: Int {
        switch self {
        case .small:  return 30
        case .medium: return 20
        case .large:  return 10
        }
    }
}

struct Alien: Identifiable, Equatable {
    let id: Int
    let row: Int
    let col: Int
    var x: CGFloat
    var y: CGFloat
    var alive: Bool = true
    let type: AlienType
}

struct InvaderShip: Identifiable, Equatable {
    let id: Int
    let owner: Int   // 1 or 2
    var x: CGFloat
    let y: CGFloat
    var lives: Int
    var invulnUntilTick: Int = 0
    var alive: Bool { lives > 0 }
}

struct InvadersBullet: Identifiable, Equatable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let vy: CGFloat
    let owner: Int   // 1, 2, or 0 (alien)
}

class SpaceInvadersGame: ObservableObject {
    static let courtWidth: CGFloat = 720
    static let courtHeight: CGFloat = 540
    static let shipWidth: CGFloat = 36
    static let shipHeight: CGFloat = 18
    static let shipY: CGFloat = courtHeight - 40
    static let alienWidth: CGFloat = 28
    static let alienHeight: CGFloat = 22
    static let bulletWidth: CGFloat = 4
    static let bulletHeight: CGFloat = 12

    static let alienCols = 11
    static let alienRows = 5
    static let alienSpacingX: CGFloat = 38
    static let alienSpacingY: CGFloat = 32
    static let alienStepX: CGFloat = 8
    static let alienStepY: CGFloat = 16

    @Published var phase: InvadersPhase = .menu
    @Published var playerCount: Int = 1
    @Published var ships: [InvaderShip] = []
    @Published var aliens: [Alien] = []
    @Published var bullets: [InvadersBullet] = []
    @Published var alienDirection: Int = 1
    @Published var wave: Int = 1
    @Published var p1Score: Int = 0
    @Published var p2Score: Int = 0
    @Published var endReason: String = ""
    @Published var isPaused: Bool = false

    var p1MoveDir: Int = 0
    var p2MoveDir: Int = 0

    private var tickCount: Int = 0
    private var alienStepCounter: Int = 0
    private var nextBulletID: Int = 0
    private var nextAlienID: Int = 0

    func startGame(players: Int) {
        playerCount = max(1, min(2, players))
        wave = 1
        p1Score = 0
        p2Score = 0
        bullets = []
        alienDirection = 1
        endReason = ""
        isPaused = false
        tickCount = 0
        alienStepCounter = 0

        spawnShips(fullLives: true)
        spawnWave()
        phase = .playing
    }

    func returnToMenu() {
        phase = .menu
        ships = []
        aliens = []
        bullets = []
    }

    func togglePause() {
        guard phase == .playing else { return }
        isPaused.toggle()
    }

    private func spawnShips(fullLives: Bool) {
        if playerCount == 1 {
            ships = [InvaderShip(id: 1, owner: 1, x: Self.courtWidth / 2, y: Self.shipY, lives: 3)]
        } else {
            ships = [
                InvaderShip(id: 1, owner: 1, x: Self.courtWidth * 0.33, y: Self.shipY, lives: 3),
                InvaderShip(id: 2, owner: 2, x: Self.courtWidth * 0.67, y: Self.shipY, lives: 3)
            ]
        }
    }

    private func spawnWave() {
        aliens = []
        let startX = (Self.courtWidth - CGFloat(Self.alienCols - 1) * Self.alienSpacingX) / 2
        let startY: CGFloat = 70
        for r in 0..<Self.alienRows {
            for c in 0..<Self.alienCols {
                let type: AlienType = r == 0 ? .small : (r < 3 ? .medium : .large)
                aliens.append(Alien(
                    id: nextAlienID,
                    row: r, col: c,
                    x: startX + CGFloat(c) * Self.alienSpacingX,
                    y: startY + CGFloat(r) * Self.alienSpacingY,
                    type: type
                ))
                nextAlienID += 1
            }
        }
        alienDirection = 1
        alienStepCounter = 0
    }

    func tick() {
        guard phase == .playing, !isPaused else { return }
        tickCount += 1

        movePlayers()
        moveBullets()
        maybeStepAliens()
        maybeAlienFire()
        resolveCollisions()
        checkEnd()
    }

    func fire(owner: Int) {
        guard phase == .playing, !isPaused else { return }
        guard !bullets.contains(where: { $0.owner == owner }) else { return }
        guard let ship = ships.first(where: { $0.owner == owner && $0.alive }) else { return }
        bullets.append(InvadersBullet(
            id: nextBulletID,
            x: ship.x,
            y: ship.y - Self.shipHeight / 2,
            vy: -8,
            owner: owner
        ))
        nextBulletID += 1
    }

    private func movePlayers() {
        let speed: CGFloat = 5
        let halfShip = Self.shipWidth / 2
        for i in 0..<ships.count where ships[i].alive {
            let dir = ships[i].owner == 1 ? p1MoveDir : p2MoveDir
            ships[i].x += CGFloat(dir) * speed
            ships[i].x = max(halfShip, min(Self.courtWidth - halfShip, ships[i].x))
        }
    }

    private func moveBullets() {
        for i in 0..<bullets.count {
            bullets[i].y += bullets[i].vy
        }
        bullets.removeAll { $0.y < -20 || $0.y > Self.courtHeight + 20 }
    }

    private func maybeStepAliens() {
        alienStepCounter += 1
        let alive = aliens.filter { $0.alive }.count
        let raw = 6 + alive
        let stepEvery = max(5, raw - (wave - 1) * 4)
        if alienStepCounter < stepEvery { return }
        alienStepCounter = 0

        let proposed = aliens.map { $0.alive ? $0.x + Self.alienStepX * CGFloat(alienDirection) : $0.x }
        let aliveProposed = zip(aliens, proposed).filter { $0.0.alive }.map { $0.1 }
        guard let minX = aliveProposed.min(), let maxX = aliveProposed.max() else { return }

        let leftLimit = Self.alienWidth / 2 + 4
        let rightLimit = Self.courtWidth - Self.alienWidth / 2 - 4

        if minX < leftLimit || maxX > rightLimit {
            for i in 0..<aliens.count where aliens[i].alive {
                aliens[i].y += Self.alienStepY
            }
            alienDirection = -alienDirection
        } else {
            for i in 0..<aliens.count where aliens[i].alive {
                aliens[i].x += Self.alienStepX * CGFloat(alienDirection)
            }
        }
    }

    private func maybeAlienFire() {
        let chance = 0.018 + 0.005 * Double(wave - 1)
        guard Double.random(in: 0..<1) < chance else { return }
        let aliveAliens = aliens.filter { $0.alive }
        guard !aliveAliens.isEmpty else { return }
        let cols = Set(aliveAliens.map { $0.col })
        guard let col = cols.randomElement() else { return }
        guard let shooter = aliveAliens.filter({ $0.col == col }).max(by: { $0.y < $1.y }) else { return }
        bullets.append(InvadersBullet(
            id: nextBulletID,
            x: shooter.x,
            y: shooter.y + Self.alienHeight / 2,
            vy: 4 + CGFloat(wave - 1) * 0.3,
            owner: 0
        ))
        nextBulletID += 1
    }

    private func resolveCollisions() {
        var bulletsToRemove: Set<Int> = []

        for bIdx in 0..<bullets.count {
            let bullet = bullets[bIdx]
            if bullet.owner == 0 {
                for sIdx in 0..<ships.count {
                    let ship = ships[sIdx]
                    guard ship.alive, tickCount >= ship.invulnUntilTick else { continue }
                    if rectsOverlap(
                        cx1: bullet.x, cy1: bullet.y, w1: Self.bulletWidth, h1: Self.bulletHeight,
                        cx2: ship.x, cy2: ship.y, w2: Self.shipWidth, h2: Self.shipHeight
                    ) {
                        ships[sIdx].lives -= 1
                        ships[sIdx].invulnUntilTick = tickCount + 90
                        bulletsToRemove.insert(bullet.id)
                    }
                }
            } else {
                for aIdx in 0..<aliens.count {
                    let alien = aliens[aIdx]
                    guard alien.alive else { continue }
                    if rectsOverlap(
                        cx1: bullet.x, cy1: bullet.y, w1: Self.bulletWidth, h1: Self.bulletHeight,
                        cx2: alien.x, cy2: alien.y, w2: Self.alienWidth, h2: Self.alienHeight
                    ) {
                        aliens[aIdx].alive = false
                        let pts = alien.type.points
                        if bullet.owner == 1 { p1Score += pts } else { p2Score += pts }
                        bulletsToRemove.insert(bullet.id)
                        break
                    }
                }
            }
        }
        if !bulletsToRemove.isEmpty {
            bullets.removeAll { bulletsToRemove.contains($0.id) }
        }
    }

    private func rectsOverlap(cx1: CGFloat, cy1: CGFloat, w1: CGFloat, h1: CGFloat,
                              cx2: CGFloat, cy2: CGFloat, w2: CGFloat, h2: CGFloat) -> Bool {
        abs(cx1 - cx2) < (w1 + w2) / 2 && abs(cy1 - cy2) < (h1 + h2) / 2
    }

    private func checkEnd() {
        if !aliens.contains(where: { $0.alive }) {
            wave += 1
            spawnWave()
            return
        }
        let aliveAliens = aliens.filter { $0.alive }
        let bottomLine = Self.shipY - Self.shipHeight / 2 - 8
        if aliveAliens.contains(where: { $0.y >= bottomLine }) {
            endReason = "Aliens reached the line"
            phase = .gameOver
            return
        }
        let totalLives = ships.reduce(0) { $0 + max(0, $1.lives) }
        if totalLives <= 0 {
            endReason = "All ships destroyed"
            phase = .gameOver
        }
    }

    func isShipFlashing(_ ship: InvaderShip) -> Bool {
        ship.alive && tickCount < ship.invulnUntilTick && (tickCount / 4) % 2 == 0
    }
}
