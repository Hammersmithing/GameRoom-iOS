import SwiftUI

struct TicTacToeView: View {
    @StateObject private var game = TicTacToeGame()
    var onExit: () -> Void = {}

    private let cellSize: CGFloat = 120
    private let spacing: CGFloat = 6

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "TIC TAC TOE",
                statusContent: AnyView(statusText),
                onNewGame: { game.reset() },
                onExit: onExit
            )

            ScaledFit(width: 3 * cellSize + 2 * spacing + 40, height: 3 * cellSize + 2 * spacing + 40) {
                boardView
            }
            .frame(maxHeight: .infinity)
            if game.result != nil {
                resultBanner.padding(.bottom, 30)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.06, blue: 0.12, opacity: 1.0),
                    Color(red: 0.04, green: 0.03, blue: 0.08, opacity: 1.0)
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
                    Text(game.currentTurn.symbol)
                        .foregroundColor(game.currentTurn == .x ? .cyan : .pink)
                        .fontWeight(.bold)
                }
            } else {
                Text("")
            }
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
    }

    private var boardView: some View {
        VStack(spacing: spacing) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<3, id: \.self) { col in
                        let index = row * 3 + col
                        cellView(index: index)
                    }
                }
            }
        }
        .padding(20)
    }

    private func cellView(index: Int) -> some View {
        let isWinCell = game.winningLine?.contains(index) ?? false

        return Button(action: { game.play(at: index) }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(cellBackground(index: index, isWinCell: isWinCell))
                    .frame(width: cellSize, height: cellSize)

                if let mark = game.board[index] {
                    Text(mark.symbol)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(markColor(mark, isWinCell: isWinCell))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(game.board[index] != nil || game.result != nil)
    }

    private func cellBackground(index: Int, isWinCell: Bool) -> Color {
        if isWinCell {
            return Color.white.opacity(0.15)
        }
        return Color.white.opacity(0.06)
    }

    private func markColor(_ mark: Mark, isWinCell: Bool) -> Color {
        let base: Color = mark == .x ? .cyan : .pink
        return isWinCell ? base : base.opacity(0.85)
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            switch game.result {
            case .win(let mark):
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("\(mark.symbol) Wins!")
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
