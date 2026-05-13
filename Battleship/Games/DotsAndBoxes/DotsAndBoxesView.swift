import SwiftUI

struct DotsAndBoxesView: View {
    @StateObject private var game = DotsAndBoxesGame()
    var onExit: () -> Void = {}

    private let gap: CGFloat = 70
    private let dotSize: CGFloat = 14
    private let lineThickness: CGFloat = 6
    private let hitThickness: CGFloat = 22

    private var n: Int { DotsAndBoxesGame.size }
    private var boardSide: CGFloat { CGFloat(n) * gap + dotSize }

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "DOTS AND BOXES",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset() },
                onExit: onExit
            )

            VStack(spacing: 0) {
                Spacer()
                board
                Spacer()
                if game.result != nil {
                    resultBanner.padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        Group {
            if game.result == nil {
                HStack(spacing: 6) {
                    Text("Turn:").foregroundColor(.gray)
                    Circle()
                        .fill(playerColor(game.currentTurn))
                        .frame(width: 14, height: 14)
                    Text(game.currentTurn.name)
                        .foregroundColor(playerColor(game.currentTurn))
                        .fontWeight(.bold)
                    Text("·").foregroundColor(.gray)
                    Text("R \(game.count(.red))")
                        .foregroundColor(playerColor(.red))
                    Text("B \(game.count(.blue))")
                        .foregroundColor(playerColor(.blue))
                }
            } else {
                EmptyView()
            }
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
    }

    private var board: some View {
        ZStack(alignment: .topLeading) {
            Color.clear

            ForEach(0..<n, id: \.self) { r in
                ForEach(0..<n, id: \.self) { c in
                    if let owner = game.boxes[r][c] {
                        boxFill(r: r, c: c, owner: owner)
                    }
                }
            }

            ForEach(0...n, id: \.self) { r in
                ForEach(0..<n, id: \.self) { c in
                    horizontalLine(row: r, col: c)
                }
            }

            ForEach(0..<n, id: \.self) { r in
                ForEach(0...n, id: \.self) { c in
                    verticalLine(row: r, col: c)
                }
            }

            ForEach(0...n, id: \.self) { r in
                ForEach(0...n, id: \.self) { c in
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: dotSize, height: dotSize)
                        .position(dotCenter(r: r, c: c))
                }
            }
        }
        .frame(width: boardSide, height: boardSide)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.13))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(white: 0.3), lineWidth: 2)
        )
    }

    private func boxFill(r: Int, c: Int, owner: DotsPlayer) -> some View {
        let center = CGPoint(
            x: CGFloat(c) * gap + gap / 2 + dotSize / 2,
            y: CGFloat(r) * gap + gap / 2 + dotSize / 2
        )
        return ZStack {
            Rectangle()
                .fill(playerColor(owner).opacity(0.30))
                .frame(width: gap - dotSize, height: gap - dotSize)
            Text(owner.initial)
                .font(.system(size: 22, weight: .heavy, design: .monospaced))
                .foregroundColor(playerColor(owner))
        }
        .position(center)
    }

    private func horizontalLine(row: Int, col: Int) -> some View {
        let drawn = game.horizontalLines[row][col]
        let center = CGPoint(
            x: CGFloat(col) * gap + gap / 2 + dotSize / 2,
            y: CGFloat(row) * gap + dotSize / 2
        )
        return Button(action: { game.draw(.horizontal, row: row, col: col) }) {
            ZStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: gap - dotSize, height: hitThickness)
                    .contentShape(Rectangle())
                Rectangle()
                    .fill(drawn.map { playerColor($0) } ?? Color.white.opacity(0.06))
                    .frame(width: gap - dotSize, height: drawn == nil ? 2 : lineThickness)
            }
        }
        .buttonStyle(.plain)
        .disabled(drawn != nil || game.result != nil)
        .position(center)
    }

    private func verticalLine(row: Int, col: Int) -> some View {
        let drawn = game.verticalLines[row][col]
        let center = CGPoint(
            x: CGFloat(col) * gap + dotSize / 2,
            y: CGFloat(row) * gap + gap / 2 + dotSize / 2
        )
        return Button(action: { game.draw(.vertical, row: row, col: col) }) {
            ZStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: hitThickness, height: gap - dotSize)
                    .contentShape(Rectangle())
                Rectangle()
                    .fill(drawn.map { playerColor($0) } ?? Color.white.opacity(0.06))
                    .frame(width: drawn == nil ? 2 : lineThickness, height: gap - dotSize)
            }
        }
        .buttonStyle(.plain)
        .disabled(drawn != nil || game.result != nil)
        .position(center)
    }

    private func dotCenter(r: Int, c: Int) -> CGPoint {
        CGPoint(
            x: CGFloat(c) * gap + dotSize / 2,
            y: CGFloat(r) * gap + dotSize / 2
        )
    }

    private func playerColor(_ p: DotsPlayer) -> Color {
        p == .red
            ? Color(red: 0.95, green: 0.25, blue: 0.25)
            : Color(red: 0.30, green: 0.55, blue: 0.95)
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            switch game.result {
            case .win(let p):
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").foregroundColor(.yellow)
                    Circle()
                        .fill(playerColor(p))
                        .frame(width: 20, height: 20)
                    Text("\(p.name) Wins!").fontWeight(.bold)
                }
                .font(.system(size: 28, design: .monospaced))
                .foregroundColor(.white)
                Text("\(game.count(.red)) – \(game.count(.blue))")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
            case .draw:
                Text("Draw — \(game.count(.red)) all")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
            case .none:
                EmptyView()
            }

            Button("Play Again") { game.reset() }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
