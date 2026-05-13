import SwiftUI

struct BattleshipView: View {
    @StateObject private var game = Game()
    var onExit: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "BATTLESHIP",
                statusContent: AnyView(
                    Text(game.message)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.cyan)
                ),
                onNewGame: { game.newGame() },
                onExit: onExit
            )

            // Main content
            Group {
                switch game.phase {
                case .placingShips(let player):
                    PlacementView(game: game, player: player)
                        .padding(20)

                case .transition:
                    TransitionView(game: game)

                case .firing(let player):
                    FiringView(game: game, player: player)
                        .padding(20)

                case .shotResult(let player, _, let wasHit, let sunkShip):
                    ShotResultView(game: game, player: player, wasHit: wasHit, sunkShip: sunkShip)

                case .gameOver(let winner):
                    GameOverView(game: game, winner: winner)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2, opacity: 1.0),
                    Color(red: 0.02, green: 0.05, blue: 0.15, opacity: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
