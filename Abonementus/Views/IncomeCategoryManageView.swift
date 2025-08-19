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
			// Top bar 50px
			HStack {
				Text("Категории дохода")
					.font(.headline)
					.fontWeight(.bold)
				Spacer()
				Button(action: onClose) {
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
			
			// Content area
			VStack(spacing: 0) {
				// Create form
				Form {
					Section(header: Text("Новая категория")) {
						TextField("Название", text: $newName)
					}
				}
				.padding(.horizontal, 20)
				.padding(.bottom, 10)
				
				Spacer()
				
				// Category list
				List {
					Section(header: HStack {
						Text("Существующие категории")
						Spacer()
					}) {
						ForEach(categories, id: \.id) { cat in
							categoryRow(for: cat)
								.background(Color.gray.opacity(0.1))
								.cornerRadius(6)
						}
					}
				}
				.padding(.horizontal, 20)
				#if os(iOS)
				.listStyle(.insetGrouped)
				#else
				.listStyle(.bordered(alternatesRowBackgrounds: true))
				#endif
			}
			
			// Bottom add button
			HStack {
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
			.padding(.top, 10)
			.padding(.bottom, 20)
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
	
	private func categoryRow(for category: IncomeCategory) -> some View {
		return HStack {
			// Category name
			VStack(alignment: .leading, spacing: 4) {
				Text(category.name)
					.font(.headline)
			}
			.frame(width: 200, alignment: .leading)
			
			Spacer()
			
			// Delete button
			Button(action: {
				categoryIdToDelete = category.id
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
			.padding(.trailing, 1)
		}
		.padding(.horizontal, 15)
		.padding(.vertical, 8)
	}
}


