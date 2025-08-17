import SwiftUI

struct HistoryView: View {
    let lessons: [Lesson]
    let clients: [Client]
    
    @Environment(\.presentationMode) var presentationMode
    
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
                
                Text("История доходов")
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
            
            // History content
            if monthlyData.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("Нет данных о доходах")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("История доходов появится после проведения уроков")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(yearlyData, id: \.year) { yearData in
                            VStack(spacing: 0) {
                                // Year header
                                HStack {
                                    Text("\(yearData.year)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("Итого: \(String(format: "%.2f", yearData.totalAmount)) руб.")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(Color(.controlBackgroundColor))
                                
                                // Monthly data for this year
                                ForEach(yearData.months, id: \.month) { monthData in
                                    VStack(spacing: 0) {
                                        HStack {
                                            Text(monthData.monthName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text("\(String(format: "%.2f", monthData.amount)) руб.")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        
                                        Divider()
                                    }
                                }
                            }
                            .background(Color(.windowBackgroundColor))
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.bottom)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    // MARK: - Data Processing
    
    private var monthlyData: [MonthlyIncome] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        
        // Group completed lessons by month
        var monthlyIncome: [String: Double] = [:]
        
        for lesson in lessons where lesson.isCompleted {
            guard let conductedAt = lesson.conductedAt else { continue }
            
            let year = calendar.component(.year, from: conductedAt)
            let month = calendar.component(.month, from: conductedAt)
            let key = "\(year)-\(month)"
            
            monthlyIncome[key, default: 0] += lesson.price
        }
        
        // Convert to MonthlyIncome objects
        return monthlyIncome.map { key, amount in
            let components = key.split(separator: "-")
            let year = Int(components[0]) ?? 0
            let month = Int(components[1]) ?? 0
            
            let monthName = dateFormatter.monthSymbols[month - 1]
            return MonthlyIncome(year: year, month: month, monthName: monthName, amount: amount)
        }.sorted { $0.year > $1.year || ($0.year == $1.year && $0.month > $1.month) }
    }
    
    private var yearlyData: [YearlyData] {
        let groupedByYear = Dictionary(grouping: monthlyData) { $0.year }
        
        return groupedByYear.map { year, months in
            let totalAmount = months.reduce(0) { $0 + $1.amount }
            return YearlyData(year: year, months: months.sorted { $0.month > $1.month }, totalAmount: totalAmount)
        }.sorted { $0.year > $1.year }
    }
}

// MARK: - Data Models

struct MonthlyIncome {
    let year: Int
    let month: Int
    let monthName: String
    let amount: Double
}

struct YearlyData {
    let year: Int
    let months: [MonthlyIncome]
    let totalAmount: Double
}

// MARK: - Preview

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleLessons = [
            Lesson(id: 1, clientId: 1, subscriptionId: 1, number: 1, price: 1000, createdAt: Date(), conductedAt: Date(), isCompleted: true),
            Lesson(id: 2, clientId: 1, subscriptionId: 1, number: 2, price: 1500, createdAt: Date(), conductedAt: Calendar.current.date(byAdding: .month, value: -1, to: Date()), isCompleted: true),
            Lesson(id: 3, clientId: 2, subscriptionId: 2, number: 1, price: 2000, createdAt: Date(), conductedAt: Calendar.current.date(byAdding: .year, value: -1, to: Date()), isCompleted: true)
        ]
        
        let sampleClients = [
            Client(id: 1, firstName: "Иван", lastName: "Иванов", phone: nil, telegram: nil, email: nil, additionalInfo: nil, createdAt: Date(), updatedAt: Date()),
            Client(id: 2, firstName: "Петр", lastName: "Петров", phone: nil, telegram: nil, email: nil, additionalInfo: nil, createdAt: Date(), updatedAt: Date())
        ]
        
        return HistoryView(lessons: sampleLessons, clients: sampleClients)
    }
}
