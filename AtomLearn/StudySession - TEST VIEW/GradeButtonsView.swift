import SwiftUI

struct GradeButtonsView: View {

    let onDontRemember: () -> Void
    let onHard: () -> Void
    let onEasy: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            GradeButton(title: "Не помню", fill: .red.opacity(0.18), action: onDontRemember)
            GradeButton(title: "Сложно", fill: .yellow.opacity(0.25), action: onHard)
            GradeButton(title: "Легко", fill: .green.opacity(0.20), action: onEasy)
        }
        .padding(.top, 6)
    }
}

private struct GradeButton: View {
    let title: String
    let fill: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.55))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(fill)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 6)
    }
}
