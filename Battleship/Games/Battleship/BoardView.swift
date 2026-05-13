import SwiftUI

struct BoardView: View {
    let board: Board
    let isOwner: Bool // true = show ships, false = opponent view
    let interactive: Bool
    var onCellTap: ((GridPosition) -> Void)? = nil
    var hoverShip: Ship? = nil

    private let cellSize: CGFloat = 36
    private let spacing: CGFloat = 2
    private let colLabels = ["A","B","C","D","E","F","G","H","I","J"]

    var body: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack(spacing: spacing) {
                Text("")
                    .frame(width: cellSize, height: 20)
                ForEach(0..<Board.size, id: \.self) { col in
                    Text(colLabels[col])
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .frame(width: cellSize, height: 20)
                        .foregroundColor(.gray)
                }
            }

            ForEach(0..<Board.size, id: \.self) { row in
                HStack(spacing: spacing) {
                    // Row number
                    Text("\(row + 1)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .frame(width: cellSize, height: cellSize)
                        .foregroundColor(.gray)

                    ForEach(0..<Board.size, id: \.self) { col in
                        let pos = GridPosition(row: row, col: col)
                        CellView(
                            state: isOwner ? board.cellState(at: pos) : board.opponentCellState(at: pos),
                            isHoverPreview: isHoverCell(pos),
                            isHoverInvalid: isHoverInvalid(pos),
                            size: cellSize
                        )
                        .onTapGesture {
                            if interactive {
                                onCellTap?(pos)
                            }
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }

    private func isHoverCell(_ pos: GridPosition) -> Bool {
        guard let ship = hoverShip else { return false }
        return ship.positions.contains(pos)
    }

    private func isHoverInvalid(_ pos: GridPosition) -> Bool {
        guard let ship = hoverShip, ship.positions.contains(pos) else { return false }
        return !board.canPlace(ship: ship)
    }
}

struct CellView: View {
    let state: CellState
    let isHoverPreview: Bool
    let isHoverInvalid: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
                .border(Color.gray.opacity(0.3), width: 0.5)

            if state == .hit {
                Image(systemName: "xmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(.white)
            } else if state == .miss {
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: size * 0.3, height: size * 0.3)
            }
        }
    }

    private var backgroundColor: Color {
        if isHoverPreview {
            return isHoverInvalid ? .red.opacity(0.4) : .green.opacity(0.4)
        }
        switch state {
        case .empty: return Color(red: 0.1, green: 0.2, blue: 0.4, opacity: 1.0)
        case .ship: return Color(red: 0.3, green: 0.3, blue: 0.35, opacity: 1.0)
        case .hit: return .red.opacity(0.8)
        case .miss: return Color(red: 0.15, green: 0.25, blue: 0.45, opacity: 1.0)
        }
    }
}
