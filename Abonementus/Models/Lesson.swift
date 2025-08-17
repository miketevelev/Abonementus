import SQLite
import Foundation
import SwiftUI

struct Lesson: Identifiable {
    let id: Int64
    let clientId: Int64
    let subscriptionId: Int64?
    let number: Int  // Добавлено поле для номера урока
    let price: Double
    let createdAt: Date
    var conductedAt: Date?
    var isCompleted: Bool
    
    static let table = Table("lessons")
    static let id = Expression<Int64>("id")
    static let clientId = Expression<Int64>("clientId")
    static let subscriptionId = Expression<Int64?>("subscriptionId")
    static let number = Expression<Int>("number")  // Добавлено поле для номера
    static let price = Expression<Double>("price")
    static let createdAt = Expression<Date>("createdAt")
    static let conductedAt = Expression<Date?>("conductedAt")
    static let isCompleted = Expression<Bool>("isCompleted")
    
    var statusSymbol: String {
        isCompleted ? "X" : "\(number)"
    }
    
    var statusColor: Color {
        isCompleted ? .red : .gray.opacity(0.2)
    }
}
