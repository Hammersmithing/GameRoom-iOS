import Foundation

enum CardSuit: Int, CaseIterable, Equatable {
    case hearts, diamonds, clubs, spades
    var isRed: Bool { self == .hearts || self == .diamonds }
    var symbol: String {
        switch self {
        case .hearts:   return "\u{2665}"
        case .diamonds: return "\u{2666}"
        case .clubs:    return "\u{2663}"
        case .spades:   return "\u{2660}"
        }
    }
}

struct Card: Identifiable, Equatable {
    let id: Int
    let rank: Int      // 1-13 (Ace..King)
    let suit: CardSuit
    var faceUp: Bool = false

    var rankLabel: String {
        switch rank {
        case 1:  return "A"
        case 11: return "J"
        case 12: return "Q"
        case 13: return "K"
        default: return "\(rank)"
        }
    }
    var isRed: Bool { suit.isRed }
}

enum SolitaireSource: Equatable {
    case waste
    case foundation(Int)
    case tableau(col: Int, fromIndex: Int)
}

class SolitaireGame: ObservableObject {
    @Published var stock: [Card] = []
    @Published var waste: [Card] = []
    @Published var foundations: [[Card]] = Array(repeating: [], count: 4)
    @Published var tableau: [[Card]] = Array(repeating: [], count: 7)
    @Published var selected: SolitaireSource? = nil
    @Published var hasWon: Bool = false
    @Published var moves: Int = 0

    init() { reset() }

    func reset() {
        var deck: [Card] = []
        var id = 0
        for suit in CardSuit.allCases {
            for rank in 1...13 {
                deck.append(Card(id: id, rank: rank, suit: suit))
                id += 1
            }
        }
        deck.shuffle()

        tableau = Array(repeating: [], count: 7)
        for col in 0..<7 {
            for r in 0...col {
                var c = deck.removeFirst()
                c.faceUp = (r == col)
                tableau[col].append(c)
            }
        }
        stock = deck
        waste = []
        foundations = Array(repeating: [], count: 4)
        selected = nil
        hasWon = false
        moves = 0
    }

    func tapStock() {
        guard !hasWon else { return }
        selected = nil
        if stock.isEmpty {
            stock = waste.reversed().map { var c = $0; c.faceUp = false; return c }
            waste = []
        } else {
            var c = stock.removeLast()
            c.faceUp = true
            waste.append(c)
        }
        moves += 1
    }

    func tapWaste() {
        guard !hasWon, !waste.isEmpty else { return }
        if selected == .waste {
            selected = nil
            return
        }
        if let sel = selected {
            attemptMoveTo(.waste, from: sel)
            return
        }
        selected = .waste
    }

    func tapFoundation(_ index: Int) {
        guard !hasWon else { return }
        if let sel = selected {
            attemptMoveTo(.foundation(index), from: sel)
            return
        }
        if !foundations[index].isEmpty {
            selected = .foundation(index)
        }
    }

    func tapTableauCard(col: Int, index: Int) {
        guard !hasWon else { return }
        guard col >= 0, col < 7, index >= 0, index < tableau[col].count else { return }
        let card = tableau[col][index]
        guard card.faceUp else { return }

        if let sel = selected, sel == .tableau(col: col, fromIndex: index) {
            selected = nil
            return
        }
        if let sel = selected {
            if attemptMoveToTableau(col: col, from: sel) { return }
        }
        selected = .tableau(col: col, fromIndex: index)
    }

    func tapEmptyTableau(col: Int) {
        guard !hasWon else { return }
        guard let sel = selected else { return }
        attemptMoveToTableau(col: col, from: sel)
    }

    @discardableResult
    private func attemptMoveTo(_ destination: SolitaireSource, from source: SolitaireSource) -> Bool {
        switch destination {
        case .foundation(let idx):
            return attemptMoveToFoundation(index: idx, from: source)
        case .waste:
            // Cannot move to waste; treat as deselect.
            selected = nil
            return false
        case .tableau:
            return false
        }
    }

    @discardableResult
    private func attemptMoveToFoundation(index: Int, from source: SolitaireSource) -> Bool {
        let cards = sourceCards(source)
        guard cards.count == 1 else {
            selected = nil
            return false
        }
        let card = cards[0]
        guard canPlaceOnFoundation(card: card, foundationIndex: index) else {
            selected = nil
            return false
        }
        removeFromSource(source)
        foundations[index].append(card)
        selected = nil
        moves += 1
        flipExposedTableauCards()
        checkWin()
        return true
    }

    @discardableResult
    private func attemptMoveToTableau(col: Int, from source: SolitaireSource) -> Bool {
        let cards = sourceCards(source)
        guard !cards.isEmpty else { selected = nil; return false }
        guard canPlaceOnTableau(topCard: cards[0], col: col) else {
            selected = nil
            return false
        }
        removeFromSource(source)
        tableau[col].append(contentsOf: cards)
        selected = nil
        moves += 1
        flipExposedTableauCards()
        checkWin()
        return true
    }

    private func sourceCards(_ source: SolitaireSource) -> [Card] {
        switch source {
        case .waste:
            return waste.last.map { [$0] } ?? []
        case .foundation(let i):
            return foundations[i].last.map { [$0] } ?? []
        case .tableau(let col, let from):
            guard col >= 0, col < 7, from >= 0, from < tableau[col].count else { return [] }
            return Array(tableau[col][from...])
        }
    }

    private func removeFromSource(_ source: SolitaireSource) {
        switch source {
        case .waste:
            if !waste.isEmpty { waste.removeLast() }
        case .foundation(let i):
            if !foundations[i].isEmpty { foundations[i].removeLast() }
        case .tableau(let col, let from):
            if from < tableau[col].count {
                tableau[col].removeSubrange(from..<tableau[col].count)
            }
        }
    }

    private func canPlaceOnFoundation(card: Card, foundationIndex i: Int) -> Bool {
        let pile = foundations[i]
        if let top = pile.last {
            return card.suit == top.suit && card.rank == top.rank + 1
        }
        return card.rank == 1
    }

    private func canPlaceOnTableau(topCard: Card, col: Int) -> Bool {
        let pile = tableau[col]
        if let top = pile.last {
            return top.faceUp
                && top.isRed != topCard.isRed
                && topCard.rank == top.rank - 1
        }
        return topCard.rank == 13
    }

    private func flipExposedTableauCards() {
        for col in 0..<7 {
            if let last = tableau[col].last, !last.faceUp {
                let lastIdx = tableau[col].count - 1
                tableau[col][lastIdx].faceUp = true
            }
        }
    }

    private func checkWin() {
        let total = foundations.reduce(0) { $0 + $1.count }
        hasWon = total == 52
    }
}
