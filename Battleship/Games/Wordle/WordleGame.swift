import Foundation

enum LetterFeedback: Equatable {
    case green, yellow, gray
}

enum WordleResult: Equatable {
    case won(guesses: Int)
    case lost(answer: String)
}

class WordleGame: ObservableObject {
    static let maxGuesses = 6
    static let wordLength = 5

    static let words: [String] = [
        "APPLE", "BREAD", "CHAIR", "DREAM", "EARTH", "FAITH", "GLOBE", "HAPPY",
        "INDEX", "JOLLY", "KNIFE", "LEMON", "MAGIC", "NIGHT", "OCEAN", "PAPER",
        "QUIET", "RIVER", "STONE", "TIGER", "UNCLE", "VOICE", "WATER", "YOUTH",
        "ZEBRA", "AGAIN", "ALONE", "ANGEL", "ANGRY", "ARGUE", "AWARE", "AWFUL",
        "BEACH", "BEGIN", "BLACK", "BLAME", "BLEND", "BLOCK", "BOARD", "BRAIN",
        "BRAVE", "BREAK", "BRICK", "BRIEF", "BROAD", "BROWN", "BUILD", "BURST",
        "CAUSE", "CHAIN", "CHARM", "CHEAP", "CHEER", "CLEAN", "CLEAR", "CLIMB",
        "CLOCK", "CLOSE", "CLOUD", "COACH", "COVER", "CRAFT", "CRASH", "CRAZY",
        "CREAM", "CRIME", "CROSS", "CROWD", "CROWN", "CRUDE", "CURVE", "DANCE",
        "DEPTH", "DIRTY", "DOZEN", "DRAFT", "DRINK", "DRIVE", "EAGER", "EARLY",
        "EMPTY", "EQUAL", "ERROR", "EVENT", "EVERY", "EXACT", "EXIST", "EXTRA",
        "FAULT", "FAVOR", "FEAST", "FIFTH", "FIFTY", "FIGHT", "FINAL", "FIRST",
        "FLASH", "FLOAT", "FLOOR", "FLOUR", "FOCUS", "FORGE", "FORTH", "FORTY",
        "FRAME", "FRESH", "FRONT", "FRUIT", "FUNNY", "GHOST", "GIANT", "GLASS",
        "GRACE", "GRADE", "GRAIN", "GRAND", "GRANT", "GRASS", "GRAVE", "GREAT",
        "GREEN", "GROUP", "GROWN", "GUARD", "GUESS", "GUEST", "GUIDE", "HAPPY",
        "HEART", "HEAVY", "HORSE", "HOTEL", "HOUSE", "HUMOR", "ISSUE", "JOINT",
        "JUDGE", "JUICE", "LARGE", "LAUGH", "LEARN", "LEAST", "LEAVE", "LEGAL",
        "LIGHT", "LIMIT", "LOCAL", "LOOSE", "LUCKY", "LUNCH", "MAJOR", "MARCH",
        "MATCH", "MAYBE", "MAYOR", "MERCY", "METAL", "MIGHT", "MINOR", "MOUTH",
        "MOVIE", "MUSIC", "NEVER", "NIGHT", "NOISE", "NORTH", "NOVEL", "NURSE",
        "OFFER", "OFTEN", "ORDER", "OTHER", "PARTY", "PEACE", "PHONE", "PIANO",
        "PIECE", "PILOT", "PLAIN", "PLANE", "PLANT", "PLATE", "POINT", "POUND",
        "POWER", "PRESS", "PRICE", "PRIDE", "PRIME", "PRINT", "PRIZE", "PROOF",
        "PROUD", "PROVE", "QUICK", "QUIET", "QUITE", "RADIO", "RAISE", "RANGE",
        "REACH", "READY", "REFER", "RIGHT", "ROBOT", "ROUND", "ROUTE", "ROYAL",
        "RURAL", "SCENE", "SCOPE", "SCORE", "SENSE", "SERVE", "SEVEN", "SHALL",
        "SHAPE", "SHARE", "SHARP", "SHEEP", "SHEET", "SHELF", "SHIFT", "SHINE",
        "SHIRT", "SHORT", "SHOWN", "SIGHT", "SINCE", "SIXTH", "SIXTY", "SKILL",
        "SLEEP", "SLIDE", "SMALL", "SMART", "SMILE", "SOLID", "SORRY", "SOUND",
        "SOUTH", "SPACE", "SPARE", "SPEAK", "SPEED", "SPEND", "SPENT", "SPLIT",
        "SPORT", "STAFF", "STAGE", "STAIR", "STAND", "START", "STATE", "STEAM",
        "STEEL", "STICK", "STILL", "STOCK", "STORE", "STORM", "STORY", "STRIP",
        "STUDY", "STYLE", "SUGAR", "SUITE", "SUPER", "SWEET", "TABLE", "TASTE",
        "TEACH", "THANK", "THEME", "THERE", "THICK", "THING", "THIRD", "THOSE",
        "THREE", "THROW", "TIGHT", "TODAY", "TOOTH", "TOTAL", "TOUCH", "TOUGH",
        "TOWER", "TRACK", "TRADE", "TRAIN", "TREAT", "TREND", "TRIAL", "TRIBE",
        "TRICK", "TRULY", "TRUNK", "TRUST", "TRUTH", "TWICE", "UNDER", "UNDUE",
        "UNTIL", "UPPER", "UPSET", "URBAN", "USAGE", "VALID", "VALUE", "VIDEO",
        "VITAL", "VOCAL", "VOICE", "WASTE", "WATCH", "WHEEL", "WHERE", "WHICH",
        "WHILE", "WHITE", "WHOLE", "WHOSE", "WOMAN", "WORLD", "WORRY", "WORSE",
        "WORST", "WORTH", "WOULD", "WRITE", "WRONG", "YIELD", "YOUNG"
    ]

