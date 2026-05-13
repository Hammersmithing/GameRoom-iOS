import Foundation

enum SnakeDirection: Equatable {
    case up, down, left, right

    var delta: (Int, Int) {
        switch self {
        case .up:    return (-1, 0)
        case .down:  return ( 1, 0)
        case .left:  return ( 0,-1)
        case .right: return ( 0, 1)
        }
    }

    var opposite: SnakeDirection {
        switch self {
        case .up:    return .down
        case .down:  return .up
        case .left:  return .right
        case .right: return .left
        }
    }
}

class SnakeGame: ObservableObject {
    static let size = 20

    @Published var snake: [Position] = []
    @Published var food: Position = Position(row: 0, col: 0)
    @Published var direction: SnakeDirection = .right
    @Published var pendingDirection: SnakeDirection = .right
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var isPaused: Bool = false

    init() { reset() }

    func reset() {
        let mid = Self.size / 2
        snake = [
            Position(row: mid, col: mid + 1),
            Position(row: mid, col: mid),
            Position(row: mid, col: mid - 1)
        ]
        direction = .right
        pendingDirection = .right
        score = 0
        isGameOver = false
        isPaused = false
        spawnFood()
    }

    func setDirection(_ d: SnakeDirection) {
        if isGameOver { return }
        if d == pendingDirection.opposite { return }
        pendingDirection = d
    }

    func togglePause() {
        guard !isGameOver else { return }
        isPaused.toggle()
    }

    func tick() {
        guard !isGameOver, !isPaused else { return }
        direction = pendingDirection

        let head = snake[0]
        let (dr, dc) = direction.delta
        let next = Position(row: head.row + dr, col: head.col + dc)

        if next.row < 0 || next.row >= Self.size
            || next.col < 0 || next.col >= Self.size {
            isGameOver = true
            return
        }
        if snake.dropLast().contains(next) {
            isGameOver = true
            return
        }

        snake.insert(next, at: 0)
        if next == food {
            score += 1
            spawnFood()
        } else {
            snake.removeLast()
        }
    }

    private func spawnFood() {
        let occupied = Set(snake)
        var open: [Position] = []
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                let p = Position(row: r, col: c)
                if !occupied.contains(p) { open.append(p) }
            }
        }
        if let f = open.randomElement() {
            food = f
        } else {
            isGameOver = true
        }
    }
}
