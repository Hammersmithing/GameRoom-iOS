import SwiftUI

struct TwentyFortyEightView: View {
    @StateObject private var game = TwentyFortyEightGame()
    var onExit: () -> Void = {}

    @FocusState private var focused: Bool
    private let tileSize: CGFloat = 86
    private let gap: CGFloat = 10

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "2048",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset(); focused = true },
                onExit: onExit
            )

            VStack(spacing: 0) {
                Spacer()
                board
                Spacer()
                if banner {
                    bannerView.padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            LinearGradient(
                colors: [Color(white: 0.10), Color(white: 0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .onKeyPress(.upArrow)    { game.move(.up); return .handled }
        .onKeyPress(.downArrow)  { game.move(.down); return .handled }
        .onKeyPress(.leftArrow)  { game.move(.left); return .handled }
        .onKeyPress(.rightArrow) { game.move(.right); return .handled }
        .onKeyPress(phases: .down) { keyPress in
            switch keyPress.characters.lowercased() {
            case "w": game.move(.up);    return .handled
            case "s": game.move(.down);  return .handled
            case "a": game.move(.left);  return .handled
            case "d": game.move(.right); return .handled
            default:  return .ignored
            }
        }
    }

    private var statusContent: some View {
        HStack(spacing: 8) {
            Text("Score:").foregroundColor(.gray)
            Text("\(game.score)")
                .foregroundColor(.white)
                .fontWeight(.bold)
            Text("·").foregroundColor(.gray)
            Text("↑↓←→ to slide")
                .foregroundColor(.gray)
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
    }

    private var board: some View {
        VStack(spacing: gap) {
            ForEach(0..<TwentyFortyEightGame.size, id: \.self) { r in
                HStack(spacing: gap) {
                    ForEach(0..<TwentyFortyEightGame.size, id: \.self) { c in
                        tile(value: game.grid[r][c])
                    }
                }
            }
        }
        .padding(gap)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.73, green: 0.68, blue: 0.63))
        )
    }

    private func tile(value: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(tileBackground(value))
                .frame(width: tileSize, height: tileSize)
            if value > 0 {
                Text("\(value)")
                    .font(.system(size: tileFontSize(value), weight: .heavy, design: .monospaced))
                    .foregroundColor(tileTextColor(value))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
            }
        }
        .animation(.easeInOut(duration: 0.12), value: value)
    }

    private func tileBackground(_ value: Int) -> Color {
        switch value {
        case 0:    return Color(red: 0.80, green: 0.76, blue: 0.71)
        case 2:    return Color(red: 0.93, green: 0.89, blue: 0.85)
        case 4:    return Color(red: 0.93, green: 0.88, blue: 0.78)
        case 8:    return Color(red: 0.95, green: 0.69, blue: 0.47)
        case 16:   return Color(red: 0.96, green: 0.58, blue: 0.39)
        case 32:   return Color(red: 0.96, green: 0.49, blue: 0.37)
        case 64:   return Color(red: 0.96, green: 0.37, blue: 0.23)
        case 128:  return Color(red: 0.93, green: 0.81, blue: 0.45)
        case 256:  return Color(red: 0.93, green: 0.80, blue: 0.38)
        case 512:  return Color(red: 0.93, green: 0.78, blue: 0.31)
        case 1024: return Color(red: 0.93, green: 0.77, blue: 0.25)
        case 2048: return Color(red: 0.93, green: 0.76, blue: 0.18)
        default:   return Color(red: 0.24, green: 0.22, blue: 0.20)
        }
    }

    private func tileTextColor(_ value: Int) -> Color {
        value < 8 ? Color(red: 0.46, green: 0.43, blue: 0.40) : .white
    }

    private func tileFontSize(_ value: Int) -> CGFloat {
        switch value {
        case 0...64:        return 36
        case 65...512:      return 30
        case 513...4096:    return 26
        default:            return 22
        }
    }

    private var banner: Bool {
        game.isGameOver || (game.hasWon && !game.keepPlaying)
    }

    @ViewBuilder
    private var bannerView: some View {
        VStack(spacing: 12) {
            if game.isGameOver {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
                    Text("Game Over").fontWeight(.bold)
                }
                .font(.system(size: 28, design: .monospaced))
                .foregroundColor(.white)
                Text("Score: \(game.score)")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                Button("Play Again") { game.reset(); focused = true }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            } else if game.hasWon && !game.keepPlaying {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").foregroundColor(.yellow)
                    Text("You reached 2048!").fontWeight(.bold)
                }
                .font(.system(size: 26, design: .monospaced))
                .foregroundColor(.white)
                HStack(spacing: 12) {
                    Button("Keep Playing") { game.dismissWinBanner(); focused = true }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    Button("New Game") { game.reset(); focused = true }
                        .keyboardShortcut(.return, modifiers: [])
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }
        }
    }
}
