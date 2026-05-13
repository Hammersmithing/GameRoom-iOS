import SwiftUI

struct TetrisView: View {
    @StateObject private var game = TetrisGame()
    var onExit: () -> Void = {}

    @FocusState private var focused: Bool
    private let cellSize: CGFloat = 28
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "TETRIS",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset(); focused = true },
                onExit: onExit
            )

            HStack(alignment: .top, spacing: 24) {
                playfield
                sidebar
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            LinearGradient(
                colors: [Color(white: 0.10), Color(white: 0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .onReceive(timer) { _ in game.tick() }
        .onKeyPress(.leftArrow)  { game.moveLeft();  return .handled }
        .onKeyPress(.rightArrow) { game.moveRight(); return .handled }
        .onKeyPress(.upArrow)    { game.rotate();    return .handled }
        .onKeyPress(.downArrow)  { game.softDrop();  return .handled }
        .onKeyPress(.space)      { game.hardDrop();  return .handled }
        .onKeyPress(phases: .down) { keyPress in
            switch keyPress.characters.lowercased() {
            case "p": game.togglePause(); return .handled
            default:  return .ignored
            }
        }
    }

    private var statusContent: some View {
        HStack(spacing: 6) {
            Text("←→ move · ↑ rotate · ↓ soft · space hard · P pause")
                .foregroundColor(.gray)
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
    }

    private var playfield: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 1) {
                ForEach(0..<TetrisGame.rows, id: \.self) { r in
                    HStack(spacing: 1) {
                        ForEach(0..<TetrisGame.cols, id: \.self) { c in
                            cell(at: r, c: c)
                        }
                    }
                }
            }

            if game.isGameOver {
                gameOverOverlay
            } else if game.isPaused {
                pausedOverlay
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(white: 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(white: 0.3), lineWidth: 2)
        )
    }

    private func cell(at r: Int, c: Int) -> some View {
        let locked = game.grid[r][c]
        let active: TetrominoType? = {
            guard let p = game.current else { return nil }
            for (dr, dc) in p.cells where p.row + dr == r && p.col + dc == c {
                return p.type
            }
            return nil
        }()
        let type = locked ?? active

        return Rectangle()
            .fill(type.map(tetrominoColor) ?? Color(white: 0.12))
            .frame(width: cellSize, height: cellSize)
            .overlay(
                Rectangle()
                    .stroke(type == nil ? Color.white.opacity(0.04) : Color.black.opacity(0.25), lineWidth: 1)
            )
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            statBlock(title: "SCORE", value: "\(game.score)")
            statBlock(title: "LINES", value: "\(game.lines)")
            statBlock(title: "LEVEL", value: "\(game.level)")

            VStack(alignment: .leading, spacing: 8) {
                Text("NEXT")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundColor(.gray)
                nextPreview
            }

            Spacer()
        }
        .frame(width: 140)
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    private var nextPreview: some View {
        let cells = game.nextType.cells(rotation: 0)
        let previewSize: CGFloat = 22
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color(white: 0.10))
                .frame(width: previewSize * 4 + 8, height: previewSize * 4 + 8)
            ForEach(0..<cells.count, id: \.self) { i in
                let (r, c) = cells[i]
                Rectangle()
                    .fill(tetrominoColor(game.nextType))
                    .frame(width: previewSize, height: previewSize)
                    .position(
                        x: CGFloat(c) * previewSize + previewSize / 2 + 4,
                        y: CGFloat(r) * previewSize + previewSize / 2 + 4
                    )
            }
        }
        .frame(width: previewSize * 4 + 8, height: previewSize * 4 + 8)
        .overlay(
            Rectangle()
                .stroke(Color(white: 0.25), lineWidth: 1)
        )
    }

    private var gameOverOverlay: some View {
        ZStack {
            Rectangle().fill(Color.black.opacity(0.7))
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
                    Text("Game Over").fontWeight(.bold)
                }
                .font(.system(size: 24, design: .monospaced))
                .foregroundColor(.white)
                Text("Score: \(game.score)")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                Button("Play Again") { game.reset(); focused = true }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var pausedOverlay: some View {
        ZStack {
            Rectangle().fill(Color.black.opacity(0.7))
            Text("PAUSED")
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    private func tetrominoColor(_ t: TetrominoType) -> Color {
        switch t {
        case .I: return Color(red: 0.10, green: 0.85, blue: 0.95)
        case .O: return Color(red: 0.95, green: 0.85, blue: 0.10)
        case .T: return Color(red: 0.65, green: 0.30, blue: 0.85)
        case .S: return Color(red: 0.30, green: 0.85, blue: 0.35)
        case .Z: return Color(red: 0.95, green: 0.25, blue: 0.30)
        case .L: return Color(red: 0.95, green: 0.55, blue: 0.15)
        case .J: return Color(red: 0.20, green: 0.45, blue: 0.95)
        }
    }
}
