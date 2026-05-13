import Foundation

enum MancalaResult: Equatable {
    case win(Int)
    case draw
}

class MancalaGame: ObservableObject {
    static let pitsPerSide = 6
    static let initialStones = 4

    /// Indices: 0-5 P1 pits, 6 P1 store, 7-12 P2 pits, 13 P2 store.
    @Published var pits: [Int] = Array(repeating: 0, count: 14)
    @Published var currentTurn: Int = 1
    @Published var result: MancalaResult? = nil
    @Published var lastCaptureFrom: Int? = nil

    init() { reset() }

    func reset() {
        pits = Array(repeating: 0, count: 14)
        for i in 0...5  { pits[i] = Self.initialStones }
        for i in 7...12 { pits[i] = Self.initialStones }
        currentTurn = 1
        result = nil
        lastCaptureFrom = nil
    }

    var p1Score: Int { pits[6] }
    var p2Score: Int { pits[13] }

    func canSelect(pit: Int) -> Bool {
        guard result == nil else { return false }
        if pits[pit] == 0 { return false }
        if currentTurn == 1 { return pit >= 0 && pit <= 5 }
        return pit >= 7 && pit <= 12
    }

    func sow(from start: Int) {
        guard canSelect(pit: start) else { return }
        var stones = pits[start]
        pits[start] = 0
        var idx = start
        let opponentStore = currentTurn == 1 ? 13 : 6
        while stones > 0 {
            idx = (idx + 1) % 14
            if idx == opponentStore { continue }
            pits[idx] += 1
            stones -= 1
        }

        let myStore = currentTurn == 1 ? 6 : 13
        let myRange: ClosedRange<Int> = currentTurn == 1 ? 0...5 : 7...12
        var captured = false

        if myRange.contains(idx), pits[idx] == 1 {
            let opposite = 12 - idx
            if pits[opposite] > 0 {
                pits[myStore] += pits[opposite] + pits[idx]
                pits[opposite] = 0
                pits[idx] = 0
                lastCaptureFrom = opposite
                captured = true
            }
        }

        if idx == myStore {
            // bonus turn — keep currentTurn
        } else {
            currentTurn = currentTurn == 1 ? 2 : 1
        }

        if !captured { lastCaptureFrom = nil }

        checkEnd()
    }

    private func checkEnd() {
        let p1Empty = (0...5).allSatisfy { pits[$0] == 0 }
        let p2Empty = (7...12).allSatisfy { pits[$0] == 0 }
        guard p1Empty || p2Empty else { return }

        for i in 0...5 { pits[6] += pits[i]; pits[i] = 0 }
        for i in 7...12 { pits[13] += pits[i]; pits[i] = 0 }

        if pits[6] > pits[13] { result = .win(1) }
        else if pits[13] > pits[6] { result = .win(2) }
        else { result = .draw }
    }
}
