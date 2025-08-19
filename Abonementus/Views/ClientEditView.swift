import SwiftUI

struct ClientEditView: View {
    @State var client: Client
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDeleteConfirmation = false
    let onSave: (Client) -> Void
    let onDelete: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar 50px
            HStack {
                Text(client.id == 0 ? "Создание клиента" : "Редактирование клиента")
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
            
            // Form
            Form {
                Section(header: Text("Основная информация")) {
                    TextField("Имя", text: $client.firstName)
                    TextField("Фамилия", text: Binding(
                        get: { client.lastName ?? "" },
                        set: { client.lastName = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                Section(header: Text("Контакты")) {
                    TextField("Телефон", text: Binding(
                        get: { client.phone ?? "" },
                        set: { client.phone = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Telegram", text: Binding(
                        get: { client.telegram ?? "" },
                        set: { client.telegram = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Email", text: Binding(
                        get: { client.email ?? "" },
                        set: { client.email = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                Section(header: Text("Дополнительно")) {
                    TextEditor(text: Binding(
                        get: { client.additionalInfo ?? "" },
                        set: { client.additionalInfo = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(height: 100)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            
            // Bottom actions
            HStack(spacing: 12) {
                Button(action: {
                        // Validate form
                        guard !client.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            errorMessage = "Имя клиента обязательно для заполнения"
                            showError = true
                            return
                        }
                        
                        let updatedClient = Client(
                            id: client.id,
                            firstName: client.firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                            lastName: client.lastName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? client.lastName?.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                            phone: client.phone?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? client.phone?.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                            telegram: client.telegram?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? client.telegram?.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                            email: client.email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? client.email?.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                            additionalInfo: client.additionalInfo?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? client.additionalInfo?.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                            createdAt: client.createdAt,
                            updatedAt: Date()
                        )
                        onSave(updatedClient)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Сохранить", systemImage: "checkmark.circle")
                            .padding(8)
                    }
                    .buttonStyle(GreenButtonStyle())
                    
                    if client.id != 0 {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Label("Удалить", systemImage: "trash")
                                .padding(8)
                        }
                        .buttonStyle(RedButtonStyle())
                    }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .frame(minWidth: 500, minHeight: 200)
        .alert(isPresented: $showError) {
            Alert(title: Text("Ошибка"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .alert("Подтверждение удаления", isPresented: $showDeleteConfirmation) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                onDelete()
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Вы уверены, что хотите удалить клиента \(client.fullName)?")
        }
    }
}
