import SQLite
import Foundation

struct Client {
    let id: Int64
    var firstName: String
    var lastName: String?
    var phone: String?
    var telegram: String?
    var email: String?
    var additionalInfo: String?
    let createdAt: Date
    var updatedAt: Date
    
    static let table = Table("clients")
    static let id = Expression<Int64>("id")
    static let firstName = Expression<String>("firstName")
    static let lastName = Expression<String?>("lastName")
    static let phone = Expression<String?>("phone")
    static let telegram = Expression<String?>("telegram")
    static let email = Expression<String?>("email")
    static let additionalInfo = Expression<String?>("additionalInfo")
    static let createdAt = Expression<Date>("createdAt")
    static let updatedAt = Expression<Date>("updatedAt")
    
    var fullName: String {
        if let lastName = lastName {
            return "\(firstName) \(lastName)"
        } else {
            return firstName
        }
    }
}
