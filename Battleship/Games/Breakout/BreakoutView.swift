import SwiftUI

struct BreakoutView: View {
    @StateObject private var game = BreakoutGame()
    var onExit: () -> Void = {}

    @FocusState private var focused: Bool
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private static let brickColors: [Color] = [
        Color(red: 0.95, green: 0.30, blue: 0.30),
        Color(red: 0.95, green: 0.55, blue: 0.20),
        Color(red: 0.30, green: 0.80, blue: 0.40),
        Color(red: 0.95, green: 0.85, blue: 0.20)
    ]

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "BREAKOUT",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset(); focused = true },
                onExit: onExit
            )

            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    court
                    overlay
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black)
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .onReceive(timer) { _ in game.tick() }
        .onKeyPress(phases: [.down, .up]) { keyPress in
            let isDown = keyPress.phase == .down
            switch keyPress.key {
            case .leftArrow:
                game.moveDir = isDown ? -1 : 0
                return .handled
            case .rightArrow:
                game.moveDir = isDown ? 1 : 0
                return .handled
            case .space:
                if isDown {
                    if game.phase == .ready || game.phase == .lostBall {
                        game.launch()
                    } else {
                        game.togglePause()
                    }
                }
                return .handled
            default: break
            }
            switch keyPress.characters.lowercased() {
            case "a":
                game.moveDir = isDown ? -1 : 0
                return .handled
            case "d":
                game.moveDir = isDown ? 1 : 0
                return .handled
            case "p":
                if isDown { game.togglePause() }
                return .handled
            default:
                return .ignored
            }
        }
    }

    private var statusContent: some View {
        HStack(spacing: 8) {
            Text("Score:").foregroundColor(.gray)
            Text("\(game.score)").foregroundColor(.white).fontWeight(.bold)
            Text("·").foregroundColor(.gray)
            Text("Lives:").foregroundColor(.gray)
            Text("\(max(0, game.lives))").foregroundColor(.white).fontWeight(.bold)
            Text("·").foregroundColor(.gray)
            Text("←/→ move · space launch/pause")
                .foregroundColor(.gray)
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
    }

    private var court: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.black)
                .frame(width: BreakoutGame.courtWidth, height: BreakoutGame.courtHeight)

            ForEach(game.bricks) { brick in
                if brick.alive {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Self.brickColors[brick.colorIndex])
                        .frame(width: BreakoutGame.brickWidth, height: BreakoutGame.brickHeight)
                        .position(
                            x: game.brickX(col: brick.col) + BreakoutGame.brickWidth / 2,
                            y: game.brickY(row: brick.row) + BreakoutGame.brickHeight / 2
                        )
                }
            }

            Rectangle()
                .fill(Color.white)
                .frame(width: BreakoutGame.paddleWidth, height: BreakoutGame.paddleHeight)
                .position(x: game.paddleX, y: BreakoutGame.paddleY)

            if game.phase != .gameOver && game.phase != .won {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: BreakoutGame.ballSize, height: BreakoutGame.ballSize)
                    .position(x: game.ballX, y: game.ballY)
            }
        }
        .frame(width: BreakoutGame.courtWidth, height: BreakoutGame.courtHeight)
        .overlay(
            Rectangle()
                .stroke(Color(white: 0.3), lineWidth: 2)
        )
    }

    @ViewBuilder
    private var overlay: some View {
        switch game.phase {
        case .ready:
            messageBox(title: "READY", subtitle: "Press SPACE to launch")
        case .lostBall:
            messageBox(title: "READY", subtitle: "Lives left: \(game.lives) — SPACE to continue")
        case .won:
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").foregroundColor(.yellow)
                    Text("Cleared!").fontWeight(.bold)
                }
                .font(.system(size: 28, design: .monospaced))
                .foregroundColor(.white)
                Text("Score: \(game.score)")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.gray)
                Button("Play Again") { game.reset(); focused = true }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
            }
            .padding(20)
            .background(Color.black.opacity(0.75))
            .cornerRadius(10)
        case .gameOver:
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
                    Text("Game Over").fontWeight(.bold)
                }
                .font(.system(size: 28, design: .monospaced))
                .foregroundColor(.white)
                Text("Score: \(game.score)")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.gray)
                Button("Play Again") { game.reset(); focused = true }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
            }
            .padding(20)
            .background(Color.black.opacity(0.75))
            .cornerRadius(10)
        case .playing:
            if game.isPaused {
                Text("PAUSED")
                    .font(.system(size: 36, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
            }
        }
    }

    private func messageBox(title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 24).padding(.vertical, 12)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
}
