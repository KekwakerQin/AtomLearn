import Foundation
import Combine

@MainActor
final class AnatomyStudyViewModel: ObservableObject {

    // MARK: - Published UI State
    @Published var streak: [StreakDay] = []
    @Published var cards: [StudyCard] = []
    @Published var currentIndex: Int = 0

    @Published var isFlipped: Bool = false              // лицо/оборот карточки
    @Published var sessionSeconds: Int = 0              // таймер сессии
    @Published var isTimerRunning: Bool = true

    // MARK: - Progress
    var totalCount: Int { cards.count }
    var currentNumber: Int { min(currentIndex + 1, max(totalCount, 1)) }
    var progressValue: Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentNumber) / Double(totalCount)
    }

    // MARK: - Private
    private var timerCancellable: AnyCancellable?

    // MARK: - Init
    init() {
        loadMock()
        startTimer()
    }

    deinit {
        timerCancellable?.cancel()
    }

    // MARK: - Mock Data
    func loadMock() {
        // Мок-карточки (можешь расширить)
        cards = [
            StudyCard(deckTitle: "Анатомия человека",
                      term: "Синапсис",
                      answer: "Синапс — место контакта между нейронами (или нейроном и мышечной клеткой), через которое передаётся сигнал."),
            StudyCard(deckTitle: "Анатомия человека",
                      term: "Нейрон",
                      answer: "Нейрон — нервная клетка, которая принимает, обрабатывает и передаёт информацию."),
            StudyCard(deckTitle: "Анатомия человека",
                      term: "Аксон",
                      answer: "Аксон — длинный отросток нейрона, по которому импульс идёт от тела клетки к другим клеткам."),
            StudyCard(deckTitle: "Анатомия человека",
                      term: "Дендрит",
                      answer: "Дендриты — короткие отростки нейрона, которые принимают сигналы от других клеток.")
        ]

        // Мок-неделя: done / current / missed / future
        streak = [
            StreakDay(shortName: "Пн", state: .done,    isSpecial: false),
            StreakDay(shortName: "Вт", state: .done,    isSpecial: false),
            StreakDay(shortName: "Ср", state: .done,    isSpecial: false),
            StreakDay(shortName: "Чт", state: .current, isSpecial: true),   // "животное"
            StreakDay(shortName: "Пт", state: .future,  isSpecial: false),
            StreakDay(shortName: "Сб", state: .missed,  isSpecial: false),
            StreakDay(shortName: "Вс", state: .future,  isSpecial: false)
        ]
    }

    // MARK: - Timer
    func startTimer() {
        timerCancellable?.cancel()
        isTimerRunning = true

        timerCancellable = Timer
            .publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard self.isTimerRunning else { return }
                self.sessionSeconds += 1
            }
    }

    func toggleTimer() {
        isTimerRunning.toggle()
    }

    // MARK: - Card Actions
    func flipCard() {
        isFlipped.toggle()
    }
    
    func gradeAndGoNext(label: String) {
        // Пока логики FSRS/SRS нет — просто шаблон/хук:
        // можно потом писать в лог: term + label + sessionSeconds + timestamp
        // print("GRADE:", label, "TERM:", currentCard?.term ?? "-")

        goNext()
    }

    func goNext() {
        guard totalCount > 0 else { return }

        isFlipped = false

        if currentIndex < totalCount - 1 {
            currentIndex += 1
        } else {
            currentIndex = 0
        }
    }
    
    var currentCard: StudyCard? {
        guard cards.indices.contains(currentIndex) else { return nil }
        return cards[currentIndex]
    }
}
