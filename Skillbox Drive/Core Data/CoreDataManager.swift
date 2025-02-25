import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "PublishedFilesModel")
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Ошибка загрузки Core Data store: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Ошибка сохранения контекста: \(error)")
            }
        }
    }
}

extension CoreDataManager {
    func savePublishedFiles(_ files: [PublishedFile]) {
        let context = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PublishedFileEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
        } catch {
            print("Ошибка удаления старого кэша: \(error)")
        }
        
        for file in files {
            if let entity = NSEntityDescription.insertNewObject(forEntityName: "PublishedFileEntity", into: context) as? PublishedFileEntity {
                entity.name = file.name
                entity.file = file.file
                entity.preview = file.preview
                entity.type = file.type
                entity.mediaType = file.mediaType
                entity.created = file.created
                if let size = file.size {
                    entity.size = Int64(size)
                }
            }
        }
        
        do {
            try context.save()
            print("Данные успешно сохранены в кэше")
        } catch {
            print("Ошибка сохранения в кэше: \(error)")
        }
    }
}

extension CoreDataManager {
    func fetchPublishedFiles() -> [PublishedFile] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<PublishedFileEntity> = PublishedFileEntity.fetchRequest()
        do {
            let entities = try context.fetch(fetchRequest)
            let files = entities.map { entity in
                PublishedFile(
                    size: Int(entity.size),
                    name: entity.name ?? "",
                    created: entity.created ?? "",
                    file: entity.file,
                    preview: entity.preview,
                    path: entity.path ?? "",
                    type: entity.type,
                    mediaType: entity.mediaType ?? "",
                    mimeType: entity.mimeType,
                    publicURL: entity.publicURL
                )
            }
            return files
        } catch {
            print("Ошибка извлечения данных из кэша: \(error)")
            return []
        }
    }
}

extension CoreDataManager {
    func clearCache() {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PublishedFileEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("Кеш успешно очищен")
        } catch {
            print("Ошибка очистки кеша: \(error)")
        }
    }
}
