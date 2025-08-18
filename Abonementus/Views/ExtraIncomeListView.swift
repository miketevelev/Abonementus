import SwiftUI

struct ExtraIncomeListView: View {
    let incomes: [ExtraIncome]
    let categories: [IncomeCategory]
    let onCreate: () -> Void
    let onEdit: (ExtraIncome) -> Void
    let onDelete: (Int64) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Доп доход")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
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
                    }
                }
                
                Spacer()
                
                Button(action: onCreate) {
                    Label("Добавить", systemImage: "plus.circle")
                        .padding(8)
                }
                .buttonStyle(YellowButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top)
            
            // List
            List {
                Section(header: HStack {
                    Text("Записи")
                    Spacer()
                }) {
                    ForEach(filteredIncomes, id: \.id) { income in
                        incomeRow(for: income)
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
    }
    
    private var availableYears: [Int] {
        let cal = Calendar.current
        let years = incomes.map { cal.component(.year, from: $0.receivedAt) }
        return Array(Set(years)).sorted(by: >)
    }
    
    private var availableMonths: [Int] {
        let cal = Calendar.current
        let months = incomes.compactMap { inc -> Int? in
            let y = cal.component(.year, from: inc.receivedAt)
            if y == selectedYear { return cal.component(.month, from: inc.receivedAt) }
            return nil
        }
        return Array(Set(months)).sorted()
    }
    
    private var filteredIncomes: [ExtraIncome] {
        let cal = Calendar.current
        return incomes.filter { inc in
            guard cal.component(.year, from: inc.receivedAt) == selectedYear else { return false }
            if let m = selectedMonth, cal.component(.month, from: inc.receivedAt) != m { return false }
            return true
        }.sorted { $0.receivedAt > $1.receivedAt }
    }
    
    private func categoryName(for id: Int64) -> String {
        categories.first(where: { $0.id == id })?.name ?? "Категория"
    }
    
    private func monthName(for month: Int) -> String {
        let monthNames = [
            1: "Январь", 2: "Февраль", 3: "Март", 4: "Апрель",
            5: "Май", 6: "Июнь", 7: "Июль", 8: "Август",
            9: "Сентябрь", 10: "Октябрь", 11: "Ноябрь", 12: "Декабрь"
        ]
        return monthNames[month] ?? String(month)
    }
    
    private func incomeRow(for income: ExtraIncome) -> some View {
        return HStack {
            // Category info and amount
            VStack(alignment: .leading, spacing: 4) {
                Text(categoryName(for: income.categoryId))
                    .font(.headline)
                
                Text("\(String(format: "%.2f", income.amount)) руб.")
                    .font(.subheadline)
            }
            .frame(width: 200, alignment: .leading)
            
            // Dates info - aligned to left with 190px margin from right
            VStack(alignment: .leading, spacing: 4) {
                Text("Получен: \(income.receivedAt.toString())")
                Text("Создан: \(income.createdAt.toString())")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 150)
            .padding(.trailing, 190)

            // Actions
            HStack(spacing: 8) {
                Button(action: { onEdit(income) }) {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                        .padding(6)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { onDelete(income.id) }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                        .padding(6)
                        .background(Color.red.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.trailing, 1)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
    }
}


