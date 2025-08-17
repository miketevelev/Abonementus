import SQLite
import Combine
import Foundation

class LessonViewModel: ObservableObject {
    @Published var lessons: [Lesson] = []
    @Published var completedLessons: [Lesson] = []
    @Published var pendingLessons: [Lesson] = []
    private var db: Connection?
    
    var onLessonCreated: (() -> Void)?
    var onSubscriptionCompleted: ((Int64) -> Void)?
    
    init() {
        db = Database.shared.getConnection()
        // Don't fetch immediately - let the view control when to load
    }
    
    func setOnLessonCreated(_ callback: @escaping () -> Void) {
        self.onLessonCreated = callback
    }
    
    func setOnSubscriptionCompleted(_ callback: @escaping (Int64) -> Void) {
        self.onSubscriptionCompleted = callback
    }
    
    func fetchLessons() {
        guard let db = db else { 
            print("No database connection available")
            return 
        }
        
        do {
            lessons = try db.prepare(Lesson.table).map { row in
                // Try to get the number, fallback to 1 if it doesn't exist
                let lessonNumber: Int
                do {
                    lessonNumber = row[Lesson.number]
                } catch {
                    print("Warning: Could not read lesson number for lesson \(row[Lesson.id]), using default value 1")
                    lessonNumber = 1
                }
                
                return Lesson(
                    id: row[Lesson.id],
                    clientId: row[Lesson.clientId],
                    subscriptionId: row[Lesson.subscriptionId],
                    number: lessonNumber,
                    price: row[Lesson.price],
                    createdAt: row[Lesson.createdAt],
                    conductedAt: row[Lesson.conductedAt],
                    isCompleted: row[Lesson.isCompleted]
                )
            }
            completedLessons = lessons.filter { $0.isCompleted }
            pendingLessons = lessons.filter { !$0.isCompleted }
            
            print("Successfully fetched \(lessons.count) lessons")
            print("Completed lessons: \(completedLessons.count), Pending lessons: \(pendingLessons.count)")
            
            // Log subscription lessons specifically
            let subscriptionLessons = lessons.filter { $0.subscriptionId != nil }
            print("Subscription lessons: \(subscriptionLessons.count)")
            for lesson in subscriptionLessons {
                print("  Lesson \(lesson.number) for subscription \(lesson.subscriptionId ?? 0), completed: \(lesson.isCompleted)")
            }
        } catch {
            print("Error fetching lessons: \(error)")
            // Try to run migration if there's a column error
            if error.localizedDescription.contains("no such column") {
                print("Attempting to run database migration...")
                Database.shared.runMigration()
                // Try fetching again after migration
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.fetchLessons()
                }
            }
        }
    }
    
    func createLesson(clientId: Int64, subscriptionId: Int64?, price: Double, lessonDate: Date? = nil) {
        guard let db = db else { return }
        
        do {
            let isCompleted = lessonDate != nil // If lessonDate is provided, mark as completed
            let conductedAt = lessonDate ?? nil // Use provided date or nil
            let createdAt = lessonDate ?? Date() // Use lessonDate for creation date if provided, otherwise use now
            
            // Get the next lesson number for this client
            let nextNumber = getNextLessonNumber(for: clientId, subscriptionId: subscriptionId)
            
            print("Creating lesson: clientId=\(clientId), subscriptionId=\(subscriptionId ?? 0), price=\(price), isCompleted=\(isCompleted), createdAt=\(createdAt.description), conductedAt=\(conductedAt?.description ?? "nil")")
            
            try db.run(Lesson.table.insert(
                Lesson.clientId <- clientId,
                Lesson.subscriptionId <- subscriptionId,
                Lesson.number <- nextNumber,
                Lesson.price <- price,
                Lesson.createdAt <- createdAt,
                Lesson.conductedAt <- conductedAt,
                Lesson.isCompleted <- isCompleted
            ))
            
            print("Lesson created successfully with number \(nextNumber)")
            fetchLessons()
            onLessonCreated?() // Notify the view
        } catch {
            print("Error creating lesson: \(error)")
        }
    }
    
    private func getNextLessonNumber(for clientId: Int64, subscriptionId: Int64?) -> Int {
        if let subscriptionId = subscriptionId {
            // For subscription lessons, get the next number in sequence
            let subscriptionLessons = lessons.filter { $0.subscriptionId == subscriptionId }
            return (subscriptionLessons.map { $0.number }.max() ?? 0) + 1
        } else {
            // For single lessons, get the next number for this client
            let clientLessons = lessons.filter { $0.clientId == clientId && $0.subscriptionId == nil }
            return (clientLessons.map { $0.number }.max() ?? 0) + 1
        }
    }
    
    func completeLesson(lesson: Lesson) {
        guard let db = db else { return }
        
        do {
            let lessonToUpdate = Lesson.table.filter(Lesson.id == lesson.id)
            try db.run(lessonToUpdate.update(
                Lesson.conductedAt <- Date(),
                Lesson.isCompleted <- true
            ))
            
            print("Lesson \(lesson.id) marked as completed")
            
            // Check if all lessons in the subscription are completed
            if let subscriptionId = lesson.subscriptionId {
                let subscriptionLessons = try db.prepare(
                    Lesson.table.filter(Lesson.subscriptionId == subscriptionId)
                )
                
                let allCompleted = !subscriptionLessons.contains { !$0[Lesson.isCompleted] }
                
                if allCompleted {
                    print("All lessons completed for subscription \(subscriptionId), marking as inactive")
                    try db.run(Subscription.table.filter(Subscription.id == subscriptionId).update(
                        Subscription.isActive <- false,
                        Subscription.closedAt <- Date()
                    ))
                    
                    onSubscriptionCompleted?(subscriptionId)
                }
            }
            
            fetchLessons()
        } catch {
            print("Error completing lesson: \(error)")
        }
    }
    
    func uncompleteLesson(lesson: Lesson) {
        guard let db = db else { return }
        
        do {
            let lessonToUpdate = Lesson.table.filter(Lesson.id == lesson.id)
            try db.run(lessonToUpdate.update(
                Lesson.conductedAt <- nil,
                Lesson.isCompleted <- false
            ))
            
            print("Lesson \(lesson.id) marked as uncompleted")
            
            // Check if subscription should be reactivated
            if let subscriptionId = lesson.subscriptionId {
                let subscriptionLessons = try db.prepare(
                    Lesson.table.filter(Lesson.subscriptionId == subscriptionId)
                )
                
                let allCompleted = !subscriptionLessons.contains { !$0[Lesson.isCompleted] }
                
                if !allCompleted {
                    print("Not all lessons completed for subscription \(subscriptionId), marking as active")
                    try db.run(Subscription.table.filter(Subscription.id == subscriptionId).update(
                        Subscription.isActive <- true,
                        Subscription.closedAt <- nil
                    ))
                    
                    onSubscriptionCompleted?(subscriptionId)
                }
            }
            
            fetchLessons()
        } catch {
            print("Error uncompleting lesson: \(error)")
        }
    }
    
    func deleteLesson(id: Int64) {
        guard let db = db else { return }
        
        do {
            let lessonToDelete = Lesson.table.filter(Lesson.id == id)
            try db.run(lessonToDelete.delete())
            fetchLessons()
        } catch {
            print("Error deleting lesson: \(error)")
        }
    }
    
    func updateLessonCompletionTime(lessonId: Int64, newConductedAt: Date) {
        guard let db = db else { return }
        
        do {
            let lessonToUpdate = Lesson.table.filter(Lesson.id == lessonId)
            try db.run(lessonToUpdate.update(
                Lesson.conductedAt <- newConductedAt
            ))
            
            print("Lesson \(lessonId) completion time updated to \(newConductedAt)")
            fetchLessons()
        } catch {
            print("Error updating lesson completion time: \(error)")
        }
    }
    
    func calculateCompletedAmount() -> Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let monthlyCompletedLessons = completedLessons.filter { lesson in
            let lessonMonth = Calendar.current.component(.month, from: lesson.conductedAt ?? lesson.createdAt)
            let lessonYear = Calendar.current.component(.year, from: lesson.conductedAt ?? lesson.createdAt)
            return lessonMonth == currentMonth && lessonYear == currentYear
        }
        
        let totalAmount = monthlyCompletedLessons.reduce(0) { $0 + $1.price }
        
        print("Monthly completed amount calculation: month=\(currentMonth), year=\(currentYear), lessons=\(monthlyCompletedLessons.count), total=\(totalAmount)")
        
        return totalAmount
    }
    
    func calculatePendingAmount() -> Double {
        return pendingLessons.reduce(0) { $0 + $1.price }
    }
}
