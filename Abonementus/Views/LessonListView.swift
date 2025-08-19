import SwiftUI

struct LessonListView: View {
    let lessons: [Lesson]
    let clients: [Client]
    let onDelete: (Int64) -> Void
    let onUpdateLessonTime: (Int64, Date) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int? = nil
    @State private var selectedClientId: Int64? = nil
    @State private var selectedLessonType: String? = nil
    @State private var showAllLessonTypes: Bool = false
    @State private var selectedLessonForEdit: Lesson?
    @State private var showDeleteConfirmation = false
    @State private var lessonToDelete: Int64?
    
    var body: some View {
            VStack(spacing: 0) {
                // Top bar 50px
                HStack {
                    Text("Все уроки")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(height: 50)
                .padding(.horizontal, 20)
                .background(Color(.controlBackgroundColor))
                .padding(.bottom, 10)

                // Filters row
                HStack(spacing: 12) {
                    if availableYears.count > 1 {
                        Picker("Год", selection: $selectedYear) {
                            ForEach(availableYears, id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 100)
                    }
                    
                    Picker("Месяц", selection: $selectedMonth) {
                        Text("Все месяцы").tag(nil as Int?)
                        ForEach(availableMonths, id: \.self) { month in
                            Text(monthName(for: month)).tag(Optional(month))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 140)
                    
                    Picker("Клиент", selection: $selectedClientId) {
                        Text("Все клиенты").tag(nil as Int64?)
                        ForEach(availableClients.sorted { $0.fullName < $1.fullName }, id: \.id) { client in
                            Text(client.fullName).tag(Optional(client.id))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 220)
                    
                    Picker("Тип урока", selection: $selectedLessonType) {
                        Text("Все типы").tag(nil as String?)
                        Text("Абонементный").tag(Optional("subscription"))
                        Text("Разовый").tag(Optional("single"))
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 230)
                    
                    HStack(spacing: 8) {
                        Text("Все")
                        Toggle("Все", isOn: $showAllLessonTypes)
                            .labelsHidden()
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                
                // Lessons list
                List {
                    // Active lessons (only when toggle is on)
                    if showAllLessonTypes {
                        Section(header: Text("Активные уроки")) {
                            ForEach(filteredActiveLessons, id: \.id) { lesson in
                                lessonRow(for: lesson)
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    
                    // Completed lessons
                    Section(header: HStack {
                        Text("Завершенные уроки")
                        Spacer()
                    }) {
                        ForEach(filteredCompletedLessons, id: \.id) { lesson in
                            lessonRow(for: lesson)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 20)
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.automatic)
                #endif
            }
            .frame(minWidth: 900, minHeight: 500)
            .sheet(item: $selectedLessonForEdit) { lesson in
                let client = clients.first { $0.id == lesson.clientId }
                LessonEditView(
                    lesson: lesson,
                    client: client,
                    onSave: { newDate in
                        onUpdateLessonTime(lesson.id, newDate)
                        selectedLessonForEdit = nil
                    },
                    onCancel: {
                        selectedLessonForEdit = nil
                    }
                )
            }
            .alert("Подтверждение удаления", isPresented: $showDeleteConfirmation) {
                Button("Отмена", role: .cancel) { }
                Button("Удалить", role: .destructive) {
                    if let lessonId = lessonToDelete {
                        onDelete(lessonId)
                        lessonToDelete = nil
                    }
                }
            } message: {
                if let lessonId = lessonToDelete,
                   let lesson = lessons.first(where: { $0.id == lessonId }),
                   let client = clients.first(where: { $0.id == lesson.clientId }) {
                    Text("Вы уверены, что хотите удалить урок для клиента \(client.fullName)?")
                } else {
                    Text("Вы уверены, что хотите удалить урок?")
                }
            }
        }
    
    private var activeLessons: [Lesson] {
        lessons.filter { !$0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    private var completedLessons: [Lesson] {
        lessons.filter { $0.isCompleted }
            .sorted { ($0.conductedAt ?? $0.createdAt) > ($1.conductedAt ?? $1.createdAt) }
    }
    
    private var availableYears: [Int] {
        let calendar = Calendar.current
        let years = lessons.map { lesson in
            if lesson.isCompleted, let conductedAt = lesson.conductedAt {
                return calendar.component(.year, from: conductedAt)
            } else {
                return calendar.component(.year, from: lesson.createdAt)
            }
        }
        return Array(Set(years)).sorted(by: >)
    }
    
    // Completed months available for the selected year
    private var availableMonths: [Int] {
        let calendar = Calendar.current
        let months = lessons.compactMap { lesson -> Int? in
            if let conductedAt = lesson.conductedAt {
                let year = calendar.component(.year, from: conductedAt)
                if year == selectedYear { return calendar.component(.month, from: conductedAt) }
            }
            return nil
        }
        let unique = Array(Set(months)).sorted()
        return unique
    }
    
    private var filteredActiveLessons: [Lesson] {
        let calendar = Calendar.current
        return activeLessons.filter { lesson in
            // Filter by year (createdAt for active)
            guard calendar.component(.year, from: lesson.createdAt) == selectedYear else { return false }
            // Filter by client if selected
            if let clientId = selectedClientId, lesson.clientId != clientId { return false }
            // Filter by lesson type if selected
            if let lessonType = selectedLessonType {
                if lessonType == "subscription" && lesson.subscriptionId == nil { return false }
                if lessonType == "single" && lesson.subscriptionId != nil { return false }
            }
            // If a month is selected, active lessons should be hidden
            if selectedMonth != nil { return false }
            return true
        }
    }
    
    private var filteredCompletedLessons: [Lesson] {
        let calendar = Calendar.current
        return completedLessons.filter { lesson in
            // Year and month use conductedAt if exists
            let dateForFilter = lesson.conductedAt ?? lesson.createdAt
            guard calendar.component(.year, from: dateForFilter) == selectedYear else { return false }
            // Month filter for completed
            if let month = selectedMonth, calendar.component(.month, from: dateForFilter) != month { return false }
            // Client filter
            if let clientId = selectedClientId, lesson.clientId != clientId { return false }
            // Filter by lesson type if selected
            if let lessonType = selectedLessonType {
                if lessonType == "subscription" && lesson.subscriptionId == nil { return false }
                if lessonType == "single" && lesson.subscriptionId != nil { return false }
            }
            return true
        }
    }
    
    private func monthName(for month: Int) -> String {
        let monthNames = [
            1: "Январь", 2: "Февраль", 3: "Март", 4: "Апрель",
            5: "Май", 6: "Июнь", 7: "Июль", 8: "Август",
            9: "Сентябрь", 10: "Октябрь", 11: "Ноябрь", 12: "Декабрь"
        ]
        return monthNames[month] ?? String(month)
    }
    
    private var availableClients: [Client] {
        let calendar = Calendar.current
        
        // Get all lessons for the selected year and month
        let relevantLessons = lessons.filter { lesson in
            let dateForFilter = lesson.conductedAt ?? lesson.createdAt
            let year = calendar.component(.year, from: dateForFilter)
            guard year == selectedYear else { return false }
            
            if let month = selectedMonth {
                return calendar.component(.month, from: dateForFilter) == month
            } else {
                return true
            }
        }
        
        // Filter by lesson completion status based on checkbox
        let filteredLessons = relevantLessons.filter { lesson in
            if showAllLessonTypes {
                // Show all lessons (both active and completed)
                return true
            } else {
                // Show only completed lessons
                return lesson.isCompleted
            }
        }
        
        // Get unique client IDs from relevant lessons
        let relevantClientIds = Set(filteredLessons.map { $0.clientId })
        
        // Return only clients that have relevant lessons
        return clients.filter { relevantClientIds.contains($0.id) }
    }
    
    private func lessonRow(for lesson: Lesson) -> some View {
        let client = clients.first { $0.id == lesson.clientId }
        
        return HStack {
            // Client info and price
            VStack(alignment: .leading, spacing: 4) {
                Text(client?.fullName ?? "Неизвестный клиент")
                    .font(.headline)
                
                Text("\(String(format: "%.2f", lesson.price)) руб.")
                    .font(.subheadline)
            }
            .frame(width: 200, alignment: .leading)
            
            // Dates and subscription info - aligned to left with 190px margin from right
            VStack(alignment: .leading, spacing: 4) {
                if !lesson.isCompleted {
                    Text("Создан: \(lesson.createdAt.toString())")
                } else if lesson.conductedAt == nil {
                    // Show creation date only for completed lessons without conductedAt
                    Text("Создан: \(lesson.createdAt.toString())")
                }
                if let conductedAt = lesson.conductedAt {
                    Text("Проведен: \(conductedAt.toString())")
                }
                
                Text(lesson.subscriptionId == nil ? "Разовый урок" : "Абонементный урок")
                    .font(.caption)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 150)
            .padding(.trailing, 190)

            // Show actions only for completed lessons
            if lesson.isCompleted {
                HStack(spacing: 8) {
                    if lesson.subscriptionId == nil {
                        // Delete for completed single lessons
                        Button(action: {
                            lessonToDelete = lesson.id
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                                .padding(6)
                                .background(Color.red.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // Edit button for all completed lessons
                    Button(action: {
                        selectedLessonForEdit = lesson
                    }) {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                            .padding(6)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.trailing, 1)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
    }
}

// Предварительный просмотр для Xcode
struct LessonListView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleClient = Client(
            id: 1,
            firstName: "Иван",
            lastName: "Иванов",
            phone: nil,
            telegram: nil,
            email: nil,
            additionalInfo: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let sampleLessons = [
            Lesson(
                id: 1,
                clientId: 1,
                subscriptionId: nil,
                number: 1,
                price: 1000,
                createdAt: Date(),
                conductedAt: nil,
                isCompleted: false
            ),
            Lesson(
                id: 2,
                clientId: 1,
                subscriptionId: 1,
                number: 2,
                price: 800,
                createdAt: Date().addingTimeInterval(-86400),
                conductedAt: Date(),
                isCompleted: true
            )
        ]
        
        return LessonListView(
            lessons: sampleLessons,
            clients: [sampleClient],
            onDelete: { _ in },
            onUpdateLessonTime: { _, _ in }
        )
    }
}
