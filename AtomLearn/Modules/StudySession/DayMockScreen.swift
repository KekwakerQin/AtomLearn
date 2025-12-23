import SwiftUI

struct DayMockScreen: View {
    let day: StreakDay
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Text("День: \(day.shortName)")
                        .font(.headline)

                    Spacer()

                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

                Spacer()

                Text("Мок-экран\nдля дня недели")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("Позже сюда можно повесить статистику, streak, награды и т.д.")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Назад")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: Color.black.opacity(0.06), radius: 14, y: 10)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
