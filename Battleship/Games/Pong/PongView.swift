import SwiftUI

struct PongView: View {
    @StateObject private var game = PongGame()
    var onExit: () -> Void = {}

    @FocusState private var focused: Bool
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "PONG",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset(); focused = true },
                onExit: onExit
            )

            VStack(spacing: 0) {
                Spacer()
                court
                Spacer()
                if game.winner != nil {
                    resultBanner.padding(.bottom, 24)
                }
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
            case .upArrow:
                game.rightMoveDir = isDown ? -1 : 0
                return .handled
            case .downArrow:
                game.rightMoveDir = isDown ? 1 : 0
                return .handled
            case .space:
                if isDown { game.togglePause() }
                return .handled
            default:
                switch keyPress.characters.lowercased() {
                case "w":
                    game.leftMoveDir = isDown ? -1 : 0
                    return .handled
                case "s":
                    game.leftMoveDir = isDown ? 1 : 0
                    return .handled
                default:
                    return .ignored
                }
            }
        }
    }

    private var statusContent: some View {
        HStack(spacing: 8) {
            Text("W/S vs ↑/↓")
                .foregroundColor(.gray)
            Text("·").foregroundColor(.gray)
            Text("space to pause")
                .foregroundColor(.gray)
            Text("·").foregroundColor(.gray)
            Text("first to \(PongGame.winningScore)")
                .foregroundColor(.gray)
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
    }

    private var court: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.black)
                .frame(width: PongGame.courtWidth, height: PongGame.courtHeight)

            centerLine

            scoreboard

            Rectangle()
                .fill(Color.white)
                .frame(width: PongGame.paddleWidth, height: PongGame.paddleHeight)
                .position(x: PongGame.paddleMargin + PongGame.paddleWidth / 2, y: game.leftPaddleY)

            Rectangle()
                .fill(Color.white)
                .frame(width: PongGame.paddleWidth, height: PongGame.paddleHeight)
                .position(x: PongGame.courtWidth - PongGame.paddleMargin - PongGame.paddleWidth / 2,
                          y: game.rightPaddleY)

            Rectangle()
                .fill(Color.white)
                .frame(width: PongGame.ballSize, height: PongGame.ballSize)
                .position(game.ballPos)

            if game.isPaused && game.winner == nil {
                Text("PAUSED")
                    .font(.system(size: 36, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .position(x: PongGame.courtWidth / 2, y: PongGame.courtHeight / 2)
            }
        }
        .frame(width: PongGame.courtWidth, height: PongGame.courtHeight)
        .overlay(
            Rectangle()
                .stroke(Color(white: 0.3), lineWidth: 2)
        )
    }

    private var centerLine: some View {
        let dashCount = 14
        let dashHeight = PongGame.courtHeight / CGFloat(dashCount * 2)
        return VStack(spacing: dashHeight) {
            ForEach(0..<dashCount, id: \.self) { _ in
                Rectangle()
                    .fill(Color(white: 0.3))
                    .frame(width: 4, height: dashHeight)
            }
        }
        .position(x: PongGame.courtWidth / 2, y: PongGame.courtHeight / 2)
    }

    private var scoreboard: some View {
        HStack(spacing: 80) {
            Text("\(game.leftScore)")
                .frame(width: 80, alignment: .center)
            Text("\(game.rightScore)")
                .frame(width: 80, alignment: .center)
        }
        .font(.system(size: 64, weight: .black, design: .monospaced))
        .foregroundColor(Color(white: 0.5))
        .position(x: PongGame.courtWidth / 2, y: 60)
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            if let w = game.winner {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").foregroundColor(.yellow)
                    Text("\(w.name) wins!")
                        .fontWeight(.bold)
                }
                .font(.system(size: 28, design: .monospaced))
                .foregroundColor(.white)

                Text("\(game.leftScore) – \(game.rightScore)")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Button("Play Again") { game.reset(); focused = true }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
