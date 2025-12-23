import SwiftUI

struct WeekStreakView: View {

    let days: [StreakDay]
    @EnvironmentObject private var vm: AnatomyStudyViewModel

    var body: some View {
        HStack() {
            ForEach(days) { day in
                NavigationLink {
                    DayMockScreen(day: day)
                } label: {
                    VStack(spacing: 8) {
                        Text(day.shortName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        DayPill(day: day)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
    }
}

private struct DayPill: View {
    let day: StreakDay

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(backgroundColor)

            // Особый текущий день — “животное”
            if day.isSpecial {
                Text("🦊") // можешь заменить на любое эмодзи/иконку
                    .font(.system(size: 20))
            } else {
                // Состояния по символам (чисто для мока)
                switch day.state {
                case .done:
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 18, height: 18)
                case .missed:
                    Text("✖︎")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                case .current:
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 18, height: 18)
                case .future:
                    EmptyView()
                }
            }
        }
        .frame(width: 44, height: 60)
        .overlay(alignment: .bottom) {
            // Небольшая “полоска” прогресса снизу как на скрине
            if day.state == .done || day.state == .current {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 22, height: 4)
                    .padding(.bottom, 6)
            }
        }
    }

    private var backgroundColor: Color {
        switch day.state {
        case .done:
            return Color(.systemGray5)
        case .current:
            return Color.orange.opacity(0.25)
        case .missed:
            return Color(.systemGray5)
        case .future:
            return Color(.systemGray5)
        }
    }
}
