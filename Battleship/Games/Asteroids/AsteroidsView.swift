import SwiftUI

struct AsteroidsView: View {
    @StateObject private var game = AsteroidsGame()
    var onExit: () -> Void = {}

    @FocusState private var focused: Bool
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "ASTEROIDS",
                statusContent: AnyView(statusContent),
                onNewGame: { game.returnToMenu(); focused = true },
                onExit: onExit
            )

            ScaledFit(width: AsteroidsGame.courtWidth, height: AsteroidsGame.courtHeight) {
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
        .onKeyPress(phases: [.down, .up]) { handleKey($0) }
    }

    private func handleKey(_ keyPress: KeyPress) -> KeyPress.Result {
        let isDown = keyPress.phase == .down

        switch keyPress.key {
        case .leftArrow:
            let p = game.playerCount == 2 ? 2 : 1
            game.setRotate(owner: p, dir: isDown ? -1 : 0)
            return .handled
        case .rightArrow:
            let p = game.playerCount == 2 ? 2 : 1
            game.setRotate(owner: p, dir: isDown ? 1 : 0)
            return .handled
        case .upArrow:
            let p = game.playerCount == 2 ? 2 : 1
            game.setThrust(owner: p, on: isDown)
            return .handled
        case .space:
            if isDown {
                let p = game.playerCount == 2 ? 2 : 1
                game.fire(owner: p)
            }
            return .handled
        default: break
        }

        switch keyPress.characters.lowercased() {
        case "a":
            game.setRotate(owner: 1, dir: isDown ? -1 : 0)
            return .handled
        case "d":
            game.setRotate(owner: 1, dir: isDown ? 1 : 0)
            return .handled
        case "w":
            game.setThrust(owner: 1, on: isDown)
            return .handled
        case "s":
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
                Text("Pick a mode").foregroundColor(.gray)
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
            Text("ASTEROIDS")
                .font(.system(size: 36, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            Text("Pick a mode")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.gray)

            HStack(spacing: 24) {
                Button(action: { game.startGame(players: 1); focused = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.fill").font(.system(size: 28))
                        Text("1 Player")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                        Text("←/→  ↑  space")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 200, height: 150)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.15)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.4), lineWidth: 2))
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button(action: { game.startGame(players: 2); focused = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.2.fill").font(.system(size: 28))
                        Text("2 Players (Co-op)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                        Text("P1: A/D  W  S")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("P2: ←/→  ↑  space")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 240, height: 150)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.15)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.4), lineWidth: 2))
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
                .frame(width: AsteroidsGame.courtWidth, height: AsteroidsGame.courtHeight)

            ForEach(game.asteroids) { asteroid in
                asteroidView(asteroid)
                    .position(x: asteroid.x, y: asteroid.y)
            }

            ForEach(game.ships) { ship in
                if ship.alive {
                    shipView(ship)
                        .position(x: ship.x, y: ship.y)
                        .opacity(game.isShipFlashing(ship) ? 0.4 : 1.0)
                }
            }

            ForEach(game.bullets) { bullet in
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                    .position(x: bullet.x, y: bullet.y)
            }
        }
        .frame(width: AsteroidsGame.courtWidth, height: AsteroidsGame.courtHeight)
        .clipped()
        .overlay(Rectangle().stroke(Color(white: 0.3), lineWidth: 2))
    }

    private func shipView(_ ship: AsteroidsShip) -> some View {
        let color: Color = ship.owner == 1
            ? Color(red: 0.45, green: 0.95, blue: 0.55)
            : Color(red: 0.45, green: 0.75, blue: 1.0)
        return ZStack {
            if ship.thrusting {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 14))
                    p.addLine(to: CGPoint(x: -4, y: 6))
                    p.addLine(to: CGPoint(x: 4, y: 6))
                    p.closeSubpath()
                }
                .fill(Color.orange)
            }
            Path { p in
                p.move(to: CGPoint(x: 0, y: -12))
                p.addLine(to: CGPoint(x: 8, y: 8))
                p.addLine(to: CGPoint(x: 0, y: 4))
                p.addLine(to: CGPoint(x: -8, y: 8))
                p.closeSubpath()
            }
            .stroke(color, lineWidth: 2)
        }
        .frame(width: 30, height: 30)
        .rotationEffect(.radians(Double(ship.angle)))
    }

    private func asteroidView(_ asteroid: Asteroid) -> some View {
        Path { path in
            let pts = asteroid.shape
            guard !pts.isEmpty else { return }
            path.move(to: pts[0])
            for p in pts.dropFirst() {
                path.addLine(to: p)
            }
            path.closeSubpath()
        }
        .stroke(Color(white: 0.85), lineWidth: 2)
        .frame(width: asteroid.size.radius * 2, height: asteroid.size.radius * 2)
        .rotationEffect(.radians(Double(asteroid.rotation)))
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
