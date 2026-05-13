import SwiftUI

struct ConnectFourView: View {
    @StateObject private var game = ConnectFourGame()
    var onExit: () -> Void = {}

    @State private var hoverCol: Int? = nil

    private let cellSize: CGFloat = 70
    private let spacing: CGFloat = 6

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "CONNECT FOUR",
                statusContent: AnyView(statusText),
                onNewGame: { game.reset() },
                onExit: onExit
            )

            VStack(spacing: 0) {
                Spacer()

                // Drop preview row
                HStack(spacing: spacing) {
                    ForEach(0..<ConnectFourGame.cols, id: \.self) { col in
                        ZStack {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: cellSize, height: cellSize)

                            if hoverCol == col && game.result == nil && game.lowestEmptyRow(in: col) != nil {
                                Circle()
                                    .fill(discColor(game.currentTurn).opacity(0.4))
                                    .frame(width: cellSize * 0.75, height: cellSize * 0.75)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)

                // Board
                VStack(spacing: spacing) {
                    ForEach(0..<ConnectFourGame.rows, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<ConnectFourGame.cols, id: \.self) { col in
                                cellView(row: row, col: col)
                            }
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.1, green: 0.15, blue: 0.45, opacity: 1.0))
                )
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let loc):
                        let colWidth = cellSize + spacing
                        let col = Int((loc.x - 12) / colWidth)
                        hoverCol = (col >= 0 && col < ConnectFourGame.cols) ? col : nil
                    case .ended:
                        hoverCol = nil
                    @unknown default:
                        break
                    }
                }

                Spacer()

                if game.result != nil {
                    resultBanner
                        .padding(.bottom, 30)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.18, opacity: 1.0),
                    Color(red: 0.02, green: 0.02, blue: 0.1, opacity: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var statusText: some View {
        Group {
            if game.result == nil {
                HStack(spacing: 6) {
                    Text("Turn:")
                        .foregroundColor(.gray)
                    Circle()
                        .fill(discColor(game.currentTurn))
                        .frame(width: 14, height: 14)
                    Text(game.currentTurn.name)
                        .foregroundColor(discColor(game.currentTurn))
                        .fontWeight(.bold)
                }
            } else {
                Text("")
            }
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
    }

    private func cellView(row: Int, col: Int) -> some View {
        let isWinCell = game.winningCells?.contains { $0.0 == row && $0.1 == col } ?? false

        return Button(action: { game.drop(col: col) }) {
            ZStack {
                // Background slot
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.06, green: 0.08, blue: 0.3, opacity: 1.0))
                    .frame(width: cellSize, height: cellSize)

                // Disc or empty hole
                Circle()
                    .fill(discFill(row: row, col: col, isWinCell: isWinCell))
                    .frame(width: cellSize * 0.8, height: cellSize * 0.8)
                    .shadow(color: game.grid[row][col] != nil ? .black.opacity(0.3) : .clear, radius: 3, y: 2)

                // Win highlight ring
                if isWinCell {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: cellSize * 0.85, height: cellSize * 0.85)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(game.result != nil)
    }

    private func discFill(row: Int, col: Int, isWinCell: Bool) -> Color {
        guard let disc = game.grid[row][col] else {
            return Color(red: 0.03, green: 0.04, blue: 0.15, opacity: 1.0)
        }
        return discColor(disc)
    }

    private func discColor(_ disc: Disc) -> Color {
        disc == .red ? .red : .yellow
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            switch game.result {
            case .win(let disc):
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Circle()
                        .fill(discColor(disc))
                        .frame(width: 20, height: 20)
                    Text("\(disc.name) Wins!")
                        .fontWeight(.bold)
                }
                .font(.system(size: 28, design: .monospaced))
                .foregroundColor(.white)
            case .draw:
                Text("Draw!")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
            case .none:
                EmptyView()
            }

            Button("Play Again") { game.reset() }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
