import Foundation

enum Mark: Equatable {
    case x, o

    var symbol: String {
        switch self {
        case .x: return "X"
        case .o: return "O"
        }
    }

    var next: Mark {
        self == .x ? .o : .x
    }
}

enum TicTacToeResult: Equatable {
    case win(Mark)
    case draw
}

class TicTacToeGame: ObservableObject {
    @Published var board: [Mark?] = Array(repeating: nil, count: 9)
    @Published var currentTurn: Mark = .x
    @Published var result: TicTacToeResult? = nil

    private static let winLines: [[Int]] = [
        [0,1,2], [3,4,5], [6,7,8], // rows
        [0,3,6], [1,4,7], [2,5,8], // cols
        [0,4,8], [2,4,6]           // diagonals
    ]

    var winningLine: [Int]? {
        guard case .win(let mark) = result else { return nil }
        return Self.winLines.first { line in
            line.allSatisfy { board[$0] == mark }
        }
    }

    func play(at index: Int) {
        guard board[index] == nil, result == nil else { return }
        board[index] = currentTurn

        if let winner = checkWinner() {
            result = .win(winner)
        } else if board.allSatisfy({ $0 != nil }) {
            result = .draw
        } else {
            currentTurn = currentTurn.next
        }
    }

    private func checkWinner() -> Mark? {
        for line in Self.winLines {
            let marks = line.map { board[$0] }
            if let first = marks[0], marks[1] == first, marks[2] == first {
                return first
            }
        }
        return nil
    }

    func reset() {
        board = Array(repeating: nil, count: 9)
        currentTurn = .x
        result = nil
    }
}
