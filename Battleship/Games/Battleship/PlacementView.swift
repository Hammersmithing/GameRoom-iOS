import SwiftUI

struct PlacementView: View {
    @ObservedObject var game: Game
    let player: Int

    @State private var hoverPos: GridPosition? = nil

    private var board: Board { game.boardFor(player: player) }

    private var previewShip: Ship? {
        guard let pos = hoverPos, let shipType = game.currentShipType else { return nil }
        return Ship(type: shipType, origin: pos, orientation: game.placementOrientation)
    }

    var body: some View {
        VStack(spacing: 16) {
            if let shipType = game.currentShipType {
                HStack(spacing: 12) {
                    Text("Place: \(shipType.rawValue) (\(shipType.length) cells)")
                        .font(.headline)

                    Button(action: { game.toggleOrientation() }) {
                        Label(
                            game.placementOrientation == .horizontal ? "Horizontal" : "Vertical",
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                    }
                    .keyboardShortcut("r", modifiers: [])

                    Text("Press R to rotate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            BoardView(
                board: board,
                isOwner: true,
                interactive: true,
                onCellTap: { pos in
                    game.placeShip(at: pos, player: player)
                },
                hoverShip: previewShip
            )
            .onContinuousHover { hoverPhase in
                switch hoverPhase {
                case .active(let location):
                    hoverPos = positionFromLocation(location)
                case .ended:
                    hoverPos = nil
                @unknown default:
                    break
                }
            }

            // Ship list showing placed ships
            HStack(spacing: 16) {
                ForEach(ShipType.allCases) { shipType in
                    let placed = board.ships.contains { $0.type == shipType }
                    HStack(spacing: 4) {
                        ForEach(0..<shipType.length, id: \.self) { _ in
                            Rectangle()
                                .fill(placed ? Color.gray : Color.gray.opacity(0.3))
                                .frame(width: 14, height: 14)
                                .cornerRadius(2)
                        }
                    }
                    .overlay(
                        Text(shipType.rawValue)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .offset(y: 14)
                    )
                }
            }
            .padding(.top, 8)
        }
    }

    private func positionFromLocation(_ location: CGPoint) -> GridPosition? {
        // Approximate — the board has padding and labels
        let cellSize: CGFloat = 36
        let spacing: CGFloat = 2
        let labelOffset: CGFloat = cellSize + 8 // row label + padding
        let headerOffset: CGFloat = 20 + 8 // column header + padding

        let col = Int((location.x - labelOffset) / (cellSize + spacing))
        let row = Int((location.y - headerOffset) / (cellSize + spacing))

        guard row >= 0, row < Board.size, col >= 0, col < Board.size else { return nil }
        return GridPosition(row: row, col: col)
    }
}
