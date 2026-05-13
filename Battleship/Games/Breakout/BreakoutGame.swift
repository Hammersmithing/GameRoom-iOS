import Foundation
import CoreGraphics

enum BreakoutPhase {
    case ready, playing, lostBall, won, gameOver
}

struct Brick: Identifiable, Equatable {
    let id: Int
    let row: Int
    let col: Int
    let points: Int
    let colorIndex: Int
    var alive: Bool = true
}

class BreakoutGame: ObservableObject {
    static let courtWidth: CGFloat = 720
    static let courtHeight: CGFloat = 480

    static let paddleWidth: CGFloat = 96
    static let paddleHeight: CGFloat = 14
    static let paddleY: CGFloat = courtHeight - 30

    static let ballSize: CGFloat = 12

    static let brickRows = 8
    static let brickCols = 10
    static let brickWidth: CGFloat = 64
    static let brickHeight: CGFloat = 18
    static let brickGap: CGFloat = 4
    static let brickTop: CGFloat = 60

    static let initialSpeed: CGFloat = 4.5
    static let maxSpeed: CGFloat = 10

    @Published var phase: BreakoutPhase = .ready
    @Published var paddleX: CGFloat = courtWidth / 2
    @Published var ballX: CGFloat = courtWidth / 2
    @Published var ballY: CGFloat = paddleY - paddleHeight
    @Published var ballVX: CGFloat = 0
    @Published var ballVY: CGFloat = 0
    @Published var bricks: [Brick] = []
    @Published var score: Int = 0
    @Published var lives: Int = 3
    @Published var isPaused: Bool = false

    var moveDir: Int = 0

    init() { reset() }

    func reset() {
        bricks = []
        var id = 0
        let totalWidth = CGFloat(Self.brickCols) * Self.brickWidth + CGFloat(Self.brickCols - 1) * Self.brickGap
        let startX = (Self.courtWidth - totalWidth) / 2
        for r in 0..<Self.brickRows {
            for c in 0..<Self.brickCols {
                let (pts, color): (Int, Int) = {
                    switch r {
                    case 0, 1: return (7, 0)   // red
                    case 2, 3: return (5, 1)   // orange
                    case 4, 5: return (3, 2)   // green
                    default:   return (1, 3)   // yellow
                    }
                }()
                bricks.append(Brick(
                    id: id, row: r, col: c,
                    points: pts, colorIndex: color
                ))
                id += 1
                _ = startX  // silence unused warning when laid out by view
            }
        }
        score = 0
        lives = 3
        paddleX = Self.courtWidth / 2
        moveDir = 0
        isPaused = false
        resetBall()
        phase = .ready
    }

    private func resetBall() {
        ballX = Self.courtWidth / 2
        ballY = Self.paddleY - Self.paddleHeight - Self.ballSize
        ballVX = 0
        ballVY = 0
    }

    func brickX(col: Int) -> CGFloat {
        let totalWidth = CGFloat(Self.brickCols) * Self.brickWidth + CGFloat(Self.brickCols - 1) * Self.brickGap
        let startX = (Self.courtWidth - totalWidth) / 2
        return startX + CGFloat(col) * (Self.brickWidth + Self.brickGap)
    }

    func brickY(row: Int) -> CGFloat {
        Self.brickTop + CGFloat(row) * (Self.brickHeight + Self.brickGap)
    }

    func launch() {
        guard phase == .ready || phase == .lostBall else { return }
        let dir: CGFloat = Bool.random() ? -1 : 1
        ballVX = dir * Self.initialSpeed * 0.6
        ballVY = -Self.initialSpeed
        phase = .playing
    }

    func togglePause() {
        guard phase == .playing else { return }
        isPaused.toggle()
    }

    func tick() {
        guard phase == .playing, !isPaused else { return }

        let speed: CGFloat = 7
        paddleX += CGFloat(moveDir) * speed
        paddleX = max(Self.paddleWidth / 2, min(Self.courtWidth - Self.paddleWidth / 2, paddleX))

        ballX += ballVX
        ballY += ballVY

        let half = Self.ballSize / 2
        if ballX - half < 0 {
            ballX = half
            ballVX = abs(ballVX)
        } else if ballX + half > Self.courtWidth {
            ballX = Self.courtWidth - half
            ballVX = -abs(ballVX)
        }
        if ballY - half < 0 {
            ballY = half
            ballVY = abs(ballVY)
        }

        let paddleTop = Self.paddleY - Self.paddleHeight / 2
        if ballVY > 0,
           ballY + half >= paddleTop,
           ballY - half <= Self.paddleY + Self.paddleHeight / 2,
           abs(ballX - paddleX) <= Self.paddleWidth / 2 + half {
            let hit = (ballX - paddleX) / (Self.paddleWidth / 2)
            let speed = max(Self.initialSpeed, hypot(ballVX, ballVY) * 1.02)
            let angle = hit * 1.0
            ballVX = sin(angle) * speed
            ballVY = -abs(cos(angle) * speed)
            clampSpeed()
            ballY = paddleTop - half
        }

        if ballY - half > Self.courtHeight {
            lives -= 1
            if lives <= 0 {
                phase = .gameOver
            } else {
                phase = .lostBall
                resetBall()
            }
            return
        }

        for i in 0..<bricks.count where bricks[i].alive {
            let bx = brickX(col: bricks[i].col) + Self.brickWidth / 2
            let by = brickY(row: bricks[i].row) + Self.brickHeight / 2
            let dx = ballX - bx
            let dy = ballY - by
            let overlapX = (Self.brickWidth + Self.ballSize) / 2 - abs(dx)
            let overlapY = (Self.brickHeight + Self.ballSize) / 2 - abs(dy)
            if overlapX > 0 && overlapY > 0 {
                bricks[i].alive = false
                score += bricks[i].points
                if overlapX < overlapY {
                    ballVX = -ballVX
                    ballX += dx > 0 ? overlapX : -overlapX
                } else {
                    ballVY = -ballVY
                    ballY += dy > 0 ? overlapY : -overlapY
                }
                ballVX *= 1.005
                ballVY *= 1.005
                clampSpeed()
                if !bricks.contains(where: { $0.alive }) {
                    phase = .won
                }
                break
            }
        }
    }

    private func clampSpeed() {
        let speed = hypot(ballVX, ballVY)
        if speed > Self.maxSpeed {
            ballVX *= Self.maxSpeed / speed
            ballVY *= Self.maxSpeed / speed
        }
    }
}
