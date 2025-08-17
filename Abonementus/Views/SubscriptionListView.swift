import SwiftUI

struct SubscriptionListView: View {
    let subscriptions: [Subscription]
    let clients: [Client]
    let getLessons: (Int64) -> [Lesson]
    let onDelete: (Int64) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
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
                        Text("Все абонементы")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if availableYears.count > 1 {
                            Picker("Год", selection: $selectedYear) {
                                ForEach(availableYears, id: \.self) { year in
                                    Text("\(year)").tag(year)
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
            .frame(minWidth: 700, minHeight: 500)
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
    
    private var filteredActiveSubscriptions: [Subscription] {
        let calendar = Calendar.current
        return activeSubscriptions.filter { subscription in
            calendar.component(.year, from: subscription.createdAt) == selectedYear
        }
    }
    
    private var filteredInactiveSubscriptions: [Subscription] {
        let calendar = Calendar.current
        return inactiveSubscriptions.filter { subscription in
            calendar.component(.year, from: subscription.createdAt) == selectedYear
        }
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
                
                Button(action: { onDelete(subscription.id) }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Удалить абонемент")
                    }
                    .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
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
