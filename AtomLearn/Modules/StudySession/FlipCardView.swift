import SwiftUI

/// Универсальная "переворачивающаяся" карточка
struct FlipCardView<Front: View, Back: View>: View {

    let isFlipped: Bool
    let front: () -> Front
    let back: () -> Back

    var body: some View {
        ZStack {
            front()
                .frame(maxWidth: .infinity)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )

            back()
                .frame(maxWidth: .infinity)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(maxWidth: .infinity)
        // перспектива — чтобы выглядело "объёмно"
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: isFlipped)
    }
}
