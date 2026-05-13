import SwiftUI

struct GameDefinition: Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let playerCount: String
    let color: Color
    let view: ((@escaping () -> Void) -> AnyView)
}

let allGames: [GameDefinition] = [
    GameDefinition(
        id: "battleship",
        name: "Battleship",
        icon: "scope",
        description: "Classic naval combat. Place your fleet and sink the enemy ships.",
        playerCount: "2 Players",
        color: .blue,
        view: { onExit in AnyView(BattleshipView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "tictactoe",
        name: "Tic Tac Toe",
        icon: "number",
        description: "Classic X's and O's. Get three in a row to win.",
        playerCount: "2 Players",
        color: .purple,
        view: { onExit in AnyView(TicTacToeView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "connectfour",
        name: "Connect Four",
        icon: "circle.grid.3x3.fill",
        description: "Drop discs and connect four in a row to win.",
        playerCount: "2 Players",
        color: .red,
        view: { onExit in AnyView(ConnectFourView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "checkers",
        name: "Checkers",
        icon: "crown.fill",
        description: "Hop diagonally, capture your opponent, and king your pieces.",
        playerCount: "2 Players",
        color: .brown,
        view: { onExit in AnyView(CheckersView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "reversi",
        name: "Reversi",
        icon: "circle.lefthalf.filled",
        description: "Flank your opponent's discs to flip them. Most discs at the end wins.",
        playerCount: "2 Players",
        color: .green,
        view: { onExit in AnyView(ReversiView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "minesweeper",
        name: "Minesweeper",
        icon: "flag.fill",
        description: "Clear the field without detonating a mine. ⌥-click to flag.",
        playerCount: "1 Player",
        color: .gray,
        view: { onExit in AnyView(MinesweeperView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "snake",
        name: "Snake",
        icon: "leaf.fill",
        description: "Eat to grow. Don't hit the walls or yourself.",
        playerCount: "1 Player",
        color: .mint,
        view: { onExit in AnyView(SnakeView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "memorymatch",
        name: "Memory Match",
        icon: "rectangle.on.rectangle.fill",
        description: "Flip pairs of cards. Match them all in as few moves as possible.",
        playerCount: "1 Player",
        color: .pink,
        view: { onExit in AnyView(MemoryMatchView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "dotsandboxes",
        name: "Dots and Boxes",
        icon: "square.grid.3x3.middle.filled",
        description: "Connect dots to claim boxes. Complete one to go again.",
        playerCount: "2 Players",
        color: .orange,
        view: { onExit in AnyView(DotsAndBoxesView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "hangman",
        name: "Hangman",
        icon: "textformat",
        description: "Guess the word one letter at a time. Six wrong and you're out.",
        playerCount: "1 Player",
        color: .yellow,
        view: { onExit in AnyView(HangmanView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "chess",
        name: "Chess",
        icon: "checkerboard.shield",
        description: "Full rules: castling, en passant, auto-queen promotion, check, and checkmate.",
        playerCount: "2 Players",
        color: .indigo,
        view: { onExit in AnyView(ChessView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "pong",
        name: "Pong",
        icon: "circle.fill",
        description: "Two paddles, one ball. First to 7 points wins.",
        playerCount: "2 Players",
        color: .cyan,
        view: { onExit in AnyView(PongView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "twentyfortyeight",
        name: "2048",
        icon: "square.grid.2x2.fill",
        description: "Slide tiles with arrow keys. Merge matching numbers to reach 2048.",
        playerCount: "1 Player",
        color: .orange,
        view: { onExit in AnyView(TwentyFortyEightView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "tetris",
        name: "Tetris",
        icon: "square.stack.3d.up.fill",
        description: "Falling tetrominoes. Clear lines and survive as the speed climbs.",
        playerCount: "1 Player",
        color: .teal,
        view: { onExit in AnyView(TetrisView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "wordle",
        name: "Wordle",
        icon: "square.text.square.fill",
        description: "Guess the 5-letter word in six tries with green and yellow hints.",
        playerCount: "1 Player",
        color: .green,
        view: { onExit in AnyView(WordleView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "spaceinvaders",
        name: "Space Invaders",
        icon: "airplane",
        description: "Solo or 2-player co-op. Defend the line as the wave drops faster.",
        playerCount: "1-2 Players",
        color: .purple,
        view: { onExit in AnyView(SpaceInvadersView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "asteroids",
        name: "Asteroids",
        icon: "sparkles",
        description: "Solo or 2-player co-op. Rotate, thrust, fire — wrap around the edges.",
        playerCount: "1-2 Players",
        color: .indigo,
        view: { onExit in AnyView(AsteroidsView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "sudoku",
        name: "Sudoku",
        icon: "square.grid.3x3.square",
        description: "Fill the 9×9 grid so every row, column, and box has each digit once.",
        playerCount: "1 Player",
        color: .blue,
        view: { onExit in AnyView(SudokuView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "solitaire",
        name: "Solitaire",
        icon: "suit.club.fill",
        description: "Klondike — build foundations from Ace to King, alternating-color tableau.",
        playerCount: "1 Player",
        color: .green,
        view: { onExit in AnyView(SolitaireView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "mastermind",
        name: "Mastermind",
        icon: "circle.hexagongrid.fill",
        description: "Crack the four-peg color code in ten guesses with peg feedback.",
        playerCount: "1 Player",
        color: .pink,
        view: { onExit in AnyView(MastermindView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "breakout",
        name: "Breakout",
        icon: "rectangle.split.3x1.fill",
        description: "Smash the brick wall with a paddle and a ball. Don't let it fall.",
        playerCount: "1 Player",
        color: .red,
        view: { onExit in AnyView(BreakoutView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "lightsout",
        name: "Lights Out",
        icon: "lightbulb.fill",
        description: "Toggle a cell and its neighbors. Turn off every light.",
        playerCount: "1 Player",
        color: .yellow,
        view: { onExit in AnyView(LightsOutView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "yahtzee",
        name: "Yahtzee",
        icon: "die.face.5.fill",
        description: "Three rolls per turn, 13 scoring categories. Maximize your score.",
        playerCount: "1 Player",
        color: .red,
        view: { onExit in AnyView(YahtzeeView(onExit: onExit)) }
    ),
    GameDefinition(
        id: "mancala",
        name: "Mancala",
        icon: "circle.grid.2x2",
        description: "Sow stones counter-clockwise. Capture and finish with the most.",
        playerCount: "2 Players",
        color: .brown,
        view: { onExit in AnyView(MancalaView(onExit: onExit)) }
    ),
]
