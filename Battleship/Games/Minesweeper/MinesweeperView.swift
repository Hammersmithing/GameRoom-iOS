import SwiftUI

struct MinesweeperView: View {
    @StateObject private var game = MinesweeperGame()
    var onExit: () -> Void = {}

    private let cellSize: CGFloat = 30

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "MINESWEEPER",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset() },
                onExit: onExit
            )

            VStack(spacing: 0) {
                Spacer()
                board
                Spacer()
                if game.result != nil {
                    resultBanner.padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            LinearGradient(
                colors: [Color(white: 0.1), Color(white: 0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var statusContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "flag.fill").foregroundColor(.red)
            Text("\(game.minesRemaining)")
                .foregroundColor(.white)
                .fontWeight(.bold)
            Text("·").foregroundColor(.gray)
            Text("long-press to flag")
                .foregroundColor(.gray)
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
    }

    private var board: some View {
        VStack(spacing: 1) {
            ForEach(0..<MinesweeperGame.rows, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<MinesweeperGame.cols, id: \.self) { col in
                        cell(row: row, col: col)
                    }
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(white: 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(white: 0.3), lineWidth: 2)
        )
    }

    private func cell(row: Int, col: Int) -> some View {
        let pos = Position(row: row, col: col)
        let cell = game.grid[row][col]
        let isExploded = game.revealedMine == pos

        return ZStack {
            Rectangle()
                .fill(cellBackground(cell: cell, exploded: isExploded))
                .frame(width: cellSize, height: cellSize)

            cellContent(cell: cell, exploded: isExploded)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard game.result == nil || cell.state == .revealed else { return }
            game.reveal(pos)
        }
        .onLongPressGesture(minimumDuration: 0.25) {
            guard game.result == nil else { return }
            game.toggleFlag(pos)
        }
    }

    private func cellBackground(cell: MineCell, exploded: Bool) -> Color {
        if exploded { return Color.red.opacity(0.6) }
        switch cell.state {
        case .hidden, .flagged:
            return Color(white: 0.32)
        case .revealed:
            return Color(white: 0.18)
        }
    }

    @ViewBuilder
    private func cellContent(cell: MineCell, exploded: Bool) -> some View {
        switch cell.state {
        case .hidden:
            EmptyView()
        case .flagged:
            Image(systemName: "flag.fill")
                .foregroundColor(.red)
                .font(.system(size: cellSize * 0.5, weight: .bold))
        case .revealed:
            if cell.hasMine {
                Image(systemName: "burst.fill")
                    .foregroundColor(exploded ? .white : .black)
                    .font(.system(size: cellSize * 0.55, weight: .bold))
            } else if cell.adjacent > 0 {
                Text("\(cell.adjacent)")
                    .font(.system(size: cellSize * 0.55, weight: .heavy, design: .monospaced))
                    .foregroundColor(numberColor(cell.adjacent))
            }
        }
    }

    private func numberColor(_ n: Int) -> Color {
        switch n {
        case 1: return Color(red: 0.35, green: 0.65, blue: 1.0)
        case 2: return Color(red: 0.45, green: 0.85, blue: 0.45)
        case 3: return Color(red: 1.0, green: 0.45, blue: 0.45)
        case 4: return Color(red: 0.6, green: 0.6, blue: 1.0)
        case 5: return Color(red: 0.95, green: 0.55, blue: 0.35)
        case 6: return Color(red: 0.5, green: 0.85, blue: 0.85)
        case 7: return Color(white: 0.85)
        case 8: return Color(white: 0.65)
        default: return .white
        }
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            switch game.result {
            case .won:
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").foregroundColor(.yellow)
                    Text("Cleared!").fontWeight(.bold)
                }
                .font(.system(size: 28, design: .monospaced))
                .foregroundColor(.white)
            case .lost:
                HStack(spacing: 8) {
                    Image(systemName: "burst.fill").foregroundColor(.red)
                    Text("Boom!").fontWeight(.bold)
                }
                .font(.system(size: 28, design: .monospaced))
                .foregroundColor(.white)
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
