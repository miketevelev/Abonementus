import SwiftUI

struct ClientListView: View {
    let clients: [Client]
    @Binding var selectedClient: Client?
    @Binding var filteredClient: Client?
    
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
                            ClientRow(
                                client: client,
                                isFiltered: filteredClient?.id == client.id,
                                onTap: {
                                    if filteredClient?.id == client.id {
                                        // Toggle filter off
                                        filteredClient = nil
                                    } else {
                                        // Set as filtered client
                                        filteredClient = client
                                    }
                                },
                                onEdit: {
                                    selectedClient = client
                                }
                            )
                            .frame(height: 50)
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
    let isFiltered: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(client.fullName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(isFiltered ? .white : .primary)
                
                if let phone = client.phone {
                    Text(phone)
                        .font(.subheadline)
                        .foregroundColor(isFiltered ? .white.opacity(0.8) : .secondary)
                }
            }
            
            Spacer()
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil.circle")
                    .foregroundColor(isFiltered ? .white : .blue)
                    .font(.system(size: 14))
                    .padding(6)
                    .background(isFiltered ? Color.white.opacity(0.2) : Color.blue.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isFiltered ? Color.blue : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}
