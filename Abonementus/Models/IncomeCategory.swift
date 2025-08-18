import SQLite
import Foundation

struct IncomeCategory: Identifiable {
    let id: Int64
    var name: String
    
    static let table = Table("income_categories")
    static let id = Expression<Int64>("id")
    static let name = Expression<String>("name")
}


