import SwiftUI

struct ExtraIncomeEditView: View {
    var income: ExtraIncome?
    var categories: [IncomeCategory]
    let onSave: (Int64, Double, Date) -> Void
    let onCancel: () -> Void
    let onCreateCategory: () -> Void
    
    @State private var selectedCategoryId: Int64?
    @State private var amountText: String = ""
    @State private var receivedAt: Date = Date()
    
    init(income: ExtraIncome?, categories: [IncomeCategory], onSave: @escaping (Int64, Double, Date) -> Void, onCancel: @escaping () -> Void, onCreateCategory: @escaping () -> Void) {
        self.income = income
        self.categories = categories
        self.onSave = onSave
        self.onCancel = onCancel
        self.onCreateCategory = onCreateCategory
        
        _selectedCategoryId = State(initialValue: income?.categoryId)
        _amountText = State(initialValue: income != nil ? String(format: "%.2f", income!.amount) : "")
        _receivedAt = State(initialValue: income?.receivedAt ?? Date())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar 50px
            HStack {
                Text(income == nil ? "Создание доп дохода" : "Редактирование доп дохода")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: onCancel) {
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
            
            Form {
                Section(header: Text("Данные дохода")) {
                    HStack(spacing: 8) {
                        Picker("Категория", selection: Binding(
                            get: { selectedCategoryId ?? categories.first?.id },
                            set: { selectedCategoryId = $0 }
                        )) {
                            ForEach(categories, id: \.id) { cat in
                                Text(cat.name).tag(Optional(cat.id))
                            }
                        }
                        .frame(minWidth: 220)
                        
                        Button(action: onCreateCategory) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                                .padding(6)
                                .background(Color.blue.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    TextField("Сумма", text: $amountText)
                        .textFieldStyle(.roundedBorder)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                    
                    HStack {
                        Text("Дата получения")
                        Spacer()
                        DatePicker("", selection: $receivedAt, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            
            // Bottom save
            HStack {
                Spacer()
                Button(action: save) {
                    Label("Сохранить", systemImage: "checkmark.circle")
                        .padding(8)
                }
                .buttonStyle(GreenButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .frame(minWidth: 500, minHeight: 280)
    }
    
    private func save() {
        guard let categoryId = selectedCategoryId ?? categories.first?.id else { return }
        let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        onSave(categoryId, amount, receivedAt)
    }
}


