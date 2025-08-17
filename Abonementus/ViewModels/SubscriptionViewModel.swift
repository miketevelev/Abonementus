import SQLite
import Combine
import Foundation

class SubscriptionViewModel: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    @Published var activeSubscriptions: [Subscription] = []
    private var db: Connection?
    
    private var lessonVM: LessonViewModel?
    var onSubscriptionCreated: (() -> Void)?
    var onSubscriptionDeleted: ((Int64) -> Void)?
        
    init() {
        self.db = Database.shared.getConnection()
        fetchSubscriptions()
    }
    
    func setLessonViewModel(_ lessonVM: LessonViewModel) {
        self.lessonVM = lessonVM
    }
    
    func setOnSubscriptionCreated(_ callback: @escaping () -> Void) {
        self.onSubscriptionCreated = callback
    }
    
    func setOnSubscriptionDeleted(_ callback: @escaping (Int64) -> Void) {
        self.onSubscriptionDeleted = callback
    }
    
    func fetchSubscriptions() {
        guard let db = db else { return }
        
        do {
            // Clean up any orphaned lessons first
            cleanupOrphanedLessons()
            
            subscriptions = try db.prepare(Subscription.table).map { row in
                Subscription(
                    id: row[Subscription.id],
                    clientId: row[Subscription.clientId],
                    lessonCount: row[Subscription.lessonCount],
                    totalPrice: row[Subscription.totalPrice],
                    createdAt: row[Subscription.createdAt],
                    closedAt: row[Subscription.closedAt],
                    isActive: row[Subscription.isActive]
                )
            }
            activeSubscriptions = subscriptions.filter { $0.isActive }
        } catch {
            print("Error fetching subscriptions: \(error)")
        }
    }
    
    func createSubscription(clientId: Int64, lessonCount: Int, totalPrice: Double, startDate: Date = Date()) {
        guard let db = db else { return }
        
        do {
            let closedAt = Calendar.current.date(byAdding: .day, value: 30, to: startDate)
            
            let insert = Subscription.table.insert(
                Subscription.clientId <- clientId,
                Subscription.lessonCount <- lessonCount,
                Subscription.totalPrice <- totalPrice,
                Subscription.createdAt <- startDate,
                Subscription.closedAt <- closedAt,
                Subscription.isActive <- true
            )
            let subscriptionId = try db.run(insert)
            
            // Create lessons for this subscription
            let lessonPrice = totalPrice / Double(lessonCount)
            print("Creating \(lessonCount) lessons for subscription \(subscriptionId) with price \(lessonPrice) each")
            
            for lessonNumber in 1...lessonCount {
                do {
                    try db.run(Lesson.table.insert(
                        Lesson.clientId <- clientId,
                        Lesson.subscriptionId <- subscriptionId,
                        Lesson.number <- lessonNumber,
                        Lesson.price <- lessonPrice,
                        Lesson.createdAt <- startDate,
                        Lesson.conductedAt <- nil,
                        Lesson.isCompleted <- false
                    ))
                    print("Created lesson \(lessonNumber) for subscription \(subscriptionId)")
                } catch {
                    print("Error creating lesson \(lessonNumber): \(error)")
                    // If it's a column error, try to run migration
                    if error.localizedDescription.contains("no such column") {
                        print("Attempting to run database migration...")
                        Database.shared.runMigration()
                        // Try creating the lesson again after migration
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.createSubscription(clientId: clientId, lessonCount: lessonCount, totalPrice: totalPrice, startDate: startDate)
                        }
                        return
                    }
                    throw error
                }
            }
            
            print("Successfully created \(lessonCount) lessons for subscription \(subscriptionId)")
            fetchSubscriptions()
            
            // Refresh lessons data as well since new lessons were created
            lessonVM?.fetchLessons()
            
            // Notify that subscription was created
            onSubscriptionCreated?()
        } catch {
            print("Error creating subscription: \(error)")
        }
    }
    
    func deleteSubscription(id: Int64) {
        guard let db = db else { return }
        
        do {
            print("Deleting subscription \(id) and all associated lessons...")
            
            // First, let's count how many lessons will be deleted
            let lessonsToDelete = try db.prepare(Lesson.table.filter(Lesson.subscriptionId == id))
            let lessonCount = Array(lessonsToDelete).count
            print("Found \(lessonCount) lessons associated with subscription \(id)")
            
            // Delete the subscription (this should cascade delete the lessons due to foreign key constraint)
            let subscriptionToDelete = Subscription.table.filter(Subscription.id == id)
            try db.run(subscriptionToDelete.delete())
            
            print("Successfully deleted subscription \(id)")
            
            // Verify that lessons were deleted (they should be gone due to cascade)
            let remainingLessons = try db.prepare(Lesson.table.filter(Lesson.subscriptionId == id))
            let remainingCount = Array(remainingLessons).count
            print("Remaining lessons for subscription \(id): \(remainingCount)")
            
            if remainingCount > 0 {
                print("Warning: \(remainingCount) lessons still exist for deleted subscription \(id)")
                print("This indicates foreign key cascade delete is not working properly")
                
                // Force delete any remaining lessons (fallback)
                try db.run(Lesson.table.filter(Lesson.subscriptionId == id).delete())
                print("Force deleted remaining \(remainingCount) lessons")
            } else {
                print("Cascade delete working properly - all lessons automatically removed")
            }
            
            fetchSubscriptions()
            onSubscriptionDeleted?(id)
        } catch {
            print("Error deleting subscription: \(error)")
            
            // If there's an error, try to identify the issue
            if error.localizedDescription.contains("foreign key constraint") {
                print("Foreign key constraint error detected. Checking database integrity...")
                Database.shared.verifyForeignKeys()
            }
        }
    }
    
    func getLessons(for subscriptionId: Int64) -> [Lesson] {
        guard let lessonVM = lessonVM else { 
            print("getLessons: lessonVM is nil for subscription \(subscriptionId)")
            return [] 
        }
        
        let lessons = lessonVM.lessons.filter { $0.subscriptionId == subscriptionId }
        print("getLessons: Found \(lessons.count) lessons for subscription \(subscriptionId)")
        
        return lessons
    }
    
    // Clean up orphaned lessons (lessons that reference non-existent subscriptions)
    func cleanupOrphanedLessons() {
        guard let db = db else { return }
        
        do {
            print("Checking for orphaned lessons...")
            
            // Find lessons that reference non-existent subscriptions
            let orphanedLessons = try db.prepare(Lesson.table.filter(Lesson.subscriptionId != nil))
            var orphanedCount = 0
            
            for lesson in orphanedLessons {
                let subscriptionId = lesson[Lesson.subscriptionId]
                if let subId = subscriptionId {
                    // Check if subscription exists
                    let subscriptionCountResult = try db.scalar(Subscription.table.filter(Subscription.id == subId).count)
                    let subscriptionExists: Int64
                    if let int64Result = subscriptionCountResult as? Int64 {
                        subscriptionExists = int64Result
                    } else if let intResult = subscriptionCountResult as? Int {
                        subscriptionExists = Int64(intResult)
                    } else {
                        print("SubscriptionViewModel: Unexpected type for subscription count: \(type(of: subscriptionCountResult))")
                        subscriptionExists = 0
                    }
                    
                    if subscriptionExists == 0 {
                        print("Found orphaned lesson \(lesson[Lesson.id]) referencing non-existent subscription \(subId)")
                        orphanedCount += 1
                        
                        // Delete the orphaned lesson
                        try db.run(Lesson.table.filter(Lesson.id == lesson[Lesson.id]).delete())
                    }
                }
            }
            
            if orphanedCount > 0 {
                print("Cleaned up \(orphanedCount) orphaned lessons")
            } else {
                print("No orphaned lessons found")
            }
            
        } catch {
            print("Error cleaning up orphaned lessons: \(error)")
        }
    }
}
