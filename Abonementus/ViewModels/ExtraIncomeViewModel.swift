import SQLite
import Foundation

class ExtraIncomeViewModel: ObservableObject {
    @Published var categories: [IncomeCategory] = []
    @Published var incomes: [ExtraIncome] = []
    
    private var db: Connection?
    
    init() {
        db = Database.shared.getConnection()
    }
    
    // MARK: - Fetch
    func fetchAll() {
        fetchCategories()
        fetchIncomes()
    }
    
    func fetchCategories() {
        guard let db = db else { return }
        do {
            categories = try db.prepare(IncomeCategory.table).map { row in
                IncomeCategory(id: row[IncomeCategory.id], name: row[IncomeCategory.name])
            }
        } catch {
            print("Error fetching categories: \(error)")
        }
    }
    
    func fetchIncomes() {
        guard let db = db else { return }
        do {
            incomes = try db.prepare(ExtraIncome.table).map { row in
                ExtraIncome(
                    id: row[ExtraIncome.id],
                    categoryId: row[ExtraIncome.categoryId],
                    amount: row[ExtraIncome.amount],
                    receivedAt: row[ExtraIncome.receivedAt],
                    createdAt: row[ExtraIncome.createdAt],
                    updatedAt: row[ExtraIncome.updatedAt]
                )
            }
        } catch {
            print("Error fetching extra incomes: \(error)")
        }
    }
    
    // MARK: - Mutations
    func createCategory(name: String) {
        guard let db = db else { return }
        do {
            try db.run(IncomeCategory.table.insert(IncomeCategory.name <- name))
            fetchCategories()
        } catch {
            print("Error creating category: \(error)")
        }
    }
    
    func deleteCategory(id: Int64) {
        guard let db = db else { return }
        do {
            let cat = IncomeCategory.table.filter(IncomeCategory.id == id)
            try db.run(cat.delete())
            fetchCategories()
            fetchIncomes()
        } catch {
            print("Error deleting category: \(error)")
        }
    }
    
    func createIncome(categoryId: Int64, amount: Double, receivedAt: Date) {
        guard let db = db else { return }
        do {
            try db.run(ExtraIncome.table.insert(
                ExtraIncome.categoryId <- categoryId,
                ExtraIncome.amount <- amount,
                ExtraIncome.receivedAt <- receivedAt,
                ExtraIncome.createdAt <- Date(),
                ExtraIncome.updatedAt <- Date()
            ))
            fetchIncomes()
        } catch {
            print("Error creating extra income: \(error)")
        }
    }
    
    func updateIncome(id: Int64, categoryId: Int64, amount: Double, receivedAt: Date) {
        guard let db = db else { return }
        do {
            let row = ExtraIncome.table.filter(ExtraIncome.id == id)
            try db.run(row.update(
                ExtraIncome.categoryId <- categoryId,
                ExtraIncome.amount <- amount,
                ExtraIncome.receivedAt <- receivedAt,
                ExtraIncome.updatedAt <- Date()
            ))
            fetchIncomes()
        } catch {
            print("Error updating extra income: \(error)")
        }
    }
    
    func deleteIncome(id: Int64) {
        guard let db = db else { return }
        do {
            let row = ExtraIncome.table.filter(ExtraIncome.id == id)
            try db.run(row.delete())
            fetchIncomes()
        } catch {
            print("Error deleting extra income: \(error)")
        }
    }
    
    func calculateExtraAmountForCurrentMonth() -> Double {
        let cal = Calendar.current
        let m = cal.component(.month, from: Date())
        let y = cal.component(.year, from: Date())
        return incomes.filter { inc in
            cal.component(.month, from: inc.receivedAt) == m && cal.component(.year, from: inc.receivedAt) == y
        }.reduce(0) { $0 + $1.amount }
    }
}


