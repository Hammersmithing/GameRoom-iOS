import SwiftUI

struct MastermindView: View {
    @StateObject private var game = MastermindGame()
    var onExit: () -> Void = {}

    private let pegSize: CGFloat = 32
    private let feedbackSize: CGFloat = 10

    private var naturalWidth: CGFloat { 360 }
    private var naturalHeight: CGFloat {
        pegSize + 16 + 16 + CGFloat(MastermindGame.maxGuesses) * (pegSize + 6) + pegSize + 16 + 60 + 16
    }

    private static let palette: [Color] = [
        Color(red: 0.95, green: 0.25, blue: 0.30),
        Color(red: 0.95, green: 0.55, blue: 0.20),
        Color(red: 0.95, green: 0.85, blue: 0.20),
        Color(red: 0.30, green: 0.80, blue: 0.40),
        Color(red: 0.25, green: 0.55, blue: 0.95),
        Color(red: 0.65, green: 0.30, blue: 0.85)
    ]

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "MASTERMIND",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset() },
                onExit: onExit
            )

            ScaledFit(width: naturalWidth, height: naturalHeight) {
                VStack(spacing: 16) {
                    hiddenCodeRow
                    Divider().background(Color(white: 0.3))
                    guessHistory
                    activeRow
                    colorPicker
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
    }

    private var statusContent: some View {
        HStack(spacing: 8) {
            Text("Guess:").foregroundColor(.gray)
            Text("\(game.guesses.count) / \(MastermindGame.maxGuesses)")
                .foregroundColor(.white)
                .fontWeight(.bold)
            Text("·").foregroundColor(.gray)
            Text("● = right peg, right spot · ○ = right peg, wrong spot")
                .foregroundColor(.gray)
        }
        .font(.system(size: 12, weight: .medium, design: .monospaced))
    }

    private var hiddenCodeRow: some View {
        HStack(spacing: 12) {
            Text("CODE")
                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(0..<MastermindGame.positions, id: \.self) { i in
                    if game.result != nil {
                        peg(color: Self.palette[game.code[i]])
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color(white: 0.15))
                                .frame(width: pegSize, height: pegSize)
                            Image(systemName: "questionmark")
                                .foregroundColor(.gray)
                                .font(.system(size: 14, weight: .heavy))
                        }
                    }
                }
            }
            Spacer()
        }
    }

    private var guessHistory: some View {
        VStack(spacing: 6) {
            ForEach(0..<game.guesses.count, id: \.self) { i in
                guessRow(guess: game.guesses[i], feedback: game.feedbacks[i])
            }
        }
    }

    private func guessRow(guess: [Int], feedback: (black: Int, white: Int)) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<MastermindGame.positions, id: \.self) { i in
                    peg(color: Self.palette[guess[i]])
                }
            }
            feedbackPegs(black: feedback.black, white: feedback.white)
            Spacer()
        }
    }

    private func feedbackPegs(black: Int, white: Int) -> some View {
        let total = MastermindGame.positions
        return HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(feedbackFill(index: i, black: black, white: white))
                    .frame(width: feedbackSize, height: feedbackSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
            }
        }
    }

    private func feedbackFill(index: Int, black: Int, white: Int) -> Color {
        if index < black { return .black }
        if index < black + white { return .white }
        return Color(white: 0.18)
    }

    private var activeRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<MastermindGame.positions, id: \.self) { i in
                    Button(action: { game.clearSlot(i) }) {
                        if let c = game.current[i] {
                            peg(color: Self.palette[c])
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color(white: 0.07))
                                    .frame(width: pegSize, height: pegSize)
                                Circle()
                                    .stroke(Color(white: 0.35), lineWidth: 1.5)
                                    .frame(width: pegSize, height: pegSize)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(game.result != nil)
                }
            }

            Button(action: { game.submit() }) {
                Text("Submit")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .frame(width: 100, height: 32)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(game.canSubmit ? Color.blue : Color(white: 0.22))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!game.canSubmit)

            Spacer()
        }
    }

    private var colorPicker: some View {
        VStack(spacing: 6) {
            Text("PICK A COLOR")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(.gray)
            HStack(spacing: 10) {
                ForEach(0..<MastermindGame.colorCount, id: \.self) { i in
                    Button(action: { game.place(color: i) }) {
                        peg(color: Self.palette[i])
                    }
                    .buttonStyle(.plain)
                    .disabled(game.result != nil)
                }
            }
        }
    }

    private func peg(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: pegSize, height: pegSize)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            switch game.result {
            case .won(let n):
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").foregroundColor(.yellow)
                    Text("Cracked it in \(n)!").fontWeight(.bold)
                }
                .font(.system(size: 24, design: .monospaced))
                .foregroundColor(.white)
            case .lost:
                HStack(spacing: 8) {
                    Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
                    Text("Code unbroken").fontWeight(.bold)
                }
                .font(.system(size: 24, design: .monospaced))
                .foregroundColor(.white)
            case .none:
                EmptyView()
            }

            Button("New Code") { game.reset() }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
