import SwiftUI

struct ClientListView: View {
    let clients: [Client]
    @Binding var selectedClient: Client?
    @Binding var showClientEdit: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and add button
            HStack {
                Text("Клиенты")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    // Create a new client and set it as selected
                    let newClient = Client(
                        id: 0,
                        firstName: "",
                        lastName: nil,
                        phone: nil,
                        telegram: nil,
                        email: nil,
                        additionalInfo: nil,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    selectedClient = newClient
                    showClientEdit = true
                }) {
                    Label("Создать", systemImage: "plus.circle")
                        .padding(8)
                }
                .buttonStyle(BlueButtonStyle())
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Divider line below title
            Divider()
                .padding(.horizontal)
                .padding(.top, 10)
            
            // Clients list
            if clients.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                        .padding(12)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Text("Нет клиентов")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Создайте первого клиента для начала работы")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(clients.sorted(by: { $0.fullName < $1.fullName }), id: \.id) { client in
                            ClientRow(client: client)
                                .frame(height: 50)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedClient = client
                                    showClientEdit = true
                                }
                            Divider()
                        }
                    }
                }
            }
        }
        .background(Color(.windowBackgroundColor))
    }
}

struct ClientRow: View {
    let client: Client
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(client.fullName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                if let phone = client.phone {
                    Text(phone)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
