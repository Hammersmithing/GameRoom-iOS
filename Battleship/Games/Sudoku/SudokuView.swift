import SwiftUI

struct SudokuView: View {
    @StateObject private var game = SudokuGame()
    var onExit: () -> Void = {}

    @FocusState private var focused: Bool
    private let cellSize: CGFloat = 50

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "SUDOKU",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset(); focused = true },
                onExit: onExit
            )

            ScaledFit(width: 470, height: 9 * cellSize + 18 + 46 + 8 + 36) {
                VStack(spacing: 18) {
                    board
                    numberPad
                }
            }
            .frame(maxHeight: .infinity)
            if game.isComplete {
                resultBanner.padding(.bottom, 24)
            }
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
        .onKeyPress(.upArrow)    { game.move(.up); return .handled }
        .onKeyPress(.downArrow)  { game.move(.down); return .handled }
        .onKeyPress(.leftArrow)  { game.move(.left); return .handled }
        .onKeyPress(.rightArrow) { game.move(.right); return .handled }
        .onKeyPress(.delete)     { game.clearCell(); return .handled }
        .onKeyPress(phases: .down) { keyPress in
            if let c = keyPress.characters.first {
                if let d = c.wholeNumberValue, d >= 1 && d <= 9 {
                    game.enter(d)
                    return .handled
                }
                if c == "0" {
                    game.clearCell()
                    return .handled
                }
                if c.lowercased() == "n" {
                    game.toggleNoteMode()
                    return .handled
                }
            }
            return .ignored
        }
    }

    private var statusContent: some View {
        HStack(spacing: 8) {
            if game.noteMode {
                Text("Notes mode")
                    .foregroundColor(.yellow)
                    .fontWeight(.bold)
                Text("·").foregroundColor(.gray)
            }
            Text("1-9 enter · 0/⌫ clear · N notes")
                .foregroundColor(.gray)
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
    }

    private var board: some View {
        VStack(spacing: 0) {
            ForEach(0..<SudokuGame.size, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<SudokuGame.size, id: \.self) { col in
                        cell(row: row, col: col)
                    }
                }
            }
        }
        .background(Color.black)
        .overlay(
            Rectangle()
                .stroke(Color.white, lineWidth: 3)
        )
    }

    private func cell(row: Int, col: Int) -> some View {
        let pos = Position(row: row, col: col)
        let value = game.board[row][col]
        let given = game.isGiven(pos)
        let conflict = game.isConflict(at: pos)
        let selected = game.selected == pos
        let sameValue = value != 0 && game.selected.map { game.board[$0.row][$0.col] == value } ?? false
        let inUnit = isInUnit(of: game.selected, pos: pos)

        return Button(action: { game.tap(pos) }) {
            ZStack {
                Rectangle()
                    .fill(cellBackground(selected: selected, sameValue: sameValue, inUnit: inUnit))
                    .frame(width: cellSize, height: cellSize)

                if value != 0 {
                    Text("\(value)")
                        .font(.system(size: 26, weight: given ? .heavy : .semibold, design: .monospaced))
                        .foregroundColor(numberColor(given: given, conflict: conflict))
                } else if !game.notes[row][col].isEmpty {
                    notesView(row: row, col: col)
                }
            }
        }
        .buttonStyle(.plain)
        .overlay(borderOverlay(row: row, col: col))
    }

    private func cellBackground(selected: Bool, sameValue: Bool, inUnit: Bool) -> Color {
        if selected { return Color(red: 0.30, green: 0.40, blue: 0.55) }
        if sameValue { return Color(red: 0.20, green: 0.30, blue: 0.45) }
        if inUnit { return Color(white: 0.16) }
        return Color(white: 0.10)
    }

    private func numberColor(given: Bool, conflict: Bool) -> Color {
        if conflict { return Color(red: 1.0, green: 0.45, blue: 0.45) }
        if given { return .white }
        return Color(red: 0.55, green: 0.85, blue: 1.0)
    }

    private func notesView(row: Int, col: Int) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { c in
                        let digit = r * 3 + c + 1
                        Text(game.notes[row][col].contains(digit) ? "\(digit)" : " ")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(width: cellSize / 3, height: cellSize / 3)
                    }
                }
            }
        }
    }

    private func borderOverlay(row: Int, col: Int) -> some View {
        let thick: CGFloat = 2
        let thin: CGFloat = 0.5
        return ZStack {
            Path { p in
                p.move(to: CGPoint(x: 0, y: cellSize))
                p.addLine(to: CGPoint(x: cellSize, y: cellSize))
            }
            .stroke(Color.white.opacity(0.6), lineWidth: (row + 1) % 3 == 0 ? thick : thin)

            Path { p in
                p.move(to: CGPoint(x: cellSize, y: 0))
                p.addLine(to: CGPoint(x: cellSize, y: cellSize))
            }
            .stroke(Color.white.opacity(0.6), lineWidth: (col + 1) % 3 == 0 ? thick : thin)
        }
        .frame(width: cellSize, height: cellSize)
    }

    private func isInUnit(of selected: Position?, pos: Position) -> Bool {
        guard let s = selected else { return false }
        if s == pos { return false }
        if s.row == pos.row { return true }
        if s.col == pos.col { return true }
        if s.row / 3 == pos.row / 3 && s.col / 3 == pos.col / 3 { return true }
        return false
    }

    private var numberPad: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(1...9, id: \.self) { d in
                    Button(action: { game.enter(d) }) {
                        Text("\(d)")
                            .font(.system(size: 22, weight: .heavy, design: .monospaced))
                            .frame(width: 46, height: 46)
                            .foregroundColor(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(white: 0.22))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(game.isComplete)
                }
            }

            HStack(spacing: 12) {
                Button(action: { game.clearCell() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "delete.left.fill")
                        Text("Clear")
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .frame(width: 110, height: 36)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(white: 0.22))
                    )
                }
                .buttonStyle(.plain)
                .disabled(game.isComplete)

                Button(action: { game.toggleNoteMode() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text(game.noteMode ? "Notes ON" : "Notes")
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .frame(width: 130, height: 36)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(game.noteMode
                                  ? Color(red: 0.5, green: 0.45, blue: 0.10)
                                  : Color(white: 0.22))
                    )
                }
                .buttonStyle(.plain)
                .disabled(game.isComplete)
            }
        }
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill").foregroundColor(.yellow)
                Text("Solved!").fontWeight(.bold)
            }
            .font(.system(size: 26, design: .monospaced))
            .foregroundColor(.white)

            Button("New Puzzle") { game.reset(); focused = true }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
