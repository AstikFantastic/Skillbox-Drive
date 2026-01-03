import Foundation
import CoreData


extension PublishedFileEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PublishedFileEntity> {
        return NSFetchRequest<PublishedFileEntity>(entityName: "PublishedFileEntity")
    }

    @NSManaged public var created: String?
    @NSManaged public var file: String?
    @NSManaged public var mediaType: String?
    @NSManaged public var mimeType: String?
    @NSManaged public var name: String?
    @NSManaged public var path: String?
    @NSManaged public var preview: String?
    @NSManaged public var publicURL: String?
    @NSManaged public var size: Int32?
    @NSManaged public var type: String?
    @NSManaged public var screenType: String?

}
