import SwiftUI

struct LessonCreateView: View {
    @State private var selectedClientId: Int64 = 0
    @State private var price: String = ""
    @State private var lessonDate: Date = Date()
    @State private var showError = false
    @State private var errorMessage = ""
    
    let clients: [Client]
    let onCreate: (Int64, Double, Date) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 16) {
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
                
                Text("Создание урока")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: saveLesson) {
                    Label("Сохранить", systemImage: "checkmark.circle")
                        .padding(8)
                }
                .buttonStyle(BlueButtonStyle())
            }
            .padding(.horizontal, 20)
            
            // Form
            Form {
                Section(header: Text("Основная информация")) {
                    Picker("Клиент", selection: $selectedClientId) {
                        Text("Не выбран").tag(0)
                        ForEach(clients.sorted(by: { $0.fullName < $1.fullName }), id: \.id) { client in
                            Text(client.fullName).tag(client.id)
                        }
                    }
                    
                    DatePicker("Дата проведения", selection: $lessonDate, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Стоимость урока", text: $price)
                                            #if os(iOS)
                                            .keyboardType(.decimalPad)
                                            #endif
                }
                
                Section(header: Text("Информация"), footer: Text("Урок будет автоматически отмечен как проведенный и включен в месячную статистику. Вы можете выбрать любую дату в прошлом для ретроактивного создания.")) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                            .padding(6)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Ретроактивное создание")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Статус урока:")
                        Spacer()
                        Text(lessonStatusText)
                            .fontWeight(.medium)
                            .foregroundColor(lessonStatusColor)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(minWidth: 400, minHeight: 350)
        .alert(isPresented: $showError) {
            Alert(title: Text("Ошибка"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            if let firstClient = clients.first {
                selectedClientId = firstClient.id
            }
        }
    }
    
    private var lessonStatusText: String {
        if lessonDate > Date() {
            return "Будущий урок"
        } else {
            return "Завершенный урок"
        }
    }
    
    private var lessonStatusColor: Color {
        if lessonDate > Date() {
            return .orange
        } else {
            return .green
        }
    }
    
    private func saveLesson() {
        guard selectedClientId != 0 else {
            errorMessage = "Выберите клиента"
            showError = true
            return
        }
        
        guard let priceValue = Double(price), priceValue > 0 else {
            errorMessage = "Введите корректную стоимость урока"
            showError = true
            return
        }
        
        // Validate that lesson date is not too far in the future (max 1 month)
        let maxFutureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        if lessonDate > maxFutureDate {
            errorMessage = "Дата урока не может быть более чем на месяц в будущем"
            showError = true
            return
        }
        
        // Validate that lesson date is not too far in the past (max 2 years)
        let minPastDate = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        if lessonDate < minPastDate {
            errorMessage = "Дата урока не может быть более чем 2 года назад"
            showError = true
            return
        }
        
        onCreate(selectedClientId, priceValue, lessonDate)
        presentationMode.wrappedValue.dismiss()
    }
}
