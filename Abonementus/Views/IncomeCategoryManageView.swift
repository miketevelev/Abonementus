import SwiftUI

struct IncomeCategoryManageView: View {
    let categories: [IncomeCategory]
    let onCreate: (String) -> Void
    let onDelete: (Int64) -> Void
    let onClose: () -> Void
    
    @State private var newName: String = ""
    @State private var showDeleteConfirmation = false
    @State private var categoryIdToDelete: Int64? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text("Категории дохода")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    onCreate(name)
                    newName = ""
                }) {
                    Label("Добавить", systemImage: "checkmark.circle")
                        .padding(8)
                }
                .buttonStyle(GreenButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top)
            
            // Create form
            Form {
                Section(header: Text("Новая категория")) {
                    TextField("Название", text: $newName)
                }
            }
            .padding(.horizontal, 20)

            Divider()
                .padding(.vertical, 8)

            // Styled category list
            VStack(alignment: .leading, spacing: 12) {
                Text("Существующие категории")
                    .font(.headline)
                    .padding(.horizontal, 20)
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(categories, id: \.id) { cat in
                            HStack {
                                Text(cat.name)
                                    .font(.body)
                                Spacer()
                                Button(action: {
                                    categoryIdToDelete = cat.id
                                    showDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .font(.system(size: 14))
                                        .padding(6)
                                        .background(Color.red.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .alert("Подтверждение удаления", isPresented: $showDeleteConfirmation) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                if let id = categoryIdToDelete { onDelete(id) }
                categoryIdToDelete = nil
            }
        } message: {
            Text("Удалить категорию? Все связанные доп доходы будут удалены.")
        }
    }
}


