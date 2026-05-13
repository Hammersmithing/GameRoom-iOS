import SwiftUI

struct YahtzeeView: View {
    @StateObject private var game = YahtzeeGame()
    var onExit: () -> Void = {}

    private let dieSize: CGFloat = 64

    private var naturalWidth: CGFloat { 544 }
    private var naturalHeight: CGFloat {
        let rows: CGFloat = 13 * 28
        return dieSize + 56 + rows + 116
    }

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "YAHTZEE",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset() },
                onExit: onExit
            )

            ScaledFit(width: naturalWidth, height: naturalHeight) {
                VStack(spacing: 18) {
                    diceRow
                    rollButton
                    scoreSheet
                }
            }
            .frame(maxHeight: .infinity)
            if game.isComplete {
                resultBanner.padding(.bottom, 24)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.16, blue: 0.10),
                         Color(red: 0.02, green: 0.06, blue: 0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var statusContent: some View {
        HStack(spacing: 8) {
            Text("Turn:").foregroundColor(.gray)
            Text("\(min(game.turn, YahtzeeGame.totalTurns)) / \(YahtzeeGame.totalTurns)")
                .foregroundColor(.white).fontWeight(.bold)
            Text("·").foregroundColor(.gray)
            Text("Total:").foregroundColor(.gray)
            Text("\(game.grandTotal)")
                .foregroundColor(.yellow).fontWeight(.bold)
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
    }

    private var diceRow: some View {
        HStack(spacing: 12) {
            ForEach(0..<YahtzeeGame.diceCount, id: \.self) { i in
                dieView(index: i)
            }
        }
    }

    private func dieView(index: Int) -> some View {
        let value = game.dice[index]
        let isHeld = game.held[index]
        return Button(action: { game.toggleHold(index) }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(game.hasRolled ? Color.white : Color(white: 0.45))
                    .frame(width: dieSize, height: dieSize)
                Image(systemName: "die.face.\(value).fill")
                    .font(.system(size: 44, weight: .black))
                    .foregroundColor(.black)
                if isHeld {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.yellow, lineWidth: 4)
                        .frame(width: dieSize, height: dieSize)
                }
            }
            .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!game.hasRolled || game.rollsLeft == 0 || game.isComplete)
        .opacity(game.hasRolled ? 1.0 : 0.7)
    }

    private var rollButton: some View {
        Button(action: { game.roll() }) {
            Text(game.rollsLeft == YahtzeeGame.maxRolls ? "Roll" : "Roll (\(game.rollsLeft) left)")
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .frame(width: 200, height: 40)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(game.rollsLeft > 0 && !game.isComplete
                              ? Color(red: 0.20, green: 0.65, blue: 0.30)
                              : Color(white: 0.22))
                )
        }
        .buttonStyle(.plain)
        .disabled(game.rollsLeft == 0 || game.isComplete)
    }

    private var scoreSheet: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                sectionHeader("UPPER")
                ForEach(YahtzeeCategory.upper) { cat in
                    scoreRow(category: cat)
                }
                Divider().background(Color(white: 0.3))
                summaryRow(label: "Subtotal", value: "\(game.upperTotal)")
                summaryRow(label: "Bonus (≥63)", value: "\(game.upperBonus)")
                summaryRow(label: "Upper", value: "\(game.upperTotal + game.upperBonus)", emphasize: true)
            }
            .frame(width: 240)

            VStack(alignment: .leading, spacing: 4) {
                sectionHeader("LOWER")
                ForEach(YahtzeeCategory.lower) { cat in
                    scoreRow(category: cat)
                }
                Divider().background(Color(white: 0.3))
                summaryRow(label: "Lower", value: "\(game.lowerTotal)", emphasize: true)
                Spacer().frame(height: 8)
                summaryRow(label: "TOTAL", value: "\(game.grandTotal)", emphasize: true)
            }
            .frame(width: 240)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .monospaced))
            .foregroundColor(.gray)
            .padding(.bottom, 4)
    }

    private func scoreRow(category: YahtzeeCategory) -> some View {
        let committed = game.scores[category]
        let preview = game.potentialScore(for: category)
        let canCommit = committed == nil && game.hasRolled && !game.isComplete

        return Button(action: { game.commit(category) }) {
            HStack {
                Text(category.label)
                    .foregroundColor(committed == nil ? .white : .gray)
                Spacer()
                if let v = committed {
                    Text("\(v)")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                } else if let p = preview {
                    Text("\(p)")
                        .foregroundColor(p > 0 ? .yellow : .gray)
                } else {
                    Text("—").foregroundColor(.gray.opacity(0.5))
                }
            }
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(canCommit ? Color(white: 0.16) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canCommit)
    }

    private func summaryRow(label: String, value: String, emphasize: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
        }
        .font(.system(size: emphasize ? 14 : 13, weight: emphasize ? .heavy : .medium, design: .monospaced))
        .foregroundColor(emphasize ? .yellow : .gray)
        .padding(.horizontal, 8)
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill").foregroundColor(.yellow)
                Text("Final score: \(game.grandTotal)").fontWeight(.bold)
            }
            .font(.system(size: 24, design: .monospaced))
            .foregroundColor(.white)
            Button("New Game") { game.reset() }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
