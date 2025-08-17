import SwiftUI

struct SubscriptionCreateView: View {
    @State private var selectedClientId: Int64 = 0
    @State private var lessonCount: String = "4"
    @State private var totalPrice: String = "4000"
    @State private var startDate: Date = Date()
    @State private var showError = false
    @State private var errorMessage = ""
    
    let clients: [Client]
    let onCreate: (Int64, Int, Double, Date) -> Void
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
                
                Text("Создание абонемента")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: createSubscription) {
                    Label("Создать", systemImage: "plus.circle")
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
                    
                    TextField("Количество уроков", text: $lessonCount)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    
                    TextField("Общая стоимость", text: $totalPrice)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    
                    DatePicker("Дата начала", selection: $startDate, displayedComponents: [.date])
                }
                
                Section(header: Text("Информация"), footer: Text("Вы можете создать абонемент с любой датой начала. Абонементы старше 30 дней автоматически отмечены как истекшие.")) {
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
                }
                
                Section(header: Text("Расчет")) {
                    HStack {
                        Text("Стоимость одного урока:")
                        Spacer()
                        Text(lessonPriceString)
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Дата окончания:")
                        Spacer()
                        Text(endDateString)
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Статус при создании:")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(subscriptionStatusText)
                                .fontWeight(.bold)
                                .foregroundColor(subscriptionStatusColor)
                            
                            if subscriptionStatusText == "Истек" {
                                Text("Абонемент будет создан как истекший")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Абонемент будет активен")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(minWidth: 450, minHeight: 400)
        .alert(isPresented: $showError) {
            Alert(title: Text("Ошибка"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            if let firstClient = clients.first {
                selectedClientId = firstClient.id
            }
        }
    }
    
    private var lessonPriceString: String {
        guard let count = Int(lessonCount), count > 0,
              let price = Double(totalPrice), price > 0 else {
            return "—"
        }
        return String(format: "%.2f руб.", price / Double(count))
    }
    
    private var endDateString: String {
        startDate.adding(days: 30).toString(format: "dd.MM.yyyy")
    }
    
    private var subscriptionStatusText: String {
        let endDate = startDate.adding(days: 30)
        if endDate < Date() {
            return "Истек"
        } else {
            return "Активен"
        }
    }
    
    private var subscriptionStatusColor: Color {
        let endDate = startDate.adding(days: 30)
        if endDate < Date() {
            return .orange
        } else {
            return .green
        }
    }
    
    private func createSubscription() {
        guard selectedClientId != 0 else {
            errorMessage = "Выберите клиента"
            showError = true
            return
        }
        
        guard let count = Int(lessonCount), count > 0 else {
            errorMessage = "Введите корректное количество уроков"
            showError = true
            return
        }
        
        guard let price = Double(totalPrice), price > 0 else {
            errorMessage = "Введите корректную стоимость абонемента"
            showError = true
            return
        }
        
        // Check if start date is too far in the future
        let maxFutureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        if startDate > maxFutureDate {
            errorMessage = "Дата начала не может быть более чем на месяц в будущем"
            showError = true
            return
        }
        
        // Check if start date is too far in the past (more than 2 years)
        let minPastDate = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        if startDate < minPastDate {
            errorMessage = "Дата начала не может быть более чем 2 года назад"
            showError = true
            return
        }
        
        onCreate(selectedClientId, count, price, startDate)
        presentationMode.wrappedValue.dismiss()
    }
}
