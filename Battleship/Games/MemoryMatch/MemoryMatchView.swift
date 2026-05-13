import SwiftUI

struct MemoryMatchView: View {
    @StateObject private var game = MemoryMatchGame()
    var onExit: () -> Void = {}

    private let cardWidth: CGFloat = 100
    private let cardHeight: CGFloat = 130
    private let spacing: CGFloat = 10

    private static let faces: [(symbol: String, color: Color)] = [
        ("heart.fill",       .red),
        ("star.fill",        .yellow),
        ("sparkles",         .pink),
        ("leaf.fill",        .green),
        ("drop.fill",        .cyan),
        ("bolt.fill",        .orange),
        ("moon.fill",        .indigo),
        ("sun.max.fill",     .mint),
    ]

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "MEMORY MATCH",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset() },
                onExit: onExit
            )

            VStack(spacing: 0) {
                Spacer()
                board
                Spacer()
                if game.isComplete {
                    resultBanner.padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            LinearGradient(
                colors: [Color(white: 0.10), Color(white: 0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var statusContent: some View {
        HStack(spacing: 8) {
            Text("Moves:").foregroundColor(.gray)
            Text("\(game.moves)")
                .foregroundColor(.white)
                .fontWeight(.bold)
            Text("·").foregroundColor(.gray)
            Text("Matches:").foregroundColor(.gray)
            Text("\(game.matches) / \(MemoryMatchGame.pairCount)")
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
    }

    private var board: some View {
        VStack(spacing: spacing) {
            ForEach(0..<MemoryMatchGame.rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<MemoryMatchGame.cols, id: \.self) { col in
                        let index = row * MemoryMatchGame.cols + col
                        cardView(index: index)
                    }
                }
            }
        }
        .padding(16)
    }

    private func cardView(index: Int) -> some View {
        let card = game.cards[index]
        let face = Self.faces[card.value % Self.faces.count]

        return Button(action: { game.tap(index) }) {
            ZStack {
                if card.isFaceUp || card.isMatched {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.96))
                        .frame(width: cardWidth, height: cardHeight)
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)

                    Image(systemName: face.symbol)
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(face.color)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.25, green: 0.20, blue: 0.55),
                                    Color(red: 0.10, green: 0.08, blue: 0.30)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: cardWidth, height: cardHeight)
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)

                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.18), lineWidth: 2)
                        .frame(width: cardWidth - 12, height: cardHeight - 12)

                    Image(systemName: "questionmark")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            .opacity(card.isMatched ? 0.55 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: card.isFaceUp)
            .animation(.easeInOut(duration: 0.2), value: card.isMatched)
        }
        .buttonStyle(.plain)
        .disabled(game.isLocked || card.isMatched || card.isFaceUp || game.isComplete)
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill").foregroundColor(.yellow)
                Text("All matched!").fontWeight(.bold)
            }
            .font(.system(size: 28, design: .monospaced))
            .foregroundColor(.white)

            Text("\(game.moves) moves")
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)

            Button("Play Again") { game.reset() }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
