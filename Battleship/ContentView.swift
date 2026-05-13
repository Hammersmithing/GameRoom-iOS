import SwiftUI

struct ContentView: View {
    @State private var selectedGame: GameDefinition? = nil

    var body: some View {
        Group {
            if let game = selectedGame {
                game.view { selectedGame = nil }
            } else {
                MainMenuView(onSelectGame: { game in
                    selectedGame = game
                })
            }
        }
    }
}

struct MainMenuView: View {
    var onSelectGame: (GameDefinition) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("GAME ROOM")
                    .font(.system(size: 26, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                Text("Pick a game")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(allGames) { game in
                        GameCard(game: game) {
                            onSelectGame(game)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12, opacity: 1.0),
                    Color(red: 0.04, green: 0.04, blue: 0.08, opacity: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct GameCard: View {
    let game: GameDefinition
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: game.icon)
                    .font(.system(size: 30))
                    .foregroundColor(game.color)
                    .frame(height: 36)

                Text(game.name)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(game.playerCount)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(game.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(game.color.opacity(0.15))
                    .cornerRadius(4)
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(game.color.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
