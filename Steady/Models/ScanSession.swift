import Foundation
import SwiftData

@Model
final class ScanSession {
    @Attribute(.unique) var id: String
    var name: String
    var startDate: Date
    var status: String // "active", "completed", "synced"
    
    init(name: String, status: String = "active") {
        self.id = UUID().uuidString
        self.name = name
        self.startDate = Date()
        self.status = status
    }
}
