import Foundation

struct GridPosition: Hashable {
    let row: Int
    let col: Int
}

enum CellState {
    case empty
    case ship
    case hit
    case miss
}

class Board: ObservableObject {
    static let size = 10

    @Published var ships: [Ship] = []
    @Published var shots: Set<GridPosition> = []
    @Published var hits: Set<GridPosition> = []

    private var shipCells: Set<GridPosition> {
        Set(ships.flatMap { $0.positions })
    }

    func cellState(at pos: GridPosition) -> CellState {
        if hits.contains(pos) { return .hit }
        if shots.contains(pos) { return .miss }
        if shipCells.contains(pos) { return .ship }
        return .empty
    }

    /// What the opponent sees (no ship locations revealed)
    func opponentCellState(at pos: GridPosition) -> CellState {
        if hits.contains(pos) { return .hit }
        if shots.contains(pos) { return .miss }
        return .empty
    }

    func canPlace(ship: Ship) -> Bool {
        guard ship.isValid(boardSize: Board.size) else { return false }
        let existing = shipCells
        return ship.positions.allSatisfy { !existing.contains($0) }
    }

    func place(ship: Ship) -> Bool {
        guard canPlace(ship: ship) else { return false }
        ships.append(ship)
        return true
    }

    /// Returns true if hit, false if miss. Nil if already shot there.
    func receiveShot(at pos: GridPosition) -> Bool? {
        guard !shots.contains(pos) && !hits.contains(pos) else { return nil }
        if shipCells.contains(pos) {
            hits.insert(pos)
            return true
        } else {
            shots.insert(pos)
            return false
        }
    }

    func allShipsSunk() -> Bool {
        shipCells.allSatisfy { hits.contains($0) }
    }

    func shipAt(_ pos: GridPosition) -> Ship? {
        ships.first { $0.positions.contains(pos) }
    }

    func isShipSunk(_ ship: Ship) -> Bool {
        ship.positions.allSatisfy { hits.contains($0) }
    }

    func reset() {
        ships.removeAll()
        shots.removeAll()
        hits.removeAll()
    }
}
