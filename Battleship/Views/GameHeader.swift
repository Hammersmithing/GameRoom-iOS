import SwiftUI

struct GameHeader: View {
    let title: String
    var statusContent: AnyView? = nil
    var onNewGame: () -> Void
    var onExit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onExit) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.bordered)

                Text(title)
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onNewGame) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, statusContent == nil ? 8 : 4)

            if let status = statusContent {
                status
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }

            Divider()
        }
        .background(Color.black.opacity(0.5))
    }
}
