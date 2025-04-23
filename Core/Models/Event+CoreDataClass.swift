import Foundation
import CoreData

@objc(Event)
public class Event: NSManagedObject {
    func addMedia(_ media: Media) {
        addToMedia(media)
    }
    
    func addSource(_ source: Source) {
        addToSources(source)
    }
}

