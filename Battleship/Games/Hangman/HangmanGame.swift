import Foundation

enum HangmanResult: Equatable {
    case won, lost
}

class HangmanGame: ObservableObject {
    static let maxWrong = 6

    static let words: [String] = [
        "BATTLESHIP", "MINESWEEPER", "CHECKERS", "REVERSI", "OTHELLO",
        "SOLITAIRE", "BLACKJACK", "PINBALL", "TETRIS", "PACMAN",
        "COMPUTER", "KEYBOARD", "MOUNTAIN", "UMBRELLA", "ELEPHANT",
        "KINGDOM", "PUZZLE", "RAINBOW", "TREASURE", "VOYAGE",
        "BLUEPRINT", "GUITAR", "LANTERN", "MOSAIC", "HARBOR",
        "TURBINE", "COMPASS", "SAXOPHONE", "LIBRARY", "TELESCOPE",
        "AVALANCHE", "BUTTERFLY", "CHANDELIER", "DAFFODIL", "ECLIPSE",
        "FREEWAY", "GLACIER", "HORIZON", "INSULATE", "JOURNEY"
    ]

    @Published var word: String = ""
    @Published var guessedLetters: Set<Character> = []
    @Published var wrongGuesses: Int = 0
    @Published var result: HangmanResult? = nil

    init() { reset() }

    func reset() {
        word = Self.words.randomElement() ?? "SWIFT"
        guessedLetters = []
        wrongGuesses = 0
        result = nil
    }

    func guess(_ letter: Character) {
        guard result == nil else { return }
        let upper = Character(letter.uppercased())
        guard upper.isLetter else { return }
        guard !guessedLetters.contains(upper) else { return }

        guessedLetters.insert(upper)

        if !word.contains(upper) {
            wrongGuesses += 1
            if wrongGuesses >= Self.maxWrong {
                result = .lost
            }
        } else if isAllRevealed() {
            result = .won
        }
    }

    func isRevealed(_ c: Character) -> Bool {
        if !c.isLetter { return true }
        if result == .lost { return true }
        return guessedLetters.contains(Character(c.uppercased()))
    }

    func wasGuessed(_ c: Character) -> Bool {
        guessedLetters.contains(Character(c.uppercased()))
    }

    func wasGuessedCorrectly(_ c: Character) -> Bool {
        let u = Character(c.uppercased())
        return guessedLetters.contains(u) && word.contains(u)
    }

    private func isAllRevealed() -> Bool {
        for c in word where c.isLetter {
            if !guessedLetters.contains(Character(c.uppercased())) { return false }
        }
        return true
    }
}
