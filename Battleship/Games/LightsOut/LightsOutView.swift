import SwiftUI

struct LightsOutView: View {
    @StateObject private var game = LightsOutGame()
    var onExit: () -> Void = {}

    private let cellSize: CGFloat = 80
    private let spacing: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "LIGHTS OUT",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset() },
                onExit: onExit
            )

            ScaledFit(width: 5 * cellSize + 4 * spacing + 2 * spacing,
                      height: 5 * cellSize + 4 * spacing + 2 * spacing) {
                board
            }
            .frame(maxHeight: .infinity)
            if game.isSolved {
                resultBanner.padding(.bottom, 24)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(white: 0.10), Color(white: 0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var statusContent: some View {
        HStack(spacing: 8) {
            Text("Moves:").foregroundColor(.gray)
            Text("\(game.moves)").foregroundColor(.white).fontWeight(.bold)
            Text("·").foregroundColor(.gray)
            Text("turn off every light")
                .foregroundColor(.gray)
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
    }

    private var board: some View {
        VStack(spacing: spacing) {
            ForEach(0..<LightsOutGame.size, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<LightsOutGame.size, id: \.self) { col in
                        cell(row: row, col: col)
                    }
                }
            }
        }
        .padding(spacing)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(white: 0.30), lineWidth: 2)
        )
    }

    private func cell(row: Int, col: Int) -> some View {
        let lit = game.grid[row][col]
        return Button(action: { game.tap(row: row, col: col) }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(lit
                        ? LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.85, blue: 0.30),
                                Color(red: 0.95, green: 0.65, blue: 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color(white: 0.18), Color(white: 0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: cellSize, height: cellSize)

                if lit {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                        .frame(width: cellSize - 6, height: cellSize - 6)
                }
            }
            .shadow(color: lit ? .yellow.opacity(0.4) : .clear, radius: 8)
            .animation(.easeInOut(duration: 0.12), value: lit)
        }
        .buttonStyle(.plain)
        .disabled(game.isSolved)
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill").foregroundColor(.yellow)
                Text("All out!").fontWeight(.bold)
            }
            .font(.system(size: 26, design: .monospaced))
            .foregroundColor(.white)
            Text("\(game.moves) moves")
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
            Button("New Puzzle") { game.reset() }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
