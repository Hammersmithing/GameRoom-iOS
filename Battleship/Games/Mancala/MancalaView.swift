import SwiftUI

struct MancalaView: View {
    @StateObject private var game = MancalaGame()
    var onExit: () -> Void = {}

    private let pitSize: CGFloat = 80
    private let storeWidth: CGFloat = 80
    private let storeHeight: CGFloat = 184

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "MANCALA",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset() },
                onExit: onExit
            )

            VStack(spacing: 16) {
                Spacer()
                Text("P2 — top")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundColor(playerColor(2).opacity(game.currentTurn == 2 ? 1 : 0.5))
                board
                Text("P1 — bottom")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundColor(playerColor(1).opacity(game.currentTurn == 1 ? 1 : 0.5))
                if game.result != nil {
                    resultBanner.padding(.top, 8)
                }
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.20, green: 0.12, blue: 0.06),
                         Color(red: 0.10, green: 0.06, blue: 0.03)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var statusContent: some View {
        Group {
            if game.result == nil {
                HStack(spacing: 8) {
                    Text("Turn:").foregroundColor(.gray)
                    Text("P\(game.currentTurn)")
                        .foregroundColor(playerColor(game.currentTurn))
                        .fontWeight(.bold)
                    Text("·").foregroundColor(.gray)
                    Text("P1 \(game.p1Score)").foregroundColor(playerColor(1))
                    Text("P2 \(game.p2Score)").foregroundColor(playerColor(2))
                }
            } else {
                EmptyView()
            }
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
    }

    private var board: some View {
        HStack(spacing: 16) {
            store(player: 2, count: game.pits[13])

            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    ForEach((7...12).reversed(), id: \.self) { i in
                        pitView(index: i)
                    }
                }
                HStack(spacing: 14) {
                    ForEach(0...5, id: \.self) { i in
                        pitView(index: i)
                    }
                }
            }

            store(player: 1, count: game.pits[6])
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.32, green: 0.20, blue: 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.55, green: 0.35, blue: 0.18), lineWidth: 3)
        )
    }

    private func pitView(index: Int) -> some View {
        let count = game.pits[index]
        let selectable = game.canSelect(pit: index)
        let isHighlight = game.lastCaptureFrom == index

        return Button(action: { game.sow(from: index) }) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.18, green: 0.10, blue: 0.05))
                    .frame(width: pitSize, height: pitSize)
                if isHighlight {
                    Circle()
                        .stroke(Color.yellow, lineWidth: 3)
                        .frame(width: pitSize, height: pitSize)
                }
                Text("\(count)")
                    .font(.system(size: 24, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
            }
            .overlay(
                Circle()
                    .stroke(selectable ? Color.yellow : Color.clear, lineWidth: 3)
                    .frame(width: pitSize + 6, height: pitSize + 6)
            )
        }
        .buttonStyle(.plain)
        .disabled(!selectable)
    }

    private func store(player: Int, count: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.18, green: 0.10, blue: 0.05))
                .frame(width: storeWidth, height: storeHeight)
            VStack(spacing: 4) {
                Text("P\(player)")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(playerColor(player))
                Text("\(count)")
                    .font(.system(size: 36, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }

    private func playerColor(_ player: Int) -> Color {
        player == 1
            ? Color(red: 0.45, green: 0.85, blue: 0.55)
            : Color(red: 0.55, green: 0.75, blue: 1.0)
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            switch game.result {
            case .win(let p):
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").foregroundColor(.yellow)
                    Text("P\(p) wins!")
                        .foregroundColor(playerColor(p))
                        .fontWeight(.bold)
                }
                .font(.system(size: 24, design: .monospaced))
                Text("\(game.p1Score) – \(game.p2Score)")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
            case .draw:
                Text("Draw — \(game.p1Score) all")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
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
