import SQLite
import Foundation

struct ExtraIncome: Identifiable {
    let id: Int64
    let categoryId: Int64
    var amount: Double
    var receivedAt: Date
    let createdAt: Date
    var updatedAt: Date
    
    static let table = Table("extra_incomes")
    static let id = Expression<Int64>("id")
    static let categoryId = Expression<Int64>("categoryId")
    static let amount = Expression<Double>("amount")
    static let receivedAt = Expression<Date>("receivedAt")
    static let createdAt = Expression<Date>("createdAt")
    static let updatedAt = Expression<Date>("updatedAt")
}


