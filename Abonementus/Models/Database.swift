import SQLite
import Foundation

class Database {
    static let shared = Database()
    private var db: Connection?
    private let databaseFileName = "abonementus_bd.sqlite"
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        let fileManager = FileManager.default
        let appSupportURL = try! fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let folderURL = appSupportURL.appendingPathComponent("Abonementus")
        try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        
        let dbURL = folderURL.appendingPathComponent(databaseFileName)
        
        do {
            db = try Connection(dbURL.path)
            print("Database: Successfully connected to database at \(dbURL.path)")
            
            // Verify foreign key constraints are enabled
            verifyForeignKeys()
            
            createTables()
        } catch {
            print("Database: Failed to connect to database: \(error)")
            db = nil
        }
    }
    
    private func createTables() {
        guard let db = db else { 
            print("Database: No database connection available for table creation")
            return 
        }
        
        print("Database: Starting table creation...")
        
        do {
            try db.run(Client.table.create(ifNotExists: true) { t in
                t.column(Client.id, primaryKey: .autoincrement)
                t.column(Client.firstName)
                t.column(Client.lastName)
                t.column(Client.phone)
                t.column(Client.telegram)
                t.column(Client.email)
                t.column(Client.additionalInfo)
                t.column(Client.createdAt)
                t.column(Client.updatedAt)
            })
            print("Database: Client table created/verified successfully")
            
            try db.run(Subscription.table.create(ifNotExists: true) { t in
                t.column(Subscription.id, primaryKey: .autoincrement)
                t.column(Subscription.clientId)
                t.column(Subscription.lessonCount)
                t.column(Subscription.totalPrice)
                t.column(Subscription.createdAt)
                t.column(Subscription.closedAt)
                t.column(Subscription.isActive)
                t.foreignKey(Subscription.clientId, references: Client.table, Client.id, delete: .cascade)
            })
            print("Database: Subscription table created/verified successfully")
            
            try db.run(Lesson.table.create(ifNotExists: true) { t in
                t.column(Lesson.id, primaryKey: .autoincrement)
                t.column(Lesson.clientId)
                t.column(Lesson.subscriptionId)
                t.column(Lesson.number)
                t.column(Lesson.price)
                t.column(Lesson.createdAt)
                t.column(Lesson.conductedAt)
                t.column(Lesson.isCompleted)
                t.foreignKey(Lesson.clientId, references: Client.table, Client.id, delete: .cascade)
                t.foreignKey(Lesson.subscriptionId, references: Subscription.table, Subscription.id, delete: .cascade)
            })
            print("Database: Lesson table created/verified successfully")

            // Income categories
            try db.run(IncomeCategory.table.create(ifNotExists: true) { t in
                t.column(IncomeCategory.id, primaryKey: .autoincrement)
                t.column(IncomeCategory.name, unique: true)
            })
            print("Database: IncomeCategory table created/verified successfully")

            // Extra incomes
            try db.run(ExtraIncome.table.create(ifNotExists: true) { t in
                t.column(ExtraIncome.id, primaryKey: .autoincrement)
                t.column(ExtraIncome.categoryId)
                t.column(ExtraIncome.amount)
                t.column(ExtraIncome.receivedAt)
                t.column(ExtraIncome.createdAt)
                t.column(ExtraIncome.updatedAt)
                t.foreignKey(ExtraIncome.categoryId, references: IncomeCategory.table, IncomeCategory.id, delete: .cascade)
            })
            print("Database: ExtraIncome table created/verified successfully")
            
            // Run migrations for existing databases
            migrateDatabase()
            
            print("Database: All tables created/verified successfully")
            
            // Test the connection
            testConnection()
        } catch {
            print("Database: Error creating tables: \(error)")
        }
    }
    
    private func migrateDatabase() {
        guard let db = db else { return }
        
        do {
            // Check if lessons table exists
            let tableExists = try db.scalar("SELECT name FROM sqlite_master WHERE type='table' AND name='lessons'") != nil
            
            if !tableExists {
                print("Lessons table doesn't exist yet, skipping migration")
                return
            }
            
            // Check if number column exists in lessons table
            let tableInfo = try db.prepare("PRAGMA table_info(lessons)")
            let columns = try tableInfo.map { row -> String in
                if let columnName = row[1] as? String {
                    return columnName
                } else {
                    print("Database: Unexpected type for column name: \(type(of: row[1]))")
                    return ""
                }
            }
            
            print("Current lesson table columns: \(columns)")
            
            // If number column doesn't exist, add it
            if !columns.contains("number") {
                print("Adding number column to lessons table...")
                try db.run("ALTER TABLE lessons ADD COLUMN number INTEGER DEFAULT 1")
                
                // Update existing lessons with sequential numbers
                let existingLessons = try db.prepare(Lesson.table)
                var lessonNumber = 1
                for lesson in existingLessons {
                    try db.run(Lesson.table.filter(Lesson.id == lesson[Lesson.id]).update(Lesson.number <- lessonNumber))
                    lessonNumber += 1
                }
                print("Updated \(lessonNumber - 1) existing lessons with sequential numbers")
            } else {
                print("Number column already exists in lessons table")
            }
        } catch {
            print("Error during migration: \(error)")
            // Don't crash the app if migration fails
        }
    }
    
    func getConnection() -> Connection? {
        return db
    }
    
    // Test database connection and basic functionality
    func testConnection() {
        guard let db = db else { 
            print("Database: No connection available for testing")
            return 
        }
        
        print("Database: Testing connection...")
        
        do {
            // Simple test - just try to execute a basic query
            let _ = try db.scalar("SELECT 1")
            print("Database: Connection test successful - basic query executed")
            
            // Test table existence without counting
            let clientTableExists = try db.scalar("SELECT name FROM sqlite_master WHERE type='table' AND name='clients'") != nil
            let subscriptionTableExists = try db.scalar("SELECT name FROM sqlite_master WHERE type='table' AND name='subscriptions'") != nil
            let lessonTableExists = try db.scalar("SELECT name FROM sqlite_master WHERE type='table' AND name='lessons'") != nil
            
            print("Database: Tables exist - Clients: \(clientTableExists), Subscriptions: \(subscriptionTableExists), Lessons: \(lessonTableExists)")
            
        } catch {
            print("Database: Connection test failed: \(error)")
        }
    }
    
    // Public method to manually trigger migration (useful for debugging)
    func runMigration() {
        migrateDatabase()
    }
    
    // Verify that foreign key constraints are enabled
    func verifyForeignKeys() {
        guard let db = db else { return }
        
        do {
            // Enable foreign key constraints
            try db.run("PRAGMA foreign_keys = ON")
            
            // Check if foreign keys are enabled
            let foreignKeysResult = try db.scalar("PRAGMA foreign_keys")
            let foreignKeysEnabled: Int64
            if let int64Result = foreignKeysResult as? Int64 {
                foreignKeysEnabled = int64Result
            } else if let intResult = foreignKeysResult as? Int {
                foreignKeysEnabled = Int64(intResult)
            } else {
                print("Database: Unexpected type for foreign_keys PRAGMA: \(type(of: foreignKeysResult))")
                foreignKeysEnabled = 0
            }
            print("Database: Foreign key constraints enabled: \(foreignKeysEnabled == 1 ? "YES" : "NO")")
            
            if foreignKeysEnabled == 0 {
                print("Database: Warning: Foreign key constraints are disabled!")
                print("Database: Attempting to enable them...")
                try db.run("PRAGMA foreign_keys = ON")
                
                // Check again
                let checkResult = try db.scalar("PRAGMA foreign_keys")
                let checkAgain: Int64
                if let int64Result = checkResult as? Int64 {
                    checkAgain = int64Result
                } else if let intResult = checkResult as? Int {
                    checkAgain = Int64(intResult)
                } else {
                    print("Database: Unexpected type for foreign_keys PRAGMA check: \(type(of: checkResult))")
                    checkAgain = 0
                }
                print("Database: Foreign key constraints after attempt: \(checkAgain == 1 ? "YES" : "NO")")
            }
        } catch {
            print("Database: Error verifying foreign keys: \(error)")
        }
    }
    
    // MARK: - Backup
    /// Creates a ZIP archive of the SQLite database in the user's Documents folder.
    /// The file name format is "AbonementusDBddMMyyyy.zip". Existing files are overwritten.
    @discardableResult
    func backupDatabaseToDocumentsZip() -> Bool {
        let fileManager = FileManager.default
        do {
            // Locate current DB file in Application Support
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let sourceFolderURL = appSupportURL.appendingPathComponent("Abonementus")
            let sourceDBURL = sourceFolderURL.appendingPathComponent(databaseFileName)
            
            guard fileManager.fileExists(atPath: sourceDBURL.path) else {
                print("Database: Backup failed - DB file not found at \(sourceDBURL.path)")
                return false
            }
            
            // Build destination URL in Documents
            let documentsURL = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "ddMMyyyy"
            let dateString = dateFormatter.string(from: Date())
            let zipFileURL = documentsURL.appendingPathComponent("AbonementusDB\(dateString).zip")
            
            // Remove existing zip if any
            if fileManager.fileExists(atPath: zipFileURL.path) {
                try? fileManager.removeItem(at: zipFileURL)
            }
            
            // Create zip using /usr/bin/zip for broad compatibility
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
            process.currentDirectoryURL = sourceFolderURL
            process.arguments = ["-j", zipFileURL.path, sourceDBURL.lastPathComponent]
            
            print("Database: Zip command: /usr/bin/zip -j \(zipFileURL.path) \(sourceDBURL.lastPathComponent)")
            print("Database: Working directory: \(sourceFolderURL.path)")
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                print("Database: Backup completed -> \(zipFileURL.path)")
                return true
            } else {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let log = String(data: data, encoding: .utf8) ?? ""
                print("Database: Backup failed with status \(process.terminationStatus). Log: \n\(log)")
                return false
            }
        } catch {
            print("Database: Backup error: \(error)")
            return false
        }
    }
}
