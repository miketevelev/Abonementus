import SwiftUI

struct SubscriptionMainView: View {
    let subscriptions: [Subscription]
    let clients: [Client]
    let getLessons: (Int64) -> [Lesson]
    let completedAmount: Double
    let pendingAmount: Double
    let extraAmount: Double
    
    @Binding var showSubscriptionCreate: Bool
    @Binding var showLessonCreate: Bool
    @Binding var showAllSubscriptions: Bool
    @Binding var showAllLessons: Bool
    @Binding var showHistory: Bool
    @Binding var showExtraIncome: Bool
    
    let onLessonTap: (Lesson) -> Void
    let onLessonUncomplete: (Lesson) -> Void
    let onRefresh: () -> Void
    
    @State private var showCompletedAmount = false
    @State private var showPendingAmount = false
    @State private var showExtraAmount = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with buttons
            headerView
            
            // Amount indicators
            amountIndicatorsView
            
            // Subscriptions list
            subscriptionsListView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var headerView: some View {
        HStack {
            Text("Абонементы")
                .font(.headline)
                .fontWeight(.bold)
            
            // Update icon
            Button(action: {
                print("Manual refresh triggered")
                onRefresh()
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                    .padding(6)
                    .background(Color.blue.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(PlainButtonStyle())

            // Backup icon
            Button(action: {
                let ok = Database.shared.backupDatabaseToDocumentsZip()
                if ok {
                    print("Backup completed successfully")
                } else {
                    print("Backup failed")
                }
            }) {
                Image(systemName: "externaldrive.fill.badge.plus")
                    .foregroundColor(.purple)
                    .font(.system(size: 14))
                    .padding(6)
                    .background(Color.purple.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { showSubscriptionCreate = true }) {
                    Label("Абонемент", systemImage: "plus.circle")
                        .padding(8)
                }
                .buttonStyle(BlueButtonStyle())
                
                Button(action: { showAllSubscriptions = true }) {
                    Label("Абонементы", systemImage: "list.bullet")
                        .padding(8)
                }
                .buttonStyle(BlueButtonStyle())
                
                Button(action: { showLessonCreate = true }) {
                    Label("Урок", systemImage: "plus.circle")
                        .padding(8)
                }
                .buttonStyle(YellowButtonStyle())
                
                Button(action: { showAllLessons = true }) {
                    Label("Уроки", systemImage: "list.bullet")
                        .padding(8)
                }
                .buttonStyle(YellowButtonStyle())
                
                Button(action: { showHistory = true }) {
                    Label("Доходы", systemImage: "chart.line.uptrend.xyaxis")
                        .padding(8)
                }
                .buttonStyle(BrownButtonStyle())

                // Extra income button
                Button(action: { showExtraIncome = true }) {
                    Label("Доп", systemImage: "plus.rectangle.on.rectangle")
                        .padding(8)
                }
                .buttonStyle(BrownButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var amountIndicatorsView: some View {
        HStack(spacing: 20) {
            AmountIndicator(
                title: "Отработанная сумма",
                amount: completedAmount,
                isShowing: $showCompletedAmount,
                color: .green
            )
            
            AmountIndicator(
                title: "Не отработанная",
                amount: pendingAmount,
                isShowing: $showPendingAmount,
                color: .orange
            )

            AmountIndicator(
                title: "Доп заработок",
                amount: extraAmount,
                isShowing: $showExtraAmount,
                color: .purple
            )
        }
        .padding()
    }
    
    private var subscriptionsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(subscriptions.sorted { subscription1, subscription2 in
                    let client1 = getClient(for: subscription1.clientId)
                    let client2 = getClient(for: subscription2.clientId)
                    let name1 = client1?.fullName ?? "Неизвестный клиент"
                    let name2 = client2?.fullName ?? "Неизвестный клиент"
                    return name1 < name2
                }) { subscription in
                    SubscriptionCard(
                        subscription: subscription,
                        client: getClient(for: subscription.clientId),
                        lessons: getLessons(subscription.id),
                        onLessonTap: onLessonTap,
                        onLessonUncomplete: onLessonUncomplete
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private func getClient(for clientId: Int64) -> Client? {
        return clients.first { $0.id == clientId }
    }
}

struct SubscriptionCard: View {
    let subscription: Subscription
    let client: Client?
    let lessons: [Lesson]
    let onLessonTap: (Lesson) -> Void
    let onLessonUncomplete: (Lesson) -> Void
    
    private var completedCount: Int {
        lessons.filter { $0.isCompleted }.count
    }
    
    private var clientName: String {
        if let client = client {
            if let lastName = client.lastName {
                return "\(client.firstName) \(lastName)"
            } else {
                return client.firstName
            }
        }
        return "Неизвестный клиент"
    }
    
    private var statusColor: Color {
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with client info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(clientName)
                        .font(.headline)
                    
                    Text("\(String(format: "%.2f", subscription.totalPrice)) руб.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Начало: \(subscription.createdAt.toString(format: "dd.MM.yyyy"))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(completedCount)/\(subscription.lessonCount)")
                        .font(.system(size: 16, weight: .bold))
                    
                    // Status tag
                    Text(subscription.statusTag)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor)
                        .cornerRadius(4)
                }
            }
            .padding()
            .background(statusColor.opacity(0.1))
            
            // Lessons grid
            lessonsGrid
        }
        .background(Color(.windowBackgroundColor))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(statusColor.opacity(0.6), lineWidth: 1)
        )
        .opacity(subscription.isActive ? 1.0 : 0.7) // Finished subscriptions are slightly transparent
    }
    
    private var lessonsGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 5)
        let sortedLessons = lessons.sorted(by: { $0.number < $1.number })
        
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(sortedLessons) { lesson in
                LessonBlock(lesson: lesson, subscription: subscription)
                    .onTapGesture {
                        // Allow tapping on incomplete lessons for active subscriptions
                        if !lesson.isCompleted && subscription.isActive {
                            onLessonTap(lesson)
                        } else if lesson.isCompleted {
                            // Allow uncompleting completed lessons
                            onLessonUncomplete(lesson)
                        }
                    }
            }
        }
        .padding(8)
    }
}

struct LessonBlock: View {
    let lesson: Lesson
    let subscription: Subscription
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(blockColor)
                .frame(height: 30)
            
