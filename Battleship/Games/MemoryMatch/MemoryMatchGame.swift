import Foundation

struct MemoryCard: Identifiable {
    let id: Int
    let value: Int
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

class MemoryMatchGame: ObservableObject {
    static let rows = 4
    static let cols = 4
    static var pairCount: Int { rows * cols / 2 }

    @Published var cards: [MemoryCard] = []
    @Published var moves: Int = 0
    @Published var matches: Int = 0
    @Published var isLocked: Bool = false

    private var firstFlipped: Int? = nil

    init() { reset() }

    var isComplete: Bool { matches == Self.pairCount }

    func reset() {
        moves = 0
        matches = 0
        firstFlipped = nil
        isLocked = false
        var values: [Int] = []
        for v in 0..<Self.pairCount {
            values.append(v)
            values.append(v)
        }
        values.shuffle()
        cards = values.enumerated().map { MemoryCard(id: $0.offset, value: $0.element) }
    }

    func tap(_ index: Int) {
        guard !isLocked, !isComplete else { return }
        guard index >= 0, index < cards.count else { return }
        guard !cards[index].isMatched, !cards[index].isFaceUp else { return }

        cards[index].isFaceUp = true

        guard let first = firstFlipped else {
            firstFlipped = index
            return
        }

        moves += 1
        if cards[first].value == cards[index].value {
            cards[first].isMatched = true
            cards[index].isMatched = true
            matches += 1
            firstFlipped = nil
        } else {
            let a = first
            let b = index
            firstFlipped = nil
            isLocked = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self else { return }
                self.cards[a].isFaceUp = false
                self.cards[b].isFaceUp = false
                self.isLocked = false
            }
        }
    }
}
