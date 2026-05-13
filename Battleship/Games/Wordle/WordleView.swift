import SwiftUI

struct WordleView: View {
    @StateObject private var game = WordleGame()
    var onExit: () -> Void = {}

    @FocusState private var focused: Bool

    private let cellSize: CGFloat = 56
    private let cellSpacing: CGFloat = 6

    private var naturalWidth: CGFloat { 544 }
    private var naturalHeight: CGFloat {
        let grid = 6 * cellSize + 5 * cellSpacing
        let keyboard: CGFloat = 3 * 48 + 2 * 6
        return grid + 24 + keyboard + 16
    }

    private static let keyboardRows: [[Character]] = [
        Array("QWERTYUIOP"),
        Array("ASDFGHJKL"),
        Array("ZXCVBNM")
    ]

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "WORDLE",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset(); focused = true },
                onExit: onExit
            )

            ScaledFit(width: naturalWidth, height: naturalHeight) {
                VStack(spacing: 24) {
                    guessGrid
                    keyboardView
                }
            }
            .frame(maxHeight: .infinity)
            if game.result != nil {
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
        .onKeyPress(.return) {
            game.submit()
            return .handled
        }
        .onKeyPress(.delete) {
            game.backspace()
            return .handled
        }
        .onKeyPress(phases: .down) { keyPress in
            if let c = keyPress.characters.first, c.isLetter {
                game.type(c)
                return .handled
            }
            return .ignored
        }
    }

    private var statusContent: some View {
        HStack(spacing: 8) {
            Text("Guess:")
                .foregroundColor(.gray)
            Text("\(game.guesses.count) / \(WordleGame.maxGuesses)")
                .foregroundColor(.white)
                .fontWeight(.bold)
            Text("·").foregroundColor(.gray)
            Text("type · enter · delete")
                .foregroundColor(.gray)
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
    }

    private var guessGrid: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<WordleGame.maxGuesses, id: \.self) { row in
                rowView(row)
            }
        }
    }

    private func rowView(_ row: Int) -> some View {
        let isSubmitted = row < game.guesses.count
        let guess: String = isSubmitted
            ? game.guesses[row]
            : (row == game.guesses.count ? game.current : "")
        let fb: [LetterFeedback]? = isSubmitted ? game.feedback(for: guess) : nil

        return HStack(spacing: cellSpacing) {
            ForEach(0..<WordleGame.wordLength, id: \.self) { col in
                let ch: Character? = col < guess.count
                    ? guess[guess.index(guess.startIndex, offsetBy: col)]
                    : nil
                cell(ch: ch, feedback: fb?[col], isCurrent: !isSubmitted && col < guess.count)
            }
        }
    }

    private func cell(ch: Character?, feedback: LetterFeedback?, isCurrent: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(cellFill(feedback))
                .frame(width: cellSize, height: cellSize)
            RoundedRectangle(cornerRadius: 4)
                .stroke(cellStroke(feedback: feedback, hasLetter: ch != nil, isCurrent: isCurrent), lineWidth: 2)
                .frame(width: cellSize, height: cellSize)
            if let ch {
                Text(String(ch))
                    .font(.system(size: 30, weight: .heavy, design: .monospaced))
                    .foregroundColor(feedback == nil ? .white : .white)
            }
        }
    }

    private func cellFill(_ fb: LetterFeedback?) -> Color {
        switch fb {
        case .green:  return Color(red: 0.30, green: 0.70, blue: 0.35)
        case .yellow: return Color(red: 0.85, green: 0.70, blue: 0.20)
        case .gray:   return Color(white: 0.25)
        case nil:     return Color(white: 0.07)
        }
    }

    private func cellStroke(feedback: LetterFeedback?, hasLetter: Bool, isCurrent: Bool) -> Color {
        if feedback != nil { return .clear }
        if hasLetter { return Color(white: 0.55) }
        return Color(white: 0.25)
    }

    private var keyboardView: some View {
        VStack(spacing: 6) {
            ForEach(0..<Self.keyboardRows.count, id: \.self) { idx in
                HStack(spacing: 4) {
                    if idx == Self.keyboardRows.count - 1 {
                        wideKey(label: "ENTER", action: { game.submit() })
                    }
                    ForEach(Self.keyboardRows[idx], id: \.self) { letter in
                        keyButton(letter)
                    }
                    if idx == Self.keyboardRows.count - 1 {
                        wideKey(label: "⌫", action: { game.backspace() })
                    }
                }
            }
        }
    }

    private func keyButton(_ letter: Character) -> some View {
        let status = game.keyboardStatus(for: letter)
        return Button(action: { game.type(letter) }) {
            Text(String(letter))
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .frame(width: 38, height: 48)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(keyFill(status))
                )
        }
        .buttonStyle(.plain)
        .disabled(game.result != nil)
    }

    private func wideKey(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                .frame(width: 60, height: 48)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.32))
                )
        }
        .buttonStyle(.plain)
        .disabled(game.result != nil)
    }

    private func keyFill(_ fb: LetterFeedback?) -> Color {
        switch fb {
        case .green:  return Color(red: 0.30, green: 0.70, blue: 0.35)
        case .yellow: return Color(red: 0.85, green: 0.70, blue: 0.20)
        case .gray:   return Color(white: 0.18)
        case nil:     return Color(white: 0.32)
        }
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            switch game.result {
            case .won(let n):
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").foregroundColor(.yellow)
                    Text("Got it in \(n)!").fontWeight(.bold)
                }
                .font(.system(size: 24, design: .monospaced))
                .foregroundColor(.white)
            case .lost(let answer):
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
                        Text("Out of guesses").fontWeight(.bold)
                    }
                    .font(.system(size: 24, design: .monospaced))
                    .foregroundColor(.white)
                    Text("Answer: \(answer)")
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                }
            case .none:
                EmptyView()
            }

            Button("Play Again") { game.reset(); focused = true }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
