import Foundation
import CoreGraphics

enum PongSide: Equatable {
    case left, right
    var name: String { self == .left ? "Left" : "Right" }
}

class PongGame: ObservableObject {
    static let courtWidth: CGFloat = 640
    static let courtHeight: CGFloat = 420
    static let paddleWidth: CGFloat = 14
    static let paddleHeight: CGFloat = 80
    static let paddleMargin: CGFloat = 24
    static let ballSize: CGFloat = 14
    static let winningScore = 7
    static let paddleSpeed: CGFloat = 6
    static let initialBallSpeed: CGFloat = 4.5
    static let maxBallSpeed: CGFloat = 12

    @Published var leftPaddleY: CGFloat
    @Published var rightPaddleY: CGFloat
    @Published var ballPos: CGPoint
    @Published var ballVel: CGVector
    @Published var leftScore: Int = 0
    @Published var rightScore: Int = 0
    @Published var isPaused: Bool = false
    @Published var winner: PongSide? = nil

    var leftMoveDir: Int = 0
    var rightMoveDir: Int = 0

    init() {
        leftPaddleY = Self.courtHeight / 2
        rightPaddleY = Self.courtHeight / 2
        ballPos = CGPoint(x: Self.courtWidth / 2, y: Self.courtHeight / 2)
        ballVel = CGVector(dx: Self.initialBallSpeed, dy: CGFloat.random(in: -2...2))
    }

    func reset() {
        leftPaddleY = Self.courtHeight / 2
        rightPaddleY = Self.courtHeight / 2
        leftScore = 0
        rightScore = 0
        winner = nil
        isPaused = false
        leftMoveDir = 0
        rightMoveDir = 0
        resetBall(servingTo: Bool.random() ? .left : .right)
    }

    func togglePause() {
        guard winner == nil else { return }
        isPaused.toggle()
    }

    func tick() {
        guard winner == nil, !isPaused else { return }

        leftPaddleY += CGFloat(leftMoveDir) * Self.paddleSpeed
        rightPaddleY += CGFloat(rightMoveDir) * Self.paddleSpeed
        let halfPad = Self.paddleHeight / 2
        leftPaddleY = max(halfPad, min(Self.courtHeight - halfPad, leftPaddleY))
        rightPaddleY = max(halfPad, min(Self.courtHeight - halfPad, rightPaddleY))

        ballPos.x += ballVel.dx
        ballPos.y += ballVel.dy

        let halfBall = Self.ballSize / 2
        if ballPos.y < halfBall {
            ballPos.y = halfBall
            ballVel.dy = abs(ballVel.dy)
        } else if ballPos.y > Self.courtHeight - halfBall {
            ballPos.y = Self.courtHeight - halfBall
            ballVel.dy = -abs(ballVel.dy)
        }

        let leftPaddleX = Self.paddleMargin + Self.paddleWidth / 2
        if ballVel.dx < 0,
           ballPos.x - halfBall <= leftPaddleX + Self.paddleWidth / 2,
           ballPos.x >= leftPaddleX - Self.paddleWidth / 2,
           abs(ballPos.y - leftPaddleY) <= Self.paddleHeight / 2 + halfBall {
            bounceOffPaddle(at: leftPaddleY)
            ballVel.dx = abs(ballVel.dx)
            ballPos.x = leftPaddleX + Self.paddleWidth / 2 + halfBall
        }

        let rightPaddleX = Self.courtWidth - Self.paddleMargin - Self.paddleWidth / 2
        if ballVel.dx > 0,
           ballPos.x + halfBall >= rightPaddleX - Self.paddleWidth / 2,
           ballPos.x <= rightPaddleX + Self.paddleWidth / 2,
           abs(ballPos.y - rightPaddleY) <= Self.paddleHeight / 2 + halfBall {
            bounceOffPaddle(at: rightPaddleY)
            ballVel.dx = -abs(ballVel.dx)
            ballPos.x = rightPaddleX - Self.paddleWidth / 2 - halfBall
        }

        if ballPos.x < -halfBall {
            rightScore += 1
            if rightScore >= Self.winningScore { winner = .right }
            else { resetBall(servingTo: .left) }
        } else if ballPos.x > Self.courtWidth + halfBall {
            leftScore += 1
            if leftScore >= Self.winningScore { winner = .left }
            else { resetBall(servingTo: .right) }
        }
    }

    private func bounceOffPaddle(at paddleY: CGFloat) {
        let hit = (ballPos.y - paddleY) / (Self.paddleHeight / 2)
        let speedFactor: CGFloat = 1.05
        ballVel.dx *= speedFactor
        ballVel.dy = hit * 5 * speedFactor
        clampBallSpeed()
    }

    private func clampBallSpeed() {
        ballVel.dx = max(-Self.maxBallSpeed, min(Self.maxBallSpeed, ballVel.dx))
        ballVel.dy = max(-Self.maxBallSpeed, min(Self.maxBallSpeed, ballVel.dy))
    }

    private func resetBall(servingTo side: PongSide) {
        ballPos = CGPoint(x: Self.courtWidth / 2, y: Self.courtHeight / 2)
        let dx = side == .left ? -Self.initialBallSpeed : Self.initialBallSpeed
        ballVel = CGVector(dx: dx, dy: CGFloat.random(in: -2...2))
    }
}
