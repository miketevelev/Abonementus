import SwiftUI

struct SubscriptionListView: View {
    let subscriptions: [Subscription]
    let clients: [Client]
    let getLessons: (Int64) -> [Lesson]
    let onDelete: (Int64) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int? = nil
    @State private var selectedClientId: Int64? = nil
    @State private var showDeleteConfirmation = false
    @State private var subscriptionToDelete: Int64?
    
    var body: some View {
            VStack(spacing: 0) {
                // Top bar 50px
                HStack {
                    Text("Все абонементы")
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
                    
                    // Month filter (completed subscriptions months)
                    Picker("Месяц", selection: $selectedMonth) {
                        Text("Все месяцы").tag(nil as Int?)
                        ForEach(availableMonths, id: \.self) { month in
                            Text(monthName(for: month)).tag(Optional(month))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 140)
                    
                    // Client filter
                    Picker("Клиент", selection: $selectedClientId) {
                        Text("Все клиенты").tag(nil as Int64?)
                        ForEach(clients.sorted { $0.fullName < $1.fullName }, id: \.id) { client in
                            Text(client.fullName).tag(Optional(client.id))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 220)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                
                Spacer()
                
                // Subscriptions list
                List {
                    // Active subscriptions
                    Section(header: Text("Активные абонементы")) {
                        ForEach(filteredActiveSubscriptions, id: \.id) { subscription in
                            subscriptionRow(for: subscription)
                        }
                    }
                    
                    // Inactive subscriptions
                    Section(header: Text("Завершенные абонементы")) {
                        ForEach(filteredInactiveSubscriptions, id: \.id) { subscription in
                            subscriptionRow(for: subscription)
                        }
                    }
                }
                .padding(.horizontal, 20)
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.bordered(alternatesRowBackgrounds: true))
                #endif
            }
            .frame(minWidth: 900, minHeight: 500)
            .alert("Подтверждение удаления", isPresented: $showDeleteConfirmation) {
                Button("Отмена", role: .cancel) { }
                Button("Удалить", role: .destructive) {
                    if let subscriptionId = subscriptionToDelete {
                        onDelete(subscriptionId)
                        subscriptionToDelete = nil
                    }
                }
            } message: {
                if let subscriptionId = subscriptionToDelete,
                   let subscription = subscriptions.first(where: { $0.id == subscriptionId }),
                   let client = clients.first(where: { $0.id == subscription.clientId }) {
                    Text("Вы уверены, что хотите удалить абонемент для клиента \(client.fullName)?")
                } else {
                    Text("Вы уверены, что хотите удалить абонемент?")
                }
            }
        }
    
    private var activeSubscriptions: [Subscription] {
        subscriptions.filter { $0.isActive }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    private var inactiveSubscriptions: [Subscription] {
        subscriptions.filter { !$0.isActive }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    private var availableYears: [Int] {
        let calendar = Calendar.current
        let years = subscriptions.map { calendar.component(.year, from: $0.createdAt) }
        return Array(Set(years)).sorted(by: >)
    }
    
    private var availableMonths: [Int] {
        let calendar = Calendar.current
        let months = subscriptions.compactMap { subscription -> Int? in
            if let closedAt = subscription.closedAt {
                let year = calendar.component(.year, from: closedAt)
                if year == selectedYear { return calendar.component(.month, from: closedAt) }
            }
            return nil
        }
        return Array(Set(months)).sorted()
    }
    
    private var filteredActiveSubscriptions: [Subscription] {
        let calendar = Calendar.current
        return activeSubscriptions.filter { subscription in
            // Year filter by createdAt for active subscriptions
            guard calendar.component(.year, from: subscription.createdAt) == selectedYear else { return false }
            // Client filter
            if let clientId = selectedClientId, subscription.clientId != clientId { return false }
            // Month filter applies to closedAt; active subs have no closedAt, include when month not selected
            if selectedMonth != nil { return false }
            return true
        }
    }
    
    private var filteredInactiveSubscriptions: [Subscription] {
        let calendar = Calendar.current
        return inactiveSubscriptions.filter { subscription in
            // Prefer closedAt; if month filter is active, require closedAt to exist
            if let month = selectedMonth {
                guard let closedAt = subscription.closedAt else { return false }
                guard calendar.component(.year, from: closedAt) == selectedYear else { return false }
                if calendar.component(.month, from: closedAt) != month { return false }
            } else {
                let dateForFilter = subscription.closedAt ?? subscription.createdAt
                guard calendar.component(.year, from: dateForFilter) == selectedYear else { return false }
            }
            if let clientId = selectedClientId, subscription.clientId != clientId { return false }
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
    
    private func subscriptionRow(for subscription: Subscription) -> some View {
        let client = clients.first { $0.id == subscription.clientId }
        
        return VStack(alignment: .leading, spacing: 8) {
            // Client info and price
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(client?.fullName ?? "Неизвестный клиент")
                            .font(.headline)
                        
                        // Status tag
                        Text(subscription.statusTag)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(getStatusColor(for: subscription))
                            .cornerRadius(4)
                    }
                    
                    Text("\(subscription.lessonCount) урок(ов) - \(String(format: "%.2f", subscription.totalPrice)) руб.")
                        .font(.subheadline)
                }
                
                Spacer()
                
                // Dates info
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Начало: \(subscription.createdAt.toString(format: "dd.MM.yyyy"))")
                    Text("Окончание: \(subscription.closedAt?.toString(format: "dd.MM.yyyy") ?? "—")")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            // Progress bar
            VStack(spacing: 4) {
                HStack {
                    Text("Прогресс:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(completedLessonsCount(for: subscription))/\(subscription.lessonCount) уроков")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progressValue(for: subscription))
                    .accentColor(getStatusColor(for: subscription))
            }
            
            // Delete button
            HStack {
                Spacer()
                
                Button(action: {
                    subscriptionToDelete = subscription.id
                    showDeleteConfirmation = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .padding(6)
                            .background(Color.red.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Удалить абонемент")
                    }
                    .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(getStatusColor(for: subscription).opacity(0.05))
        .cornerRadius(6)
    }
    
    private func progressValue(for subscription: Subscription) -> Double {
        let lessons = getLessons(subscription.id)
        let completedLessons = lessons.filter { $0.isCompleted }.count
        let totalLessons = subscription.lessonCount
        
        guard totalLessons > 0 else { return 0 }
        return Double(completedLessons) / Double(totalLessons)
    }
    
    private func completedLessonsCount(for subscription: Subscription) -> Int {
        let lessons = getLessons(subscription.id)
        return lessons.filter { $0.isCompleted }.count
    }
    
    private func getStatusColor(for subscription: Subscription) -> Color {
        switch subscription.statusColor {
        case "red":
            return .red
        case "green":
            return .green
        case "orange":
            return .orange
        case "blue":
            return .blue
        case "gray":
            return .gray
        default:
            return .gray
        }
    }
}

// Предварительный просмотр для Xcode
struct SubscriptionListView_Previews: PreviewProvider {
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
        
        let sampleSubscriptions = [
            Subscription(
                id: 1,
                clientId: 1,
                lessonCount: 8,
                totalPrice: 6400,
                createdAt: Date(),
                closedAt: Date().adding(days: 30),
                isActive: true
            ),
            Subscription(
                id: 2,
                clientId: 1,
                lessonCount: 4,
                totalPrice: 3200,
                createdAt: Date().addingTimeInterval(-86400 * 35),
                closedAt: Date().addingTimeInterval(-86400 * 5),
                isActive: false
            )
        ]
        
        return SubscriptionListView(
            subscriptions: sampleSubscriptions,
            clients: [sampleClient],
            getLessons: { _ in [] },
            onDelete: { _ in }
        )
    }
}
