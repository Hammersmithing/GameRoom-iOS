import SwiftUI

struct FiringView: View {
    @ObservedObject var game: Game
    let player: Int

    private var targetBoard: Board { game.opponentBoard(for: player) }
    private var ownBoard: Board { game.boardFor(player: player) }

    var body: some View {
        HStack(spacing: 40) {
            // Own board (small reference)
            VStack(spacing: 8) {
                Text("Your Fleet")
                    .font(.headline)
                    .foregroundColor(.secondary)
                BoardView(
                    board: ownBoard,
                    isOwner: true,
                    interactive: false
                )
                .scaleEffect(0.7)
                .frame(
                    width: CGFloat(Board.size) * 38 * 0.7 + 44 * 0.7,
                    height: CGFloat(Board.size) * 38 * 0.7 + 28 * 0.7
                )
            }

            // Target board
            VStack(spacing: 8) {
                Text("Enemy Waters — Fire!")
                    .font(.headline)
                BoardView(
                    board: targetBoard,
                    isOwner: false,
                    interactive: true,
                    onCellTap: { pos in
                        game.fireShot(at: pos, player: player)
                    }
                )
            }
        }
    }
}
