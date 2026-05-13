import SwiftUI

struct HangmanView: View {
    @StateObject private var game = HangmanGame()
    var onExit: () -> Void = {}

    @FocusState private var focused: Bool

    private static let alphabet: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "HANGMAN",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset(); focused = true },
                onExit: onExit
            )

            VStack(spacing: 24) {
                Spacer()
                hangmanCanvas
                wordView
                letterGrid
                Spacer()
                if game.result != nil {
                    resultBanner.padding(.bottom, 24)
                }
            }
            .padding(.horizontal, 24)
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
        .onKeyPress(phases: .down) { keyPress in
            if let c = keyPress.characters.first, c.isLetter {
                game.guess(c)
                return .handled
            }
            return .ignored
        }
    }

    private var statusContent: some View {
        HStack(spacing: 8) {
            Text("Wrong:").foregroundColor(.gray)
            Text("\(game.wrongGuesses) / \(HangmanGame.maxWrong)")
                .foregroundColor(game.wrongGuesses >= 4 ? .red : .white)
                .fontWeight(.bold)
            Text("·").foregroundColor(.gray)
            Text("type letters to guess")
                .foregroundColor(.gray)
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
    }

    private var hangmanCanvas: some View {
        Canvas { context, _ in
            let stroke = GraphicsContext.Shading.color(.white)
            let lw: CGFloat = 4

            var gallows = Path()
            gallows.move(to: CGPoint(x: 30, y: 240))
            gallows.addLine(to: CGPoint(x: 90, y: 240))
            gallows.move(to: CGPoint(x: 50, y: 240))
            gallows.addLine(to: CGPoint(x: 50, y: 30))
            gallows.addLine(to: CGPoint(x: 130, y: 30))
            gallows.addLine(to: CGPoint(x: 130, y: 50))
            context.stroke(gallows, with: stroke, lineWidth: lw)

            if game.wrongGuesses >= 1 {
                context.stroke(
                    Path(ellipseIn: CGRect(x: 110, y: 50, width: 40, height: 40)),
                    with: stroke,
                    lineWidth: lw
                )
            }
            if game.wrongGuesses >= 2 {
                var body = Path()
                body.move(to: CGPoint(x: 130, y: 90))
                body.addLine(to: CGPoint(x: 130, y: 165))
                context.stroke(body, with: stroke, lineWidth: lw)
            }
            if game.wrongGuesses >= 3 {
                var arm = Path()
                arm.move(to: CGPoint(x: 130, y: 110))
                arm.addLine(to: CGPoint(x: 105, y: 140))
                context.stroke(arm, with: stroke, lineWidth: lw)
            }
            if game.wrongGuesses >= 4 {
                var arm = Path()
                arm.move(to: CGPoint(x: 130, y: 110))
                arm.addLine(to: CGPoint(x: 155, y: 140))
                context.stroke(arm, with: stroke, lineWidth: lw)
            }
            if game.wrongGuesses >= 5 {
                var leg = Path()
                leg.move(to: CGPoint(x: 130, y: 165))
                leg.addLine(to: CGPoint(x: 105, y: 200))
                context.stroke(leg, with: stroke, lineWidth: lw)
            }
            if game.wrongGuesses >= 6 {
                var leg = Path()
                leg.move(to: CGPoint(x: 130, y: 165))
                leg.addLine(to: CGPoint(x: 155, y: 200))
                context.stroke(leg, with: stroke, lineWidth: lw)
            }
        }
        .frame(width: 200, height: 260)
    }

    private var wordView: some View {
        HStack(spacing: 10) {
            ForEach(Array(game.word.enumerated()), id: \.offset) { _, ch in
                VStack(spacing: 4) {
                    Text(game.isRevealed(ch) ? String(ch) : " ")
                        .font(.system(size: 38, weight: .heavy, design: .monospaced))
                        .foregroundColor(missedColor(for: ch))
                    Rectangle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 32, height: 3)
                }
            }
        }
    }

    private func missedColor(for ch: Character) -> Color {
        if game.result == .lost && !game.wasGuessedCorrectly(ch) {
            return .red
        }
        return .white
    }

    private var letterGrid: some View {
        let cols = Array(repeating: GridItem(.fixed(44), spacing: 6), count: 7)
        return LazyVGrid(columns: cols, spacing: 6) {
            ForEach(Self.alphabet, id: \.self) { letter in
                letterButton(letter)
            }
        }
    }

    private func letterButton(_ letter: Character) -> some View {
        let guessed = game.wasGuessed(letter)
        let correct = game.wasGuessedCorrectly(letter)

        return Button(action: { game.guess(letter) }) {
            Text(String(letter))
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .frame(width: 44, height: 38)
                .foregroundColor(textColor(guessed: guessed, correct: correct))
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(buttonBackground(guessed: guessed, correct: correct))
                )
        }
        .buttonStyle(.plain)
        .disabled(guessed || game.result != nil)
    }

    private func buttonBackground(guessed: Bool, correct: Bool) -> Color {
        if !guessed { return Color(white: 0.22) }
        return correct
            ? Color(red: 0.22, green: 0.58, blue: 0.30)
            : Color(red: 0.55, green: 0.18, blue: 0.18)
    }

    private func textColor(guessed: Bool, correct: Bool) -> Color {
        if !guessed { return .white }
        return correct ? .white : Color.white.opacity(0.55)
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            switch game.result {
            case .won:
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").foregroundColor(.yellow)
                    Text("You got it!").fontWeight(.bold)
                }
                .font(.system(size: 28, design: .monospaced))
                .foregroundColor(.white)
            case .lost:
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
                        Text("Hanged!").fontWeight(.bold)
                    }
                    .font(.system(size: 28, design: .monospaced))
                    .foregroundColor(.white)
                    Text("Word was \(game.word)")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
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
