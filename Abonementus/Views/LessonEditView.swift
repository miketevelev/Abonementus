import SwiftUI

struct LessonEditView: View {
    let lesson: Lesson
    let client: Client?
    let onSave: (Date) -> Void
    let onCancel: () -> Void
    
    @State private var selectedDate: Date
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(lesson: Lesson, client: Client?, onSave: @escaping (Date) -> Void, onCancel: @escaping () -> Void) {
        self.lesson = lesson
        self.client = client
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize with current conductedAt date or current date if nil
        self._selectedDate = State(initialValue: lesson.conductedAt ?? Date())
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button(action: {
                    onCancel()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text("Редактирование урока")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
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
            
            // Content
            Form {
                Section(header: Text("Информация об уроке")) {
                    HStack {
                        Text("Клиент:")
                        Spacer()
                        Text(client?.fullName ?? "Неизвестный")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Стоимость:")
                        Spacer()
                        Text("\(String(format: "%.2f", lesson.price)) руб.")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Дата создания:")
                        Spacer()
                        Text(lesson.createdAt.toString())
                            .foregroundColor(.secondary)
                    }
                    
                    if let conductedAt = lesson.conductedAt {
                        HStack {
                            Text("Текущая дата проведения:")
                            Spacer()
                            Text(conductedAt.toString())
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Новая дата проведения")) {
                    HStack {
                        Text("Дата проведения:")
                        Spacer()
                        DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                }
                
                Section(footer: Text("Изменение даты проведения урока повлияет на расчет дохода за соответствующий месяц и год.")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                            .padding(6)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Редактирование времени")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Buttons
            HStack(spacing: 12) {
                Button(action: { saveChanges() }) {
                    Label("Сохранить", systemImage: "checkmark.circle")
                        .padding(8)
                }
                .buttonStyle(GreenButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom)
        }
        .frame(minWidth: 500, minHeight: 300)
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Ошибка"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveChanges() {
        // Validate date (max 1 month in future, max 2 years in past)
        let calendar = Calendar.current
        let now = Date()
        let maxFuture = calendar.date(byAdding: .month, value: 1, to: now) ?? now
        let maxPast = calendar.date(byAdding: .year, value: -2, to: now) ?? now
        
        if selectedDate > maxFuture {
            errorMessage = "Дата не может быть более чем на 1 месяц в будущем"
            showError = true
            return
        }
        
        if selectedDate < maxPast {
            errorMessage = "Дата не может быть более чем на 2 года в прошлом"
            showError = true
            return
        }
        
        onSave(selectedDate)
    }
}

struct LessonEditView_Previews: PreviewProvider {
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
        
        let sampleLesson = Lesson(
            id: 1,
            clientId: 1,
            subscriptionId: nil,
            number: 1,
            price: 1000,
            createdAt: Date().addingTimeInterval(-86400),
            conductedAt: Date(),
            isCompleted: true
        )
        
        return LessonEditView(
            lesson: sampleLesson,
            client: sampleClient,
            onSave: { _ in },
            onCancel: {}
        )
    }
}
