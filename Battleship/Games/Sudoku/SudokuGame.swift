import Foundation

class SudokuGame: ObservableObject {
    static let size = 9
    static let givensCount = 36

    @Published var puzzle: [[Int]]
    @Published var solution: [[Int]]
    @Published var board: [[Int]]
    @Published var notes: [[Set<Int>]]
    @Published var selected: Position? = nil
    @Published var noteMode: Bool = false
    @Published var isComplete: Bool = false

    init() {
        let s = Self.empty()
        puzzle = s
        solution = s
        board = s
        notes = Array(repeating: Array(repeating: Set<Int>(), count: Self.size), count: Self.size)
        reset()
    }

    static func empty() -> [[Int]] {
        Array(repeating: Array(repeating: 0, count: size), count: size)
    }

    func reset() {
        let solved = Self.shuffle(Self.baseGrid())
        solution = solved
        var p = solved
        var positions = (0..<(Self.size * Self.size)).map { Position(row: $0 / Self.size, col: $0 % Self.size) }
        positions.shuffle()
        let toRemove = Self.size * Self.size - Self.givensCount
        for pos in positions.prefix(toRemove) {
            p[pos.row][pos.col] = 0
        }
        puzzle = p
        board = p
        notes = Array(repeating: Array(repeating: Set<Int>(), count: Self.size), count: Self.size)
        selected = nil
        noteMode = false
        isComplete = false
    }

    func isGiven(_ pos: Position) -> Bool {
        puzzle[pos.row][pos.col] != 0
    }

    func tap(_ pos: Position) {
        guard !isComplete else { return }
        selected = pos
    }

    func move(_ direction: SudokuDirection) {
        guard !isComplete else { return }
        let s = selected ?? Position(row: 0, col: 0)
        var r = s.row, c = s.col
        switch direction {
        case .up:    r = (r - 1 + Self.size) % Self.size
        case .down:  r = (r + 1) % Self.size
        case .left:  c = (c - 1 + Self.size) % Self.size
        case .right: c = (c + 1) % Self.size
        }
        selected = Position(row: r, col: c)
    }

    func enter(_ digit: Int) {
        guard let s = selected, !isComplete else { return }
        guard digit >= 1 && digit <= 9 else { return }
        guard !isGiven(s) else { return }

        if noteMode {
            if board[s.row][s.col] != 0 { return }
            if notes[s.row][s.col].contains(digit) {
                notes[s.row][s.col].remove(digit)
            } else {
                notes[s.row][s.col].insert(digit)
            }
        } else {
            board[s.row][s.col] = digit
            notes[s.row][s.col].removeAll()
            checkComplete()
        }
    }

    func clearCell() {
        guard let s = selected, !isComplete, !isGiven(s) else { return }
        board[s.row][s.col] = 0
        notes[s.row][s.col].removeAll()
    }

    func toggleNoteMode() {
        noteMode.toggle()
    }

    func isConflict(at pos: Position) -> Bool {
        let v = board[pos.row][pos.col]
        if v == 0 { return false }
        for c in 0..<Self.size where c != pos.col && board[pos.row][c] == v { return true }
        for r in 0..<Self.size where r != pos.row && board[r][pos.col] == v { return true }
        let br = (pos.row / 3) * 3, bc = (pos.col / 3) * 3
        for r in br..<br+3 {
            for c in bc..<bc+3 where (r != pos.row || c != pos.col) {
                if board[r][c] == v { return true }
            }
        }
        return false
    }

    private func checkComplete() {
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if board[r][c] != solution[r][c] { return }
            }
        }
        isComplete = true
    }

    // MARK: - Generation

    private static func baseGrid() -> [[Int]] {
        var g = Array(repeating: Array(repeating: 0, count: size), count: size)
        for r in 0..<size {
            for c in 0..<size {
                g[r][c] = ((r * 3 + r / 3 + c) % size) + 1
            }
        }
        return g
    }

    private static func shuffle(_ grid: [[Int]]) -> [[Int]] {
        var g = grid

        var digits = Array(1...9)
        digits.shuffle()
        g = g.map { row in row.map { digits[$0 - 1] } }

        for band in 0..<3 {
            let rows = [band*3, band*3+1, band*3+2].shuffled()
            var temp = g
            for i in 0..<3 { temp[band*3 + i] = g[rows[i]] }
            g = temp
        }

        for stack in 0..<3 {
            let cols = [stack*3, stack*3+1, stack*3+2].shuffled()
            var temp = g
            for i in 0..<3 {
                for r in 0..<size {
                    temp[r][stack*3 + i] = g[r][cols[i]]
                }
            }
            g = temp
        }

        let bandOrder = [0, 1, 2].shuffled()
        var temp1 = Array(repeating: Array(repeating: 0, count: size), count: size)
        for newBand in 0..<3 {
            let oldBand = bandOrder[newBand]
            for r in 0..<3 {
                temp1[newBand*3 + r] = g[oldBand*3 + r]
            }
        }
        g = temp1

        let stackOrder = [0, 1, 2].shuffled()
        var temp2 = Array(repeating: Array(repeating: 0, count: size), count: size)
        for newStack in 0..<3 {
            let oldStack = stackOrder[newStack]
            for r in 0..<size {
                for c in 0..<3 {
                    temp2[r][newStack*3 + c] = g[r][oldStack*3 + c]
                }
            }
        }
        g = temp2

        return g
    }
}

enum SudokuDirection {
    case up, down, left, right
}
