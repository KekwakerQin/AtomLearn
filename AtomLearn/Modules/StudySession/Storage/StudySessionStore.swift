import Foundation
import CoreData

@objc(StudySessionEntity)
final class StudySessionEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var boardId: String
    @NSManaged var stateData: Data
    @NSManaged var updatedAt: Date
    @NSManaged var isCompleted: Bool
}

extension StudySessionEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<StudySessionEntity> {
        NSFetchRequest<StudySessionEntity>(entityName: "StudySessionEntity")
    }
}

final class StudySessionStore {
    static let shared = StudySessionStore()

    private let container: NSPersistentContainer

    private init() {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "StudySessionModel", managedObjectModel: model)

        let baseURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        let storeURL = baseURL.appendingPathComponent("StudySessionModel.sqlite")

        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error {
                print("[StudySessionStore] Failed to load store:", error.localizedDescription)
            }
        }
    }

    func loadActiveSession(boardId: String) -> StudySessionState? {
        let context = container.viewContext
        let request = StudySessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "boardId == %@ AND isCompleted == NO", boardId)
        request.fetchLimit = 1

        guard let result = try? context.fetch(request),
              let entity = result.first else { return nil }
        return decode(entity.stateData)
    }

    func save(state: StudySessionState) {
        let context = container.viewContext
        let request = StudySessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "boardId == %@", state.boardId)
        request.fetchLimit = 1

        let entity: StudySessionEntity
        if let result = try? context.fetch(request),
           let existing = result.first {
            entity = existing
        } else {
            entity = StudySessionEntity(context: context)
            entity.id = UUID()
        }

        entity.boardId = state.boardId
        entity.stateData = encode(state)
        entity.updatedAt = Date()
        entity.isCompleted = state.isCompleted

        do {
            try context.save()
        } catch {
            print("[StudySessionStore] Failed to save:", error.localizedDescription)
        }
    }

    func deleteSession(boardId: String) {
        let context = container.viewContext
        let request = StudySessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "boardId == %@", boardId)

        if let items = try? context.fetch(request) {
            for item in items {
                context.delete(item)
            }
            try? context.save()
        }
    }

    func fetchActiveSessions() -> [StudySessionState] {
        let context = container.viewContext
        let request = StudySessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

        guard let items = try? context.fetch(request) else { return [] }
        return items.compactMap { decode($0.stateData) }
    }

    private func encode(_ state: StudySessionState) -> Data {
        (try? JSONEncoder().encode(state)) ?? Data()
    }

    private func decode(_ data: Data) -> StudySessionState? {
        try? JSONDecoder().decode(StudySessionState.self, from: data)
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "StudySessionEntity"
        entity.managedObjectClassName = NSStringFromClass(StudySessionEntity.self)

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false

        let boardIdAttr = NSAttributeDescription()
        boardIdAttr.name = "boardId"
        boardIdAttr.attributeType = .stringAttributeType
        boardIdAttr.isOptional = false

        let stateAttr = NSAttributeDescription()
        stateAttr.name = "stateData"
        stateAttr.attributeType = .binaryDataAttributeType
        stateAttr.allowsExternalBinaryDataStorage = true
        stateAttr.isOptional = false

        let updatedAttr = NSAttributeDescription()
        updatedAttr.name = "updatedAt"
        updatedAttr.attributeType = .dateAttributeType
        updatedAttr.isOptional = false

        let completedAttr = NSAttributeDescription()
        completedAttr.name = "isCompleted"
        completedAttr.attributeType = .booleanAttributeType
        completedAttr.isOptional = false

        entity.properties = [idAttr, boardIdAttr, stateAttr, updatedAttr, completedAttr]
        model.entities = [entity]
        return model
    }
}
