import SwiftUI

struct IncomeCategoryManageView: View {
    let categories: [IncomeCategory]
    let onCreate: (String) -> Void
    let onDelete: (Int64) -> Void
    let onClose: () -> Void
    
    @State private var newName: String = ""
    
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
            
            Form {
                Section(header: Text("Новая категория")) {
                    TextField("Название", text: $newName)
                }
                
                Section(header: Text("Список категорий")) {
                    List {
                        ForEach(categories, id: \.id) { cat in
                            HStack {
                                Text(cat.name)
                                Spacer()
                                Button(action: { onDelete(cat.id) }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .font(.system(size: 14))
                                        .padding(6)
                                        .background(Color.red.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .frame(minHeight: 200)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}


