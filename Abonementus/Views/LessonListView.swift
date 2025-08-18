import SwiftUI

struct LessonListView: View {
    let lessons: [Lesson]
    let clients: [Client]
    let onDelete: (Int64) -> Void
    let onUpdateLessonTime: (Int64, Date) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedLessonForEdit: Lesson?
    @State private var showDeleteConfirmation = false
    @State private var lessonToDelete: Int64?
    
    var body: some View {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Все уроки")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if availableYears.count > 1 {
                            Picker("Год", selection: $selectedYear) {
                                ForEach(availableYears, id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 100)
                        }
                    }
                    
                    Spacer()
                    
                    // Empty space to balance the layout
                    Button(action: {}) {
                        Image(systemName: "")
                            .font(.title2)
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.top)
                
                // Lessons list
                List {
                    // Active lessons
                    Section(header: Text("Активные уроки")) {
                        ForEach(filteredActiveLessons, id: \.id) { lesson in
                            lessonRow(for: lesson)
                                .background(Color.yellow.opacity(0.1))
                                .cornerRadius(6)
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
            .frame(minWidth: 600, minHeight: 500)
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
    
    private var filteredActiveLessons: [Lesson] {
        let calendar = Calendar.current
        return activeLessons.filter { lesson in
            calendar.component(.year, from: lesson.createdAt) == selectedYear
        }
    }
    
    private var filteredCompletedLessons: [Lesson] {
        let calendar = Calendar.current
        return completedLessons.filter { lesson in
            if let conductedAt = lesson.conductedAt {
                return calendar.component(.year, from: conductedAt) == selectedYear
            } else {
                return calendar.component(.year, from: lesson.createdAt) == selectedYear
            }
        }
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
            
            Spacer()
            
            // Dates and subscription info
            VStack(alignment: .leading, spacing: 4) {
                if !lesson.isCompleted {
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
            
            Spacer()
            
            // Delete button (only for single lessons)
            if lesson.subscriptionId == nil {
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
                .padding(.trailing, 20)
            } else {
                // Empty space to maintain alignment
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 28, height: 28)
                    .padding(.trailing, 20)
            }

            // Edit button (pencil) to open editor
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
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 20)
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
