import Foundation

enum YahtzeeCategory: String, CaseIterable, Identifiable {
    case ones, twos, threes, fours, fives, sixes
    case threeOfKind, fourOfKind, fullHouse
    case smallStraight, largeStraight, yahtzee, chance

    var id: String { rawValue }
    var label: String {
        switch self {
        case .ones:          return "Aces (1s)"
        case .twos:          return "Twos"
        case .threes:        return "Threes"
        case .fours:         return "Fours"
        case .fives:         return "Fives"
        case .sixes:         return "Sixes"
        case .threeOfKind:   return "3 of a Kind"
        case .fourOfKind:    return "4 of a Kind"
        case .fullHouse:     return "Full House"
        case .smallStraight: return "Small Straight"
        case .largeStraight: return "Large Straight"
        case .yahtzee:       return "Yahtzee"
        case .chance:        return "Chance"
        }
    }
    static let upper: [YahtzeeCategory] = [.ones, .twos, .threes, .fours, .fives, .sixes]
    static let lower: [YahtzeeCategory] = [.threeOfKind, .fourOfKind, .fullHouse, .smallStraight, .largeStraight, .yahtzee, .chance]
}

class YahtzeeGame: ObservableObject {
    static let diceCount = 5
    static let maxRolls = 3
    static let totalTurns = YahtzeeCategory.allCases.count

    @Published var dice: [Int] = Array(repeating: 1, count: diceCount)
    @Published var held: [Bool] = Array(repeating: false, count: diceCount)
    @Published var rollsLeft: Int = maxRolls
    @Published var scores: [YahtzeeCategory: Int] = [:]
    @Published var turn: Int = 1
    @Published var hasRolled: Bool = false

    init() { reset() }

    func reset() {
        dice = Array(repeating: 1, count: Self.diceCount)
        held = Array(repeating: false, count: Self.diceCount)
        rollsLeft = Self.maxRolls
        scores = [:]
        turn = 1
        hasRolled = false
    }

    var isComplete: Bool { scores.count == Self.totalTurns }

    func roll() {
        guard rollsLeft > 0, !isComplete else { return }
        for i in 0..<Self.diceCount where !held[i] {
            dice[i] = Int.random(in: 1...6)
        }
        rollsLeft -= 1
        hasRolled = true
    }

    func toggleHold(_ index: Int) {
        guard hasRolled, rollsLeft > 0 else { return }
        held[index].toggle()
    }

    func commit(_ category: YahtzeeCategory) {
        guard hasRolled, !isComplete else { return }
        guard scores[category] == nil else { return }
        scores[category] = Self.score(for: category, dice: dice)
        nextTurn()
    }

    private func nextTurn() {
        turn += 1
        held = Array(repeating: false, count: Self.diceCount)
        rollsLeft = Self.maxRolls
        hasRolled = false
    }

    func potentialScore(for category: YahtzeeCategory) -> Int? {
        guard hasRolled, scores[category] == nil else { return nil }
        return Self.score(for: category, dice: dice)
    }

    var upperTotal: Int {
        YahtzeeCategory.upper.reduce(0) { $0 + (scores[$1] ?? 0) }
    }
    var upperBonus: Int { upperTotal >= 63 ? 35 : 0 }
    var lowerTotal: Int {
        YahtzeeCategory.lower.reduce(0) { $0 + (scores[$1] ?? 0) }
    }
    var grandTotal: Int { upperTotal + upperBonus + lowerTotal }

    static func score(for category: YahtzeeCategory, dice: [Int]) -> Int {
        switch category {
        case .ones:   return dice.filter { $0 == 1 }.reduce(0, +)
        case .twos:   return dice.filter { $0 == 2 }.reduce(0, +)
        case .threes: return dice.filter { $0 == 3 }.reduce(0, +)
        case .fours:  return dice.filter { $0 == 4 }.reduce(0, +)
        case .fives:  return dice.filter { $0 == 5 }.reduce(0, +)
        case .sixes:  return dice.filter { $0 == 6 }.reduce(0, +)
        case .threeOfKind:
            return countMap(dice).values.contains { $0 >= 3 } ? dice.reduce(0, +) : 0
        case .fourOfKind:
            return countMap(dice).values.contains { $0 >= 4 } ? dice.reduce(0, +) : 0
        case .fullHouse:
            let counts = countMap(dice).values.sorted()
            return counts == [2, 3] ? 25 : 0
        case .smallStraight:
            return hasRun(dice: dice, length: 4) ? 30 : 0
        case .largeStraight:
            return hasRun(dice: dice, length: 5) ? 40 : 0
        case .yahtzee:
            return Set(dice).count == 1 ? 50 : 0
        case .chance:
            return dice.reduce(0, +)
        }
    }

    private static func countMap(_ dice: [Int]) -> [Int: Int] {
        var m: [Int: Int] = [:]
        for d in dice { m[d, default: 0] += 1 }
        return m
    }

    private static func hasRun(dice: [Int], length: Int) -> Bool {
        let unique = Set(dice).sorted()
        var run = 1
        var maxRun = 1
        for i in 1..<unique.count {
            if unique[i] == unique[i - 1] + 1 {
                run += 1
                maxRun = max(maxRun, run)
            } else {
                run = 1
            }
        }
        return maxRun >= length
    }
}
