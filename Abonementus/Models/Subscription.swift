import SQLite
import Foundation

struct Subscription: Identifiable {
    let id: Int64
    let clientId: Int64
    let lessonCount: Int
    let totalPrice: Double
    let createdAt: Date
    var closedAt: Date?
    var isActive: Bool
    
    static let table = Table("subscriptions")
    static let id = Expression<Int64>("id")
    static let clientId = Expression<Int64>("clientId")
    static let lessonCount = Expression<Int>("lessonCount")
    static let totalPrice = Expression<Double>("totalPrice")
    static let createdAt = Expression<Date>("createdAt")
    static let closedAt = Expression<Date?>("closedAt")
    static let isActive = Expression<Bool>("isActive")
    
    var isExpired: Bool {
        guard let closedAt = closedAt else { return false }
        return closedAt < Date()
    }
    
    var progressDescription: String {
        "\(completedLessonsCount)/\(lessonCount)"
    }
    
    // Status for display purposes
    var statusTag: String {
        if !isActive {
            return "Finished" // Finished (regardless of expiration)
        } else if isExpired {
            return "Expired" // Expired but still active
        } else {
            return "Active" // Active and not expired
        }
    }
    
    var statusColor: String {
        if !isActive {
            return "gray" // Finished - always gray
        } else if isExpired {
            return "orange" // Expired - orange
        } else {
            return "blue" // Active - blue
        }
    }
    
    // Это вычисляемое свойство должно быть заполнено извне
    var completedLessonsCount: Int = 0
    var lessons: [Lesson] = []  // Уроки будут добавляться отдельно
}
