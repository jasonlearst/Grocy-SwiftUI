//
//  TransferProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftUI
import SwiftData

struct TransferProductView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDProduct.id, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query(sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessingAction: Bool = false
    
    var stockElement: Binding<StockElement?>? = nil
    var productToTransferID: Int? {
        return stockElement?.wrappedValue?.productID
    }
    var isPopup: Bool = false
    
    @State private var productID: Int?
    @State private var locationIDFrom: Int?
    @State private var amount: Double = 1.0
    @State private var quantityUnitID: Int?
    @State private var locationIDTo: Int?
    @State private var useSpecificStockEntry: Bool = false
    @State private var stockEntryID: String?
    
    @State private var searchProductTerm: String = ""
    
    private let dataToUpdate: [ObjectEntities] = [.products, .locations, .quantity_units, .quantity_unit_conversions]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var product: MDProduct? {
        mdProducts.first(where: {$0.id == productID})
    }
    private var currentQuantityUnit: MDQuantityUnit? {
        return mdQuantityUnits.first(where: {$0.id == quantityUnitID })
    }
    private var stockQuantityUnit: MDQuantityUnit? {
        return mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }
    private var productName: String {
        product?.name ?? ""
    }
    
    private var locationTo: MDLocation? {
        mdLocations.first(where: {$0.id == locationIDTo})
    }
    
    private var quantityUnitConversions: [MDQuantityUnitConversion] {
        if let quIDStock = product?.quIDStock {
            return mdQuantityUnitConversions.filter({ $0.toQuID == quIDStock })
        } else { return [] }
    }
    private var factoredAmount: Double {
        return amount * (quantityUnitConversions.first(where: { $0.fromQuID == quantityUnitID})?.factor ?? 1)
    }
    
    private let priceFormatter = NumberFormatter()
    
    var isFormValid: Bool {
        (productID != nil) && (amount > 0) && (quantityUnitID != nil) && (locationIDFrom != nil) && (locationIDTo != nil) && !(useSpecificStockEntry && stockEntryID == nil) && !(useSpecificStockEntry && amount != 1.0) && !(locationIDFrom == locationIDTo)
    }
    
    private func resetForm() {
        productID = firstAppear ? productToTransferID : nil
        locationIDFrom = nil
        amount = 1.0
        quantityUnitID = firstAppear ? product?.quIDStock : nil
        locationIDTo = nil
        useSpecificStockEntry = false
        stockEntryID = nil
        searchProductTerm = ""
    }
    
    private func transferProduct() async {
        if let productID = productID, let locationIDFrom = locationIDFrom, let locationIDTo = locationIDTo {
            let transferInfo = ProductTransfer(amount: factoredAmount, locationIDFrom: locationIDFrom, locationIDTo: locationIDTo, stockEntryID: stockEntryID)
            isProcessingAction = true
            do {
                try await grocyVM.postStockObject(id: productID, stockModePost: .transfer, content: transferInfo)
                await grocyVM.postLog("Transfer successful.", type: .info)
                await grocyVM.requestData(additionalObjects: [.stock])
                resetForm()
            } catch {
                await grocyVM.postLog("Transfer failed: \(error)", type: .error)
            }
            isProcessingAction = false
        }
    }
    
    var body: some View {
        Form {
            if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count > 0 {
                Section{
                    ServerProblemView(isCompact: true)
                }
            }
            
            ProductField(productID: $productID, description: "Product")
                .onChange(of: productID) {
                    Task {
                        try await grocyVM.getStockProductEntries(productID: productID ?? 0)
                        if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                            locationIDFrom = selectedProduct.locationID
                            quantityUnitID = selectedProduct.quIDStock
                        }
                    }
                }
            
            if productID != nil {
            
            VStack(alignment: .leading) {
                Picker(selection: $locationIDFrom, label: Label("From location", systemImage: "square.and.arrow.up").foregroundStyle(.primary), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdLocations.filter({$0.active}), id:\.id) { locationFrom in
                        Text(locationFrom.name).tag(locationFrom.id as Int?)
                    }
                })
                
                if locationIDFrom == nil {
                    Text("A location is required")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            AmountSelectionView(productID: $productID, amount: $amount, quantityUnitID: $quantityUnitID)
            
            VStack(alignment: .leading) {
                Picker(
                    selection: $locationIDTo,
                    label: Label("To location", systemImage: "square.and.arrow.down").foregroundStyle(.primary),
                    content: {
                        Text("").tag(nil as Int?)
                        ForEach(grocyVM.mdLocations.filter({$0.active}), id:\.id) { locationTo in
                            Text(locationTo.name).tag(locationTo.id as Int?)
                        }
                    })
                if locationIDTo == nil {
                    Text("A location is required")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                if (locationIDFrom != nil) && (locationIDFrom == locationIDTo) {
                    Text("This cannot be the same as the \"From\" location")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                if product?.shouldNotBeFrozen == true,
                   locationTo?.isFreezer == true
                {
                    Text("This product shouldn't be frozen")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
                if productID != nil {
                    MyToggle(isOn: $useSpecificStockEntry, description: "Use a specific stock item", descriptionInfo: "The first item in this list would be picked by the default rule which is \"Opened first, then first due first, then first in first out\"", icon: "tag")
                    
                    if (useSpecificStockEntry) {
                        Picker(selection: $stockEntryID, label: Label("Stock entry", systemImage: "tag"), content: {
                            Text("").tag(nil as String?)
                            ForEach(grocyVM.stockProductEntries[productID ?? 0] ?? [], id: \.stockID) { stockProduct in
                                Group {
                                    Text("Amount: \(stockProduct.amount, specifier: "%.2f"); ")
                                    +
                                    Text("Due on \(formatDateAsString(stockProduct.bestBeforeDate, localizationKey: localizationKey) ?? "?"); ")
                                    +
                                    Text(stockProduct.stockEntryOpen == true ? "Opened" : "Not opened")
                                    +
                                    Text("; ")
                                    +
                                    Text(stockProduct.note != nil ? "Note: \(stockProduct.note ?? "")" : "")
                                }
                                .tag(stockProduct.stockID as String?)
                            }
                        })
                    }
                }
            }
        }
        .formStyle(.grouped)
        .toolbar(content: {
            ToolbarItemGroup(placement: .automatic, content: {
                if isProcessingAction {
                    ProgressView().progressViewStyle(.circular)
                } else {
                    Button(action: resetForm, label: {
                        Label("Clear", systemImage: MySymbols.cancel)
                            .help("Clear")
                    })
                    .keyboardShortcut("r", modifiers: [.command])
                }
                Button(action: {
                    Task {
                        await transferProduct()
                    }
                }, label: {
                    Label("Transfer product", systemImage: MySymbols.transfer)
                        .labelStyle(.titleAndIcon)
                })
                .disabled(!isFormValid || isProcessingAction)
                .keyboardShortcut("s", modifiers: [.command])
            })
        })
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
        .navigationTitle("Transfer")
    }
}

struct TransferProductView_Previews: PreviewProvider {
    static var previews: some View {
        TransferProductView()
    }
}
