import SwiftUI

struct ExtraIncomeContainerView: View {
    @ObservedObject var extraIncomeVM: ExtraIncomeViewModel
    
    @State private var showEdit: Bool = false
    @State private var incomeForEdit: ExtraIncome? = nil
    @State private var showCategoryManage: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var incomeIdToDelete: Int64? = nil
    
    var body: some View {
        ExtraIncomeListView(
            incomes: extraIncomeVM.incomes,
            categories: extraIncomeVM.categories,
            onCreate: { incomeForEdit = nil; showEdit = true },
            onEdit: { income in incomeForEdit = income; showEdit = true },
            onDelete: { id in incomeIdToDelete = id; showDeleteConfirmation = true }
        )
        .sheet(isPresented: $showEdit) {
            ExtraIncomeEditView(
                income: incomeForEdit,
                categories: extraIncomeVM.categories,
                onSave: { categoryId, amount, receivedAt in
                    if let inc = incomeForEdit {
                        extraIncomeVM.updateIncome(id: inc.id, categoryId: categoryId, amount: amount, receivedAt: receivedAt)
                    } else {
                        extraIncomeVM.createIncome(categoryId: categoryId, amount: amount, receivedAt: receivedAt)
                    }
                    showEdit = false
                },
                onCancel: { showEdit = false },
                onCreateCategory: { showCategoryManage = true }
            )
        }
        .sheet(isPresented: $showCategoryManage) {
            IncomeCategoryManageView(
                categories: extraIncomeVM.categories,
                onCreate: { name in extraIncomeVM.createCategory(name: name) },
                onDelete: { id in extraIncomeVM.deleteCategory(id: id) },
                onClose: { showCategoryManage = false }
            )
        }
        .alert("Подтверждение удаления", isPresented: $showDeleteConfirmation) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                if let id = incomeIdToDelete { extraIncomeVM.deleteIncome(id: id) }
                incomeIdToDelete = nil
            }
        } message: {
            Text("Вы уверены, что хотите удалить доп доход?")
        }
        .onAppear { extraIncomeVM.fetchAll() }
    }
}


