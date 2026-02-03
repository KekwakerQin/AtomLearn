import UIKit

enum AddCardsFactory {
    static func make(boardId: String, user: AppUser) -> AddCardsViewController {
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
            let aiVM = AICreateCardsViewModel(
                boardId: boardId,
                ownerId: user.uid
            )
            return AICreateCardsViewController(viewModel: aiVM)
        }

        let importVC: () -> UIViewController = {
            let importVM = ImportCreateCardsViewModel(
                boardId: boardId,
                ownerId: user.uid
            )
            return ImportCreateCardsViewController(viewModel: importVM)
        }

        return AddCardsViewController(
            viewModel: addVM,
            makeManualVC: manualVC,
            makeAIVC: aiVC,
            makeImportVC: importVC
        )
    }
}
