import SwiftUI

struct TransitionView: View {
    @ObservedObject var game: Game

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(game.message)
                .font(.title)
                .fontWeight(.semibold)

            Text("Make sure the other player isn't looking!")
                .font(.body)
                .foregroundColor(.secondary)

            Button("Ready") {
                game.continueFromTransition()
            }
            .keyboardShortcut(.return, modifiers: [])
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ShotResultView: View {
    @ObservedObject var game: Game
    let player: Int
    let wasHit: Bool
    let sunkShip: ShipType?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: wasHit ? "flame.fill" : "drop.fill")
                .font(.system(size: 64))
                .foregroundColor(wasHit ? .red : .blue)

            Text(game.message)
                .font(.title)
                .fontWeight(.bold)

            if let sunk = sunkShip {
                Text("You sank their \(sunk.rawValue)!")
                    .font(.title2)
                    .foregroundColor(.orange)
            }

            Button("End Turn") {
                game.endTurn(player: player)
            }
            .keyboardShortcut(.return, modifiers: [])
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct GameOverView: View {
    @ObservedObject var game: Game
    let winner: Int

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundColor(.yellow)

            Text("Player \(winner) Wins!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Button("New Game") {
                game.newGame()
            }
            .keyboardShortcut(.return, modifiers: [])
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
