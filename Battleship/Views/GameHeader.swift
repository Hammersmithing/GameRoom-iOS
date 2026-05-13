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

/// Wraps a fixed-size child and uniformly scales it down to fit the available space.
/// Hit-testing follows the visual transform, so taps land on the rendered cells.
struct ScaledFit<Content: View>: View {
    let naturalWidth: CGFloat
    let naturalHeight: CGFloat
    let horizontalInset: CGFloat
    let content: () -> Content

    init(width: CGFloat,
         height: CGFloat,
         horizontalInset: CGFloat = 12,
         @ViewBuilder content: @escaping () -> Content) {
        self.naturalWidth = width
        self.naturalHeight = height
        self.horizontalInset = horizontalInset
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            let availW = max(0, geo.size.width - horizontalInset * 2)
            let availH = max(0, geo.size.height)
            let scale = min(1, min(availW / naturalWidth, availH / naturalHeight))
            content()
                .frame(width: naturalWidth, height: naturalHeight)
                .scaleEffect(scale, anchor: .center)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
    }
}
