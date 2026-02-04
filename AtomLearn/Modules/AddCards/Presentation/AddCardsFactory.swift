import UIKit

enum AddCardsFactory {
    private static var cachedAI: [String: AICreateCardsViewController] = [:]
    private static var cachedImport: [String: ImportCreateCardsViewController] = [:]

    static func make(boardId: String, boardTitle: String, user: AppUser) -> AddCardsViewController {
        let addVM = AddCardsViewModel(boardId: boardId, user: user)

        let manualVC: () -> UIViewController = {
            let repository = ManuallyCreateCardsRepository()
            let service = ManuallyCreateCardsService(repository: repository)
            let manualVM = ManuallyCreateCardsViewModel(
                boardId: boardId,
                ownerId: user.uid,
                service: service
            )
            return ManuallyCreateCardsViewController(viewModel: manualVM)
        }

        let aiVC: () -> UIViewController = {
            if let cached = cachedAI[boardId], cached.hasCards {
                return cached
            }
            let aiVM = AICreateCardsViewModel(
                boardId: boardId,
                boardTitle: boardTitle,
                ownerId: user.uid
            )
            let vc = AICreateCardsViewController(viewModel: aiVM)
            cachedAI[boardId] = vc
            return vc
        }

        let importVC: () -> UIViewController = {
            if let cached = cachedImport[boardId], cached.hasCards {
                return cached
            }
            let importVM = ImportCreateCardsViewModel(
                boardId: boardId,
                boardTitle: boardTitle,
                ownerId: user.uid
            )
            let vc = ImportCreateCardsViewController(viewModel: importVM)
            cachedImport[boardId] = vc
            return vc
        }

        return AddCardsViewController(
            viewModel: addVM,
            makeManualVC: manualVC,
            makeAIVC: aiVC,
            makeImportVC: importVC
        )
    }
}
