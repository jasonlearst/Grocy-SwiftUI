//
//  StockTableMenuEntriesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 07.12.20.
//

import SwiftUI

struct StockTableMenuEntriesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    var stockElement: StockElement
    @Binding var selectedStockElement: StockElement?
    @Binding var activeSheet: StockInteractionSheet?
    
    var quantityUnit: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: {$0.id == stockElement.product.quIDStock})
    }
    var quString: String {
        return stockElement.product.quickConsumeAmount == 1.0 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? ""
    }
    
    func consumeAsSpoiled() async {
        do {
            try await grocyVM.postStockObject(id: stockElement.product.id, stockModePost: .consume, content: ProductConsume(amount: stockElement.amount, transactionType: .consume, spoiled: true, stockEntryID: nil, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil))
            await grocyVM.requestData(additionalObjects: [.stock])
        } catch {
            grocyVM.postLog("Consume all as spoiled failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        Button(action: {
            selectedStockElement = stockElement
        }, label: {
            Label("Add to shopping list", systemImage: MySymbols.addToShoppingList)
                .labelStyle(.titleAndIcon)
        })
        Divider()
        Group{
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .productPurchase
            }, label: {
                Label("Purchase", systemImage: MySymbols.purchase)
                    .labelStyle(.titleAndIcon)
            })
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .productConsume
            }, label: {
                Label("Consume", systemImage: MySymbols.consume)
                    .labelStyle(.titleAndIcon)
            })
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .productTransfer
            }, label: {
                Label("Transfer", systemImage: MySymbols.transfer)
                    .labelStyle(.titleAndIcon)
            })
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .productInventory
            }, label: {
                Label("Inventory", systemImage: MySymbols.inventory)
                    .labelStyle(.titleAndIcon)
            })
        }
        Divider()
        Group{
            Button(role: .destructive, action: {
                selectedStockElement = stockElement
                Task {
                    await consumeAsSpoiled()
                }
            }, label: {
                Label("Consume \(stockElement.amount.formattedAmount) \(quString)", systemImage: MySymbols.clear)
            })
            
            //                Button(action: {
            //                    print("recip")
            //                }, label: {
            //                    Text("Search for recipes which contain this product")
            //                })
        }
        Divider()
        Group{
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .productOverview
            }, label: {
                Label("Product overview", systemImage: MySymbols.info)
            })
            //                Button(action: {
            //                    print("Stock entries are not accessed here")
            //                }, label: {
            //                    Text("Stock entries")
            //                })
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .productJournal
            }, label: {
                Label("Stock journal", systemImage: MySymbols.stockJournal)
            })
            //                Button(action: {
            //                    print("Stock Journal summary is not available yet")
            //                }, label: {
            //                    Text("Stock journal summary")
            //                })
            Button(action: {
                selectedStockElement = stockElement
                activeSheet = .editProduct
            }, label: {
                Label("Edit product", systemImage: MySymbols.edit)
            })
        }
    }
}

//struct StockTableMenuView_Previews: PreviewProvider {
//    static var previews: some View {
//        StockTableMenuView(stockElement: StockElement(amount: "3", amountAggregated: "3", value: "25", bestBeforeDate: "2020-12-12", amountOpened: "1", amountOpenedAggregated: "1", isAggregatedAmount: "0", dueType: "1", productID: "3", product: MDProduct(id: "3", name: "Productname", mdProductDescription: "Description", productGroupID: "1", active: "1", locationID: "1", storeID: "1", quIDPurchase: "1", quIDStock: "1", minStockAmount: "1", defaultBestBeforeDays: "1", defaultBestBeforeDaysAfterOpen: "1", defaultBestBeforeDaysAfterFreezing: "1", defaultBestBeforeDaysAfterThawing: "1", pictureFileName: nil, enableTareWeightHandling: "0", tareWeight: "1", notCheckStockFulfillmentForRecipes: "1", parentProductID: "1", calories: "1233", cumulateMinStockAmountOfSubProducts: "0", dueType: "1", quickConsumeAmount: "1", rowCreatedTimestamp: "ts", hideOnStockOverview: "0", userfields: nil)), selectedStockElement)
//    }
//}
