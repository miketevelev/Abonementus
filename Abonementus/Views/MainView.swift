import SwiftUI
import SQLite

struct MainView: SwiftUI.View {
    // ViewModels
    @StateObject private var clientVM = ClientViewModel()
    @StateObject private var lessonVM = LessonViewModel()
    @StateObject private var subscriptionVM = SubscriptionViewModel()
    @StateObject private var extraIncomeVM = ExtraIncomeViewModel()
    
    // State variables
    @State private var selectedClient: Client?
    @State private var showSubscriptionCreate = false
    @State private var showLessonCreate = false
    @State private var showAllSubscriptions = false
    @State private var showAllLessons = false
    @State private var showHistory = false
    @State private var showExtraIncome = false
    
    var body: some SwiftUI.View {
        HStack(spacing: 0) {
            // Left side - Clients list (20% width)
            ClientListView(
                clients: clientVM.clients,
                selectedClient: $selectedClient
            )
            .frame(width: 250)
            .background(Color(.windowBackgroundColor))
            
            // Right side - Subscriptions and lessons
            if clientVM.isLoading {
                // Show loading state only when actually loading
                VStack {
                    ProgressView("Загрузка данных...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                // Show content regardless of whether clients exist
                VStack {

                    
                    if clientVM.clients.isEmpty {
                        // Show welcome message if no clients exist
                        VStack(spacing: 20) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                                .padding(16)
                                .background(Color.blue.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            Text("Добро пожаловать в Abonementus!")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Для начала работы создайте первого клиента")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                selectedClient = Client(
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
                            }) {
                                Label("Создать клиента", systemImage: "plus.circle")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Show normal subscription view
                        SubscriptionMainView(
                            subscriptions: subscriptionVM.activeSubscriptions,
                            clients: clientVM.clients,
                            getLessons: { subscriptionId in
                                subscriptionVM.getLessons(for: subscriptionId)
                            },
                            completedAmount: lessonVM.calculateCompletedAmount(),
                            pendingAmount: lessonVM.calculatePendingAmount(),
                            extraAmount: extraIncomeVM.calculateExtraAmountForCurrentMonth(),
                            showSubscriptionCreate: $showSubscriptionCreate,
                            showLessonCreate: $showLessonCreate,
                            showAllSubscriptions: $showAllSubscriptions,
                            showAllLessons: $showAllLessons,
                            showHistory: $showHistory,
                            showExtraIncome: $showExtraIncome,
                            onLessonTap: { lesson in
                                lessonVM.completeLesson(lesson: lesson)
                            },
                            onLessonUncomplete: { lesson in
                                lessonVM.uncompleteLesson(lesson: lesson)
                            },
                            onRefresh: {
                                refreshAllData()
                            }
                        )
                    }
                }
            }
        }
        .sheet(item: $selectedClient, onDismiss: { selectedClient = nil }) { client in
            ClientEditView(
                client: client,
                onSave: { updatedClient in
                    if updatedClient.id == 0 {
                        clientVM.addClient(client: updatedClient)
                    } else {
                        clientVM.updateClient(client: updatedClient)
                    }
                },
                onDelete: {
                    clientVM.deleteClient(id: client.id)
                }
            )
        }
        .sheet(isPresented: $showSubscriptionCreate) {
            SubscriptionCreateView(
                clients: clientVM.clients,
                onCreate: { clientId, lessonCount, totalPrice, startDate in
                    subscriptionVM.createSubscription(
                        clientId: clientId,
                        lessonCount: lessonCount,
                        totalPrice: totalPrice,
                        startDate: startDate
                    )
                }
            )
        }
        .sheet(isPresented: $showLessonCreate) {
            LessonCreateView(
                clients: clientVM.clients,
                onCreate: { clientId, price, lessonDate in
                    lessonVM.createLesson(
                        clientId: clientId,
                        subscriptionId: nil,
                        price: price,
                        lessonDate: lessonDate
                    )
                }
            )
        }
        .sheet(isPresented: $showAllSubscriptions) {
            SubscriptionListView(
                subscriptions: subscriptionVM.subscriptions,
                clients: clientVM.clients,
                getLessons: { subscriptionId in
                    subscriptionVM.getLessons(for: subscriptionId)
                },
                onDelete: { id in
                    subscriptionVM.deleteSubscription(id: id)
                }
            )
        }
        .sheet(isPresented: $showAllLessons) {
            LessonListView(
                lessons: lessonVM.lessons,
                clients: clientVM.clients,
                onDelete: { id in
                    lessonVM.deleteLesson(id: id)
                },
                onUpdateLessonTime: { lessonId, newDate in
                    lessonVM.updateLessonCompletionTime(lessonId: lessonId, newConductedAt: newDate)
                }
            )
        }
        .sheet(isPresented: $showExtraIncome) {
            ExtraIncomeContainerView(
                extraIncomeVM: extraIncomeVM
            )
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(
                lessons: lessonVM.lessons,
                clients: clientVM.clients,
                extraIncomes: extraIncomeVM.incomes
            )
        }
        .onAppear {
            print("MainView: onAppear triggered")
            
            // Set up dependencies after ViewModels are initialized
            subscriptionVM.setLessonViewModel(lessonVM)
            
            // Set up callback for subscription creation to refresh data
            subscriptionVM.setOnSubscriptionCreated {
                // Refresh all data when subscription is created
                DispatchQueue.main.async {
                    print("MainView: Subscription created callback triggered")
                    self.refreshAllData()
                }
            }
            
            // Set up callback for subscription deletion to refresh data
            subscriptionVM.setOnSubscriptionDeleted { subscriptionId in
                // Refresh data when subscription is completed
                DispatchQueue.main.async {
                    print("MainView: Subscription deleted callback triggered for ID: \(subscriptionId)")
                    self.refreshAllData()
                }
            }
            
            // Set up callback for lesson creation to refresh data
            lessonVM.setOnLessonCreated {
                // Refresh data when lesson is created
                DispatchQueue.main.async {
                    print("MainView: Lesson created callback triggered")
                    self.refreshAllData()
                }
            }
            
            // Set up callback for subscription completion to refresh data
            lessonVM.setOnSubscriptionCompleted { subscriptionId in
                // Refresh data when subscription is completed
                DispatchQueue.main.async {
                    print("MainView: Subscription completed callback triggered for ID: \(subscriptionId)")
                    self.refreshAllData()
                }
            }
            
            // Set up callback for client changes to refresh data
            clientVM.setOnClientsChanged {
                // Refresh data when clients are modified
                DispatchQueue.main.async {
                    print("MainView: Clients changed callback triggered")
                    self.refreshAllData()
                }
            }
            
            // Initial data loading - defer to avoid rapid view updates
            DispatchQueue.main.async {
                print("MainView: Starting initial data load...")
                self.refreshAllData()
                self.extraIncomeVM.fetchAll()
            }
        }
    }
    
    private func refreshAllData() {
        print("MainView: refreshAllData called")
        print("MainView: Current clientVM.isLoading: \(clientVM.isLoading)")
        print("MainView: Current clientVM.clients.count: \(clientVM.clients.count)")
        
        clientVM.fetchClients()
        lessonVM.fetchLessons()
        subscriptionVM.fetchSubscriptions()
        extraIncomeVM.fetchAll()
        
        print("MainView: refreshAllData completed")
    }
}

// Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some SwiftUI.View {
        MainView()
            .frame(minWidth: 1500, minHeight: 600)
    }
}
