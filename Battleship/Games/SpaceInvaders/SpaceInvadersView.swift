import SwiftUI

struct SpaceInvadersView: View {
    @StateObject private var game = SpaceInvadersGame()
    var onExit: () -> Void = {}

    @FocusState private var focused: Bool
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "SPACE INVADERS",
                statusContent: AnyView(statusContent),
                onNewGame: { game.returnToMenu(); focused = true },
                onExit: onExit
            )

            ScaledFit(width: SpaceInvadersGame.courtWidth, height: SpaceInvadersGame.courtHeight) {
                content
            }
            .frame(maxHeight: .infinity)
        }
        .background(Color.black)
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .onReceive(timer) { _ in game.tick() }
        .onKeyPress(phases: [.down, .up]) { keyPress in
            handleKey(keyPress)
        }
    }

    private func handleKey(_ keyPress: KeyPress) -> KeyPress.Result {
        let isDown = keyPress.phase == .down

        switch keyPress.key {
        case .leftArrow:
            if game.playerCount == 2 {
                game.p2MoveDir = isDown ? -1 : 0
            } else {
                game.p1MoveDir = isDown ? -1 : 0
            }
            return .handled
        case .rightArrow:
            if game.playerCount == 2 {
                game.p2MoveDir = isDown ? 1 : 0
            } else {
                game.p1MoveDir = isDown ? 1 : 0
            }
            return .handled
        case .space:
            if isDown {
                if game.playerCount == 2 { game.fire(owner: 2) }
                else { game.fire(owner: 1) }
            }
            return .handled
        default: break
        }

        switch keyPress.characters.lowercased() {
        case "a":
            game.p1MoveDir = isDown ? -1 : 0
            return .handled
        case "d":
            game.p1MoveDir = isDown ? 1 : 0
            return .handled
        case "w":
            if isDown { game.fire(owner: 1) }
            return .handled
        case "p":
            if isDown { game.togglePause() }
            return .handled
        default:
            return .ignored
        }
    }

    private var statusContent: some View {
        Group {
            switch game.phase {
            case .menu:
                Text("Pick a mode")
                    .foregroundColor(.gray)
            case .playing:
                HStack(spacing: 10) {
                    Text("Wave \(game.wave)").foregroundColor(.white).fontWeight(.bold)
                    Text("·").foregroundColor(.gray)
                    Text(scoreText).foregroundColor(.white)
                    Text("·").foregroundColor(.gray)
                    Text(livesText).foregroundColor(.white)
                }
            case .gameOver:
                Text(game.endReason).foregroundColor(.red).fontWeight(.bold)
            }
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
    }

    private var scoreText: String {
        if game.playerCount == 1 { return "Score \(game.p1Score)" }
        return "P1 \(game.p1Score)  P2 \(game.p2Score)"
    }

    private var livesText: String {
        if game.playerCount == 1 {
            return "Lives \(max(0, game.ships.first?.lives ?? 0))"
        }
        let p1 = game.ships.first(where: { $0.owner == 1 })?.lives ?? 0
        let p2 = game.ships.first(where: { $0.owner == 2 })?.lives ?? 0
        return "P1×\(max(0, p1))  P2×\(max(0, p2))"
    }

    @ViewBuilder
    private var content: some View {
        switch game.phase {
        case .menu:
            menu
        case .playing, .gameOver:
            ZStack {
                court
                if game.phase == .gameOver {
                    gameOverOverlay
                } else if game.isPaused {
                    pausedOverlay
                }
            }
        }
    }

    private var menu: some View {
        VStack(spacing: 24) {
            Text("SPACE INVADERS")
                .font(.system(size: 36, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            Text("Pick a mode")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.gray)

            HStack(spacing: 24) {
                Button(action: { game.startGame(players: 1); focused = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                        Text("1 Player")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                        Text("←/→  space")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 180, height: 140)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(white: 0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(white: 0.4), lineWidth: 2)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button(action: { game.startGame(players: 2); focused = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 28))
                        Text("2 Players (Co-op)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                        Text("P1: A/D + W")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("P2: ←/→ + space")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 220, height: 140)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(white: 0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(white: 0.4), lineWidth: 2)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var court: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.black)
                .frame(width: SpaceInvadersGame.courtWidth, height: SpaceInvadersGame.courtHeight)

            ForEach(game.aliens) { alien in
                if alien.alive {
                    alienView(alien)
                        .position(x: alien.x, y: alien.y)
                }
            }

            ForEach(game.ships) { ship in
                if ship.alive {
                    shipView(ship)
                        .position(x: ship.x, y: ship.y)
                        .opacity(game.isShipFlashing(ship) ? 0.4 : 1.0)
                }
            }

            ForEach(game.bullets) { bullet in
                Rectangle()
                    .fill(bullet.owner == 0 ? Color.red : Color.white)
                    .frame(width: SpaceInvadersGame.bulletWidth, height: SpaceInvadersGame.bulletHeight)
                    .position(x: bullet.x, y: bullet.y)
            }

            Rectangle()
                .fill(Color.green.opacity(0.5))
                .frame(width: SpaceInvadersGame.courtWidth, height: 2)
                .position(x: SpaceInvadersGame.courtWidth / 2,
                          y: SpaceInvadersGame.shipY + SpaceInvadersGame.shipHeight / 2 + 6)
        }
        .frame(width: SpaceInvadersGame.courtWidth, height: SpaceInvadersGame.courtHeight)
        .overlay(
            Rectangle()
                .stroke(Color(white: 0.3), lineWidth: 2)
        )
    }

    private func shipView(_ ship: InvaderShip) -> some View {
        let color: Color = ship.owner == 1 ? Color(red: 0.4, green: 0.95, blue: 0.4)
                                            : Color(red: 0.4, green: 0.7, blue: 1.0)
        return ZStack {
            Rectangle()
                .fill(color)
                .frame(width: SpaceInvadersGame.shipWidth, height: 6)
                .offset(y: 6)
            Rectangle()
                .fill(color)
                .frame(width: 22, height: 6)
                .offset(y: 0)
            Rectangle()
                .fill(color)
                .frame(width: 6, height: 8)
                .offset(y: -7)
        }
    }

    private func alienView(_ alien: Alien) -> some View {
        let color: Color = {
            switch alien.type {
            case .small:  return Color(red: 0.85, green: 0.40, blue: 0.95)
            case .medium: return Color(red: 0.40, green: 0.95, blue: 0.55)
            case .large:  return Color(red: 0.40, green: 0.85, blue: 0.95)
            }
        }()
        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 22, height: 14)
            Rectangle()
                .fill(color)
                .frame(width: 4, height: 4)
                .offset(x: -8, y: -10)
            Rectangle()
                .fill(color)
                .frame(width: 4, height: 4)
                .offset(x: 8, y: -10)
            Circle()
                .fill(Color.black)
                .frame(width: 3, height: 3)
                .offset(x: -4, y: -1)
            Circle()
                .fill(Color.black)
                .frame(width: 3, height: 3)
                .offset(x: 4, y: -1)
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Rectangle().fill(Color.black.opacity(0.75))
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
                    Text("Game Over").fontWeight(.bold)
                }
                .font(.system(size: 28, design: .monospaced))
                .foregroundColor(.white)

                Text(game.endReason)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)

                if game.playerCount == 1 {
                    Text("Score: \(game.p1Score) · Wave \(game.wave)")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.white)
                } else {
                    Text("P1 \(game.p1Score)  ·  P2 \(game.p2Score)")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.white)
                    Text("Wave \(game.wave)")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.gray)
                }

                HStack(spacing: 12) {
                    Button("Menu") { game.returnToMenu(); focused = true }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    Button("Play Again") { game.startGame(players: game.playerCount); focused = true }
                        .keyboardShortcut(.return, modifiers: [])
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }
        }
    }

    private var pausedOverlay: some View {
        ZStack {
            Rectangle().fill(Color.black.opacity(0.6))
            Text("PAUSED")
                .font(.system(size: 36, weight: .black, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}
