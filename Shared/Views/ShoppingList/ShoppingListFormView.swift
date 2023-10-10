//
//  ShoppingListAddView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

struct ShoppingListFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    
    var isNewShoppingListDescription: Bool
    var shoppingListDescription: ShoppingListDescription?
    
    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundShoppingListDescription = grocyVM.shoppingListDescriptions.first(where: { $0.name == name })
        return shoppingListDescription == nil ? !(name.isEmpty || foundShoppingListDescription != nil) : !(name.isEmpty || (foundShoppingListDescription != nil && foundShoppingListDescription!.id != shoppingListDescription!.id))
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
#endif
    }
    
    private func updateData() async {
        await grocyVM.requestData(objects: [.shopping_lists])
    }
    
    func saveShoppingList() async {
        let id = shoppingListDescription == nil ? grocyVM.findNextID(.shopping_lists) : shoppingListDescription!.id
        let timeStamp = shoppingListDescription == nil ? Date().iso8601withFractionalSeconds : shoppingListDescription!.rowCreatedTimestamp
        let shoppingListPOST = ShoppingListDescription(
            id: id,
            name: name,
            rowCreatedTimestamp: timeStamp
        )
        isProcessing = true
        if shoppingListDescription == nil {
            do {
                _ = try await grocyVM.postMDObject(
                    object: .shopping_lists,
                    content: shoppingListPOST
                )
                grocyVM.postLog("Shopping list save successful.", type: .info)
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Shopping list save failed. \(error)", type: .error)
            }
        } else {
            do {
                try await grocyVM.putMDObjectWithID(
                    object: .shopping_lists,
                    id: id,
                    content: shoppingListPOST
                )
                grocyVM.postLog("Shopping list edit successful.", type: .info)
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Shopping list edit failed. \(error)", type: .error)
            }
        }
        isProcessing = false
    }
    
    private func resetForm() {
        name = shoppingListDescription?.name ?? ""
        isNameCorrect = checkNameCorrect()
    }
    
    var body: some View {
        Form {
#if os(macOS)
            Text(isNewShoppingListDescription ? "Create shopping list" : "Edit shopping list")
                .font(.headline)
#endif
            MyTextField(
                textToEdit: $name,
                description: "Name",
                isCorrect: $isNameCorrect,
                leadingIcon: MySymbols.name,
                emptyMessage: "A name is required",
                errorMessage: "Name already exists"
            )
            .onChange(of: name) {
                isNameCorrect = checkNameCorrect()
            }
#if os(macOS)
            HStack {
                Button("Cancel") {
                    finishForm()
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    Task {
                        await saveShoppingList()
                    }
                }
                .disabled(isProcessing)
                .keyboardShortcut(.defaultAction)
            }
#endif
        }
        .onAppear(perform: resetForm)
        .navigationTitle(shoppingListDescription == nil ? "Create shopping list" : "Edit shopping list")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    finishForm()
                }
                .keyboardShortcut(.cancelAction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await saveShoppingList()
                    }
                }
                .disabled(isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}

#Preview {
    ShoppingListFormView(isNewShoppingListDescription: true)
}
