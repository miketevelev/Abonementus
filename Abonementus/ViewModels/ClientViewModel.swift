import SQLite
import Combine
import Foundation

class ClientViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var isLoading = false
    private var db: Connection?
    
    var onClientsChanged: (() -> Void)?
    
    init() {
        db = Database.shared.getConnection()
        // Don't fetch immediately - let the view control when to load
    }
    
    func setOnClientsChanged(_ callback: @escaping () -> Void) {
        self.onClientsChanged = callback
    }
    
    func fetchClients() {
        guard let db = db else { 
            print("ClientViewModel: No database connection available")
            return 
        }
        
        if isLoading {
            print("ClientViewModel: Already loading, skipping fetch")
            return
        }
        
        print("ClientViewModel: Starting to fetch clients...")
        isLoading = true
        
        // Add timeout to prevent infinite loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            if self?.isLoading == true {
                print("ClientViewModel: Loading timeout reached, forcing loading to false")
                self?.isLoading = false
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                print("ClientViewModel: Executing database query...")
                let fetchedClients = try db.prepare(Client.table).map { row in
                    Client(
                        id: row[Client.id],
                        firstName: row[Client.firstName],
                        lastName: row[Client.lastName],
                        phone: row[Client.phone],
                        telegram: row[Client.telegram],
                        email: row[Client.email],
                        additionalInfo: row[Client.additionalInfo],
                        createdAt: row[Client.createdAt],
                        updatedAt: row[Client.updatedAt]
                    )
                }
                
                print("ClientViewModel: Fetched \(fetchedClients.count) clients from database")
                
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.clients = fetchedClients
                    print("ClientViewModel: Updated clients array with \(fetchedClients.count) clients, loading set to false")
                }
            } catch {
                print("ClientViewModel: Error fetching clients: \(error)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    print("ClientViewModel: Set loading to false due to error")
                }
            }
        }
    }
    
    func addClient(client: Client) {
        guard let db = db else { return }
        
        do {
            let insert = Client.table.insert(
                Client.firstName <- client.firstName,
                Client.lastName <- client.lastName,
                Client.phone <- client.phone,
                Client.telegram <- client.telegram,
                Client.email <- client.email,
                Client.additionalInfo <- client.additionalInfo,
                Client.createdAt <- Date(),
                Client.updatedAt <- Date()
            )
            let rowId = try db.run(insert)
            
            // Update the local array instead of refetching
            var newClient = client
            // Note: In a real app, you'd want to get the actual ID from the database
            // For now, we'll refetch to ensure consistency
            fetchClients()
            onClientsChanged?()
        } catch {
            print("Error adding client: \(error)")
        }
    }
    
    func updateClient(client: Client) {
        guard let db = db else { return }
        
        do {
            let clientToUpdate = Client.table.filter(Client.id == client.id)
            try db.run(clientToUpdate.update(
                Client.firstName <- client.firstName,
                Client.lastName <- client.lastName,
                Client.phone <- client.phone,
                Client.telegram <- client.telegram,
                Client.email <- client.email,
                Client.additionalInfo <- client.additionalInfo,
                Client.updatedAt <- Date()
            ))
            
            // Update the local array instead of refetching
            if let index = clients.firstIndex(where: { $0.id == client.id }) {
                clients[index] = client
            }
            onClientsChanged?()
        } catch {
            print("Error updating client: \(error)")
        }
    }
    
    func deleteClient(id: Int64) {
        guard let db = db else { return }
        
        do {
            let clientToDelete = Client.table.filter(Client.id == id)
            try db.run(clientToDelete.delete())
            
            // Update the local array instead of refetching
            clients.removeAll { $0.id == id }
            onClientsChanged?()
        } catch {
            print("Error deleting client: \(error)")
        }
    }
}
