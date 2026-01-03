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

    func savePublishedFiles(_ files: [PublishedFile], for screenType: String) {
        let context = persistentContainer.viewContext
        
        context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PublishedFileEntity")
            fetchRequest.predicate = NSPredicate(format: "screenType == %@", screenType)
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Ошибка удаления старого кэша для \(screenType): \(error)")
            }

            for file in files {
                guard let entity = NSEntityDescription.insertNewObject(forEntityName: "PublishedFileEntity", into: context) as? PublishedFileEntity else { continue }
                
                entity.name = file.name ?? ""
                entity.file = file.file
                entity.preview = file.preview
                entity.type = file.type
                entity.mediaType = file.mediaType
                entity.created = file.created
                entity.path = file.path
                entity.mimeType = file.mimeType
                entity.publicURL = file.publicURL
                if let size = file.size {
                    entity.size = Int32(size)
                }
                
                entity.screenType = screenType
            }
            
            do {
                try context.save()
                print("Данные успешно сохранены в кэше для \(screenType)")
            } catch {
                print("Ошибка сохранения в кэше для \(screenType): \(error)")
            }
        }
    }
}


extension CoreDataManager {
    
    func fetchPublishedFiles(for screenType: String) -> [PublishedFile] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<PublishedFileEntity> = PublishedFileEntity.fetchRequest()
        
        if screenType.lowercased() != "all" {
            fetchRequest.predicate = NSPredicate(format: "screenType == %@", screenType)
        }
        
        do {
            let entities = try context.fetch(fetchRequest)
            let files = entities.map { entity -> PublishedFile in
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
                    publicURL: entity.publicURL,
                    embedded: nil
                )
            }
            return files
        } catch {
            print("Ошибка извлечения данных (\(screenType)): \(error)")
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
            print("Кеш успешно очищен (все экраны)")
        } catch {
            print("Ошибка очистки кеша: \(error)")
        }
    }
}