    @Published var answer: String = ""
    @Published var guesses: [String] = []
    @Published var current: String = ""
    @Published var result: WordleResult? = nil

    init() { reset() }

    func reset() {
        answer = Self.words.randomElement() ?? "SWIFT"
        guesses = []
        current = ""
        result = nil
    }

    func type(_ letter: Character) {
        guard result == nil else { return }
        guard current.count < Self.wordLength else { return }
        let upper = Character(letter.uppercased())
        guard upper.isLetter else { return }
        current.append(upper)
    }

    func backspace() {
        guard result == nil else { return }
        if !current.isEmpty { current.removeLast() }
    }

    func submit() {
        guard result == nil else { return }
        guard current.count == Self.wordLength else { return }
        guesses.append(current)
        if current == answer {
            result = .won(guesses: guesses.count)
        } else if guesses.count >= Self.maxGuesses {
            result = .lost(answer: answer)
        }
        current = ""
    }

    func feedback(for guess: String) -> [LetterFeedback] {
        let answerChars = Array(answer)
        let guessChars = Array(guess)
        var result: [LetterFeedback] = Array(repeating: .gray, count: Self.wordLength)
        var available = answerChars

        for i in 0..<Self.wordLength where guessChars[i] == answerChars[i] {
            result[i] = .green
            available[i] = "_"
        }
        for i in 0..<Self.wordLength where result[i] != .green {
            if let idx = available.firstIndex(of: guessChars[i]) {
                result[i] = .yellow
                available[idx] = "_"
            }
        }
        return result
    }

    func keyboardStatus(for letter: Character) -> LetterFeedback? {
        let upper = Character(letter.uppercased())
        var best: LetterFeedback? = nil
        for guess in guesses {
            let fb = feedback(for: guess)
            for (i, ch) in guess.enumerated() where ch == upper {
                let s = fb[i]
                if best == nil || rank(s) > rank(best!) {
                    best = s
                }
            }
        }
        return best
    }

    private func rank(_ f: LetterFeedback) -> Int {
        switch f {
        case .gray: return 1
        case .yellow: return 2
        case .green: return 3
        }
    }
}
