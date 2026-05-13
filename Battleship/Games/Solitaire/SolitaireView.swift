import SwiftUI

struct SolitaireView: View {
    @StateObject private var game = SolitaireGame()
    var onExit: () -> Void = {}

    private let cardWidth: CGFloat = 64
    private let cardHeight: CGFloat = 90
    private let tableauOverlap: CGFloat = 26
    private let tableauOverlapHidden: CGFloat = 14

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "SOLITAIRE",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset() },
                onExit: onExit
            )

            ScaledFit(width: 7 * cardWidth + 6 * 10 + 24,
                      height: cardHeight + 18 + cardHeight + 20 * tableauOverlap) {
                VStack(spacing: 18) {
                    topRow
                    tableauRow
                }
            }
            .frame(maxHeight: .infinity)
            if game.hasWon {
                resultBanner.padding(.bottom, 24)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.22, blue: 0.10),
                         Color(red: 0.02, green: 0.10, blue: 0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var statusContent: some View {
        HStack(spacing: 8) {
            Text("Moves:").foregroundColor(.gray)
            Text("\(game.moves)")
                .foregroundColor(.white).fontWeight(.bold)
            Text("·").foregroundColor(.gray)
            Text("Foundations:").foregroundColor(.gray)
            Text("\(foundationCount)/52")
                .foregroundColor(.white).fontWeight(.bold)
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
    }

    private var foundationCount: Int {
        game.foundations.reduce(0) { $0 + $1.count }
    }

    private var topRow: some View {
        HStack(spacing: 10) {
            stockView
            wasteView
            Spacer().frame(width: 24)
            ForEach(0..<4, id: \.self) { i in
                foundationView(index: i)
            }
            Spacer(minLength: 0)
        }
    }

    private var stockView: some View {
        Button(action: { game.tapStock() }) {
            ZStack {
                if game.stock.isEmpty {
                    emptySlot(label: game.waste.isEmpty ? "" : "\u{21BB}")
                } else {
                    cardBack
                }
            }
            .frame(width: cardWidth, height: cardHeight)
        }
        .buttonStyle(.plain)
    }

    private var wasteView: some View {
        Button(action: { game.tapWaste() }) {
            ZStack {
                if let card = game.waste.last {
                    cardFront(card, selected: game.selected == .waste)
                } else {
                    emptySlot()
                }
            }
            .frame(width: cardWidth, height: cardHeight)
        }
        .buttonStyle(.plain)
    }

    private func foundationView(index: Int) -> some View {
        Button(action: { game.tapFoundation(index) }) {
            ZStack {
                if let card = game.foundations[index].last {
                    cardFront(card, selected: game.selected == .foundation(index))
                } else {
                    emptySlot(label: foundationGlyph(index: index), labelColor: .white.opacity(0.18))
                }
            }
            .frame(width: cardWidth, height: cardHeight)
        }
        .buttonStyle(.plain)
    }

    private func foundationGlyph(index: Int) -> String {
        ["\u{2665}", "\u{2666}", "\u{2663}", "\u{2660}"][index]
    }

    private var tableauRow: some View {
        HStack(alignment: .top, spacing: 10) {
            ForEach(0..<7, id: \.self) { col in
                tableauColumn(col: col)
            }
        }
    }

    private func tableauColumn(col: Int) -> some View {
        let pile = game.tableau[col]
        return ZStack(alignment: .top) {
            if pile.isEmpty {
                Button(action: { game.tapEmptyTableau(col: col) }) {
                    emptySlot()
                        .frame(width: cardWidth, height: cardHeight)
                }
                .buttonStyle(.plain)
            } else {
                ZStack(alignment: .top) {
                    ForEach(Array(pile.enumerated()), id: \.element.id) { item in
                        let idx = item.offset
                        let card = item.element
                        let yOffset = stackedYOffset(in: pile, upTo: idx)
                        Button(action: { game.tapTableauCard(col: col, index: idx) }) {
                            if card.faceUp {
                                cardFront(card, selected: isInSelection(col: col, index: idx))
                            } else {
                                cardBack
                            }
                        }
                        .buttonStyle(.plain)
                        .offset(y: yOffset)
                    }
                }
                .frame(width: cardWidth, alignment: .top)
            }
        }
        .frame(width: cardWidth, height: tableauTotalHeight(in: pile), alignment: .top)
    }

    private func stackedYOffset(in pile: [Card], upTo index: Int) -> CGFloat {
        var y: CGFloat = 0
        for i in 0..<index {
            y += pile[i].faceUp ? tableauOverlap : tableauOverlapHidden
        }
        return y
    }

    private func tableauTotalHeight(in pile: [Card]) -> CGFloat {
        guard !pile.isEmpty else { return cardHeight }
        var y: CGFloat = 0
        for i in 0..<(pile.count - 1) {
            y += pile[i].faceUp ? tableauOverlap : tableauOverlapHidden
        }
        return y + cardHeight
    }

    private func isInSelection(col: Int, index: Int) -> Bool {
        if case .tableau(let c, let from) = game.selected {
            return c == col && index >= from
        }
        return false
    }

    private func cardFront(_ card: Card, selected: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: cardWidth, height: cardHeight)
                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(card.rankLabel)
                            .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        Text(card.suit.symbol)
                            .font(.system(size: 14, weight: .heavy))
                    }
                    .foregroundColor(card.isRed ? Color(red: 0.85, green: 0.15, blue: 0.20) : .black)
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.top, 4)
                Spacer()
                Text(card.suit.symbol)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(card.isRed ? Color(red: 0.85, green: 0.15, blue: 0.20) : .black)
                Spacer()
            }
            .frame(width: cardWidth, height: cardHeight)

            if selected {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.yellow, lineWidth: 3)
                    .frame(width: cardWidth, height: cardHeight)
            }
        }
    }

    private var cardBack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.20, green: 0.30, blue: 0.65),
                            Color(red: 0.10, green: 0.15, blue: 0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: cardWidth, height: cardHeight)
                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                .frame(width: cardWidth - 8, height: cardHeight - 8)
        }
    }

    private func emptySlot(label: String = "", labelColor: Color = .white.opacity(0.25)) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.25), lineWidth: 2)
                .frame(width: cardWidth, height: cardHeight)
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(labelColor)
            }
        }
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill").foregroundColor(.yellow)
                Text("You won!").fontWeight(.bold)
            }
            .font(.system(size: 26, design: .monospaced))
            .foregroundColor(.white)
            Text("\(game.moves) moves")
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
            Button("New Deal") { game.reset() }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
