import SwiftUI

struct AnatomyStudyScreen: View {

    @StateObject private var vm = AnatomyStudyViewModel()

    var body: some View {
        
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            VStack {
                // MARK: - Header
                header
                
                // MARK: - Week streak row
                WeekStreakView(days: vm.streak)
                
                // MARK: - Progress + Timer
                progressRow
                
                Spacer(minLength: 8)
                // MARK: - Card (flip)
                if let card = vm.currentCard {
                    FlipCardView(
                        isFlipped: vm.isFlipped,
                        front: { cardFront(card: card) },
                        back: { cardBack(card: card) }
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: Color.black.opacity(0.06), radius: 20, y: 10)
                } else {
                    emptyState
                }
                
                // MARK: - Grade buttons
                GradeButtonsView(
                    onDontRemember: { vm.gradeAndGoNext(label: "Не помню") },
                    onHard: { vm.gradeAndGoNext(label: "Сложно") },
                    onEasy: { vm.gradeAndGoNext(label: "Легко") }
                )
                
                Spacer(minLength: 12)
                
            }
                .padding(.top, 6)
                .padding(.bottom, 32)
        }
        .navigationBarHidden(true)
        
        .environmentObject(vm) // удобно, чтобы WeekStreakView пушил мок-скрин
    }

    // MARK: - Header View
    private var header: some View {
        HStack {
            Button {
                // в реальном приложении: dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40, alignment: .center)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text("Анатомия …")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Spacer()

            // Заглушка симметрии справа (чтобы заголовок был по центру)
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Progress Row
    private var progressRow: some View {
        HStack(spacing: 12) {
            Text("\(vm.currentNumber) / \(max(vm.totalCount, 1))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            ProgressView(value: vm.progressValue)
                .tint(.green)
                .scaleEffect(x: 1, y: 1.15, anchor: .center)

            Spacer()

            // Таймер сессии (просто UI)
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(TimeFormatters.mmss(vm.sessionSeconds))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Тап по таймеру: пауза/плей — удобно для дебага
                vm.toggleTimer()
            }
            .opacity(vm.isTimerRunning ? 1.0 : 0.55)
        }
        .padding(.top, 4)
        .padding(.horizontal, 32)
    }

    // MARK: - Front Card
    private func cardFront(card: StudyCard) -> some View {
        CardShell {
            VStack(spacing: 18) {
                HStack {
                    Text(card.deckTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Кнопка "?"
                    Button { } label: {
                        Image(systemName: "questionmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.blue)
                            .frame(width: 34, height: 34)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 5)
                    }
                }

                Spacer()

                Text(card.term)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Spacer()

                Button {
                    vm.flipCard()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.2.circlepath")
                        Text("Проверить себя")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                }
                .padding(.bottom, 6)
            }
        }
    }

    // MARK: - Back Card
    private func cardBack(card: StudyCard) -> some View {
        CardShell {
            VStack(spacing: 18) {
                HStack {
                    Text("Ответ")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Spacer()

                Text(card.answer)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)

                Spacer()

                Button {
                    vm.flipCard()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.uturn.left")
                        Text("Вернуться к термину")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                }
                .padding(.bottom, 6)
            }
        }
    }

    // MARK: - Empty state
    private var emptyState: some View {
        Text("Нет карточек")
            .foregroundStyle(.secondary)
            .padding()
    }
    
}

// MARK: - Card shell (одинаковая “рамка”)
private struct CardShell<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}
