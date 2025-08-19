import SwiftUI

struct HistoryView: View {
    let lessons: [Lesson]
    let clients: [Client]
    var extraIncomes: [ExtraIncome] = []
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar 50px
            HStack {
                Text("История доходов")
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
            
            Spacer()
            
            // History content
            if monthlyData.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                        .padding(12)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
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
                                    Text(String(yearData.year))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("Основной: \(String(format: "%.2f", yearData.totalAmount)) руб. | Доп: \(String(format: "%.2f", yearData.totalExtraAmount)) руб. | Общий: \(String(format: "%.2f", yearData.totalAmount + yearData.totalExtraAmount)) руб.")
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
                                            Text("Основной: \(String(format: "%.2f", monthData.amount)) руб. | Доп: \(String(format: "%.2f", monthData.extraAmount)) руб. | Общий: \(String(format: "%.2f", monthData.amount + monthData.extraAmount)) руб.")
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
        .frame(minWidth: 700, minHeight: 400)
    }
    
    // MARK: - Data Processing
    
    private var monthlyData: [MonthlyIncome] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        
        // Group completed lessons by month
        var monthlyIncome: [String: Double] = [:]
        var monthlyExtra: [String: Double] = [:]
        
        for lesson in lessons where lesson.isCompleted {
            guard let conductedAt = lesson.conductedAt else { continue }
            
            let year = calendar.component(.year, from: conductedAt)
            let month = calendar.component(.month, from: conductedAt)
            let key = "\(year)-\(month)"
            
            monthlyIncome[key, default: 0] += lesson.price
        }
        
        // Include extra incomes
        for inc in extraIncomes {
            let year = calendar.component(.year, from: inc.receivedAt)
            let month = calendar.component(.month, from: inc.receivedAt)
            let key = "\(year)-\(month)"
            monthlyExtra[key, default: 0] += inc.amount
        }
        
        // Convert to MonthlyIncome objects (include months having only extra incomes)
        let allKeys = Set(monthlyIncome.keys).union(monthlyExtra.keys)
        return allKeys.map { key in
            let components = key.split(separator: "-")
            let year = Int(components[0]) ?? 0
            let month = Int(components[1]) ?? 0
            let monthIndex = max(1, min(12, month))
            let monthNames = [
                1: "Январь", 2: "Февраль", 3: "Март", 4: "Апрель",
                5: "Май", 6: "Июнь", 7: "Июль", 8: "Август",
                9: "Сентябрь", 10: "Октябрь", 11: "Ноябрь", 12: "Декабрь"
            ]
            let monthName = monthNames[monthIndex] ?? String(monthIndex)
            let main = monthlyIncome[key] ?? 0
            let extra = monthlyExtra[key] ?? 0
            return MonthlyIncome(year: year, month: monthIndex, monthName: monthName, amount: main, extraAmount: extra)
        }.sorted { $0.year > $1.year || ($0.year == $1.year && $0.month > $1.month) }
    }
    
    private var yearlyData: [YearlyData] {
        let groupedByYear = Dictionary(grouping: monthlyData) { $0.year }
        
        return groupedByYear.map { year, months in
            let totalAmount = months.reduce(0) { $0 + $1.amount }
            let totalExtraAmount = months.reduce(0) { $0 + $1.extraAmount }
            return YearlyData(year: year, months: months.sorted { $0.month > $1.month }, totalAmount: totalAmount, totalExtraAmount: totalExtraAmount)
        }.sorted { $0.year > $1.year }
    }
}

// MARK: - Data Models

struct MonthlyIncome {
    let year: Int
    let month: Int
    let monthName: String
    let amount: Double
    let extraAmount: Double
}

struct YearlyData {
    let year: Int
    let months: [MonthlyIncome]
    let totalAmount: Double
    let totalExtraAmount: Double
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
