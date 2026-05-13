import Foundation
import SwiftUI

indirect enum GamePhase: Equatable {
    case placingShips(player: Int) // 1 or 2
    case transition(to: GamePhase)
    case firing(player: Int)
    case shotResult(player: Int, position: GridPosition, wasHit: Bool, sunkShip: ShipType?)
    case gameOver(winner: Int)

    static func == (lhs: GamePhase, rhs: GamePhase) -> Bool {
        switch (lhs, rhs) {
        case (.placingShips(let a), .placingShips(let b)): return a == b
        case (.firing(let a), .firing(let b)): return a == b
        case (.gameOver(let a), .gameOver(let b)): return a == b
        case (.shotResult(let a, _, _, _), .shotResult(let b, _, _, _)): return a == b
        case (.transition, .transition): return true
        default: return false
        }
    }
}

class Game: ObservableObject {
    @Published var phase: GamePhase = .placingShips(player: 1)
    @Published var board1 = Board()
    @Published var board2 = Board()
    @Published var message: String = "Player 1: Place your ships"

    // Placement state
    @Published var currentShipIndex: Int = 0
    @Published var placementOrientation: Orientation = .horizontal
    @Published var hoverPosition: GridPosition? = nil

    var shipsToPlace: [ShipType] { ShipType.allCases }

    var currentShipType: ShipType? {
        guard currentShipIndex < shipsToPlace.count else { return nil }
        return shipsToPlace[currentShipIndex]
    }

    func boardFor(player: Int) -> Board {
        player == 1 ? board1 : board2
    }

    func opponentBoard(for player: Int) -> Board {
        player == 1 ? board2 : board1
    }

    // MARK: - Ship Placement

    func placeShip(at pos: GridPosition, player: Int) {
        guard case .placingShips(let p) = phase, p == player else { return }
        guard let shipType = currentShipType else { return }

        let ship = Ship(type: shipType, origin: pos, orientation: placementOrientation)
        let board = boardFor(player: player)

        if board.place(ship: ship) {
            currentShipIndex += 1
            if currentShipIndex >= shipsToPlace.count {
                if player == 1 {
                    currentShipIndex = 0
                    phase = .transition(to: .placingShips(player: 2))
                    message = "Pass the computer to Player 2"
                } else {
                    phase = .transition(to: .firing(player: 1))
                    message = "Pass the computer to Player 1"
                }
            } else {
                message = "Player \(player): Place your \(shipsToPlace[currentShipIndex].rawValue)"
            }
        }
    }

    func toggleOrientation() {
        placementOrientation = placementOrientation == .horizontal ? .vertical : .horizontal
    }

    // MARK: - Firing

    func fireShot(at pos: GridPosition, player: Int) {
        guard case .firing(let p) = phase, p == player else { return }

        let target = opponentBoard(for: player)
        guard let wasHit = target.receiveShot(at: pos) else { return }

        var sunkShip: ShipType? = nil
        if wasHit, let ship = target.shipAt(pos), target.isShipSunk(ship) {
            sunkShip = ship.type
        }

        if target.allShipsSunk() {
            phase = .gameOver(winner: player)
            message = "Player \(player) wins!"
        } else {
            phase = .shotResult(player: player, position: pos, wasHit: wasHit, sunkShip: sunkShip)
            if wasHit {
                if let sunk = sunkShip {
                    message = "HIT! You sank their \(sunk.rawValue)!"
                } else {
                    message = "HIT!"
                }
            } else {
                message = "Miss."
            }
        }
    }

    func endTurn(player: Int) {
        let next = player == 1 ? 2 : 1
        phase = .transition(to: .firing(player: next))
        message = "Pass the computer to Player \(next)"
    }

    func continueFromTransition() {
        guard case .transition(let next) = phase else { return }
        phase = next
        switch next {
        case .placingShips(let p):
            currentShipIndex = 0
            message = "Player \(p): Place your \(shipsToPlace[0].rawValue)"
        case .firing(let p):
            message = "Player \(p): Choose a target"
        default:
            break
        }
    }

    func newGame() {
        board1.reset()
        board2.reset()
        currentShipIndex = 0
        placementOrientation = .horizontal
        hoverPosition = nil
        phase = .placingShips(player: 1)
        message = "Player 1: Place your \(shipsToPlace[0].rawValue)"
    }
}
