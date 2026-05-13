import Foundation

enum MastermindResult: Equatable {
    case won(guesses: Int)
    case lost(code: [Int])
}

class MastermindGame: ObservableObject {
    static let positions = 4
    static let colorCount = 6
    static let maxGuesses = 10

    @Published var code: [Int] = []
    @Published var guesses: [[Int]] = []
    @Published var feedbacks: [(black: Int, white: Int)] = []
    @Published var current: [Int?] = Array(repeating: nil, count: positions)
    @Published var result: MastermindResult? = nil

    init() { reset() }

    func reset() {
        code = (0..<Self.positions).map { _ in Int.random(in: 0..<Self.colorCount) }
        guesses = []
        feedbacks = []
        current = Array(repeating: nil, count: Self.positions)
        result = nil
    }

    func place(color: Int) {
        guard result == nil else { return }
        if let i = current.firstIndex(of: nil) {
            current[i] = color
        }
    }

    func clearSlot(_ index: Int) {
        guard result == nil else { return }
        guard index >= 0, index < Self.positions else { return }
        current[index] = nil
    }

    var canSubmit: Bool {
        result == nil && current.allSatisfy { $0 != nil }
    }

    func submit() {
        guard canSubmit else { return }
        let guess = current.compactMap { $0 }
        let fb = Self.computeFeedback(guess: guess, code: code)
        guesses.append(guess)
        feedbacks.append(fb)

        if fb.black == Self.positions {
            result = .won(guesses: guesses.count)
        } else if guesses.count >= Self.maxGuesses {
            result = .lost(code: code)
        }
        current = Array(repeating: nil, count: Self.positions)
    }

    static func computeFeedback(guess: [Int], code: [Int]) -> (black: Int, white: Int) {
        var blacks = 0
        var availableCode: [Int?] = code.map { $0 }
        var availableGuess: [Int?] = guess.map { $0 }

        for i in 0..<positions where guess[i] == code[i] {
            blacks += 1
            availableCode[i] = nil
            availableGuess[i] = nil
        }

        var whites = 0
        for i in 0..<positions {
            guard let g = availableGuess[i] else { continue }
            if let idx = availableCode.firstIndex(of: g) {
                whites += 1
                availableCode[idx] = nil
            }
        }
        return (blacks, whites)
    }
}