            Text(blockText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(blockTextColor)
        }
    }
    
    private var blockColor: Color {
        if !subscription.isActive {
            return .gray.opacity(0.3) // Finished subscription - gray
        } else if lesson.isCompleted {
            return .green // Completed lesson
        } else {
            return .gray.opacity(0.2) // Incomplete lesson
        }
    }
    
    private var blockText: String {
        if !subscription.isActive {
            return "✓" // Finished subscription - show checkmark
        } else if lesson.isCompleted {
            return "✓" // Completed lesson
        } else {
            return "\(lesson.number)" // Incomplete lesson - show number
        }
    }
    
    private var blockTextColor: Color {
        if !subscription.isActive {
            return .gray // Finished subscription - gray text
        } else if lesson.isCompleted {
            return .white // Completed lesson - white text
        } else {
            return .primary // Incomplete lesson - primary text color
        }
    }
}

struct AmountIndicator: View {
    let title: String
    let amount: Double
    @Binding var isShowing: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(isShowing ? String(format: "%.2f руб.", amount) : "•••")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
                .onTapGesture {
                    isShowing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        isShowing = false
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// Preview
struct SubscriptionMainView_Previews: PreviewProvider {
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
            Lesson(id: 1, clientId: 1, subscriptionId: 1, number: 1, price: 1000, createdAt: Date(), conductedAt: nil, isCompleted: false),
            Lesson(id: 2, clientId: 1, subscriptionId: 1, number: 2, price: 1000, createdAt: Date(), conductedAt: Date(), isCompleted: true)
        ]
        
        let sampleSubscriptions = [
            Subscription(
                id: 1,
                clientId: 1,
                lessonCount: 8,
                totalPrice: 8000,
                createdAt: Date(),
                closedAt: Date().addingTimeInterval(86400 * 30),
                isActive: true
            ),
            Subscription(
                id: 2,
                clientId: 1,
                lessonCount: 4,
                totalPrice: 4000,
                createdAt: Date().addingTimeInterval(-86400 * 35),
                closedAt: Date().addingTimeInterval(-86400 * 5),
                isActive: false
            )
        ]
        
        return SubscriptionMainView(
            subscriptions: sampleSubscriptions,
            clients: [sampleClient],
            getLessons: { _ in sampleLessons },
            completedAmount: 1500,
            pendingAmount: 6500,
            extraAmount: 0,
            showSubscriptionCreate: .constant(false),
            showLessonCreate: .constant(false),
            showAllSubscriptions: .constant(false),
            showAllLessons: .constant(false),
            showHistory: .constant(false),
            showExtraIncome: .constant(false),
            onLessonTap: { _ in },
            onLessonUncomplete: { _ in },
            onRefresh: {}
        )
        .frame(width: 800, height: 600)
        .padding()
    }
}
