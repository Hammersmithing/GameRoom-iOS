import Foundation

enum ShipType: String, CaseIterable, Identifiable {
    case carrier = "Carrier"
    case battleship = "Battleship"
    case cruiser = "Cruiser"
    case submarine = "Submarine"
    case destroyer = "Destroyer"

    var id: String { rawValue }

    var length: Int {
        switch self {
        case .carrier: return 5
        case .battleship: return 4
        case .cruiser: return 3
        case .submarine: return 3
        case .destroyer: return 2
        }
    }
}

enum Orientation {
    case horizontal, vertical
}

struct Ship: Identifiable {
    let id = UUID()
    let type: ShipType
    var origin: GridPosition
    var orientation: Orientation

    var length: Int { type.length }

    var positions: [GridPosition] {
        (0..<length).map { i in
            switch orientation {
            case .horizontal: return GridPosition(row: origin.row, col: origin.col + i)
            case .vertical: return GridPosition(row: origin.row + i, col: origin.col)
            }
        }
    }

    func isValid(boardSize: Int) -> Bool {
        positions.allSatisfy { $0.row >= 0 && $0.row < boardSize && $0.col >= 0 && $0.col < boardSize }
    }
}
