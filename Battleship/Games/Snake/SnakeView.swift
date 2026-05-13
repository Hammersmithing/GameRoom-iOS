import SwiftUI

struct SnakeView: View {
    @StateObject private var game = SnakeGame()
    var onExit: () -> Void = {}

    @FocusState private var focused: Bool
    private let cellSize: CGFloat = 26
    private let timer = Timer.publish(every: 0.13, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "SNAKE",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset(); focused = true },
                onExit: onExit
            )

            ScaledFit(width: 20 * cellSize + 12, height: 20 * cellSize + 12) {
                ZStack {
                    board
                    if game.isPaused && !game.isGameOver {
                        Text("PAUSED")
                            .font(.system(size: 36, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            if game.isGameOver {
                resultBanner.padding(.bottom, 24)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(white: 0.1), Color(white: 0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .onReceive(timer) { _ in game.tick() }
        .onKeyPress(.upArrow)    { game.setDirection(.up); return .handled }
        .onKeyPress(.downArrow)  { game.setDirection(.down); return .handled }
        .onKeyPress(.leftArrow)  { game.setDirection(.left); return .handled }
        .onKeyPress(.rightArrow) { game.setDirection(.right); return .handled }
        .onKeyPress(.space)      { game.togglePause(); return .handled }
        .onKeyPress(phases: .down) { keyPress in
            switch keyPress.characters.lowercased() {
            case "w": game.setDirection(.up);    return .handled
            case "s": game.setDirection(.down);  return .handled
            case "a": game.setDirection(.left);  return .handled
            case "d": game.setDirection(.right); return .handled
            default:  return .ignored
            }
        }
    }

    private var statusContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf.fill").foregroundColor(.green)
            Text("\(game.score)")
                .foregroundColor(.white)
                .fontWeight(.bold)
            Text("·").foregroundColor(.gray)
            Text("↑↓←→ / WASD · space to pause")
                .foregroundColor(.gray)
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
    }

    private var board: some View {
        let snakeSet = Set(game.snake)
        let head = game.snake.first

        return VStack(spacing: 0) {
            ForEach(0..<SnakeGame.size, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<SnakeGame.size, id: \.self) { col in
                        cell(row: row, col: col, snakeSet: snakeSet, head: head)
                    }
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(white: 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(white: 0.3), lineWidth: 2)
        )
    }

    private func cell(row: Int, col: Int, snakeSet: Set<Position>, head: Position?) -> some View {
        let pos = Position(row: row, col: col)
        let isSnake = snakeSet.contains(pos)
        let isHead = head == pos
        let isFood = game.food == pos
        let isCheckered = (row + col) % 2 == 0

        return ZStack {
            Rectangle()
                .fill(isCheckered ? Color(white: 0.13) : Color(white: 0.10))
                .frame(width: cellSize, height: cellSize)

            if isSnake {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHead
                        ? Color(red: 0.4, green: 0.95, blue: 0.4)
                        : Color(red: 0.2, green: 0.75, blue: 0.3))
                    .frame(width: cellSize - 3, height: cellSize - 3)
            } else if isFood {
                Circle()
                    .fill(Color(red: 0.95, green: 0.25, blue: 0.25))
                    .frame(width: cellSize - 6, height: cellSize - 6)
                    .shadow(color: .red.opacity(0.6), radius: 4)
            }
        }
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
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
        }
    }
}
