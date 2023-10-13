//
//  MasterDataView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

private enum MasterDataItem: Hashable {
    case products
    case locations
    case stores
    case quantityUnits
    case productGroups
    case chores
    case batteries
    case taskCategories
    case userFields
    case userEntities
}

struct MasterDataView: View {
    @AppStorage("devMode") private var devMode: Bool = false
    
    var body: some View {
        List {
            NavigationLink(value: MasterDataItem.products) {
                Label("Products", systemImage: MySymbols.product)
            }
            
            NavigationLink(value: MasterDataItem.locations) {
                Label("Locations", systemImage: MySymbols.location)
            }
            
            NavigationLink(value: MasterDataItem.stores) {
                Label("Stores", systemImage: MySymbols.store)
            }
            
            NavigationLink(value: MasterDataItem.quantityUnits) {
                Label("Quantity units", systemImage: MySymbols.quantityUnit)
            }
            
            NavigationLink(value: MasterDataItem.productGroups) {
                Label("Product groups", systemImage: MySymbols.productGroup)
            }
            
            if devMode {
                NavigationLink(value: MasterDataItem.chores) {
                    Label("Chores", systemImage: "house")
                }
                
                NavigationLink(value: MasterDataItem.batteries) {
                    Label("Batteries", systemImage: "battery.25")
                }
                
                NavigationLink(value: MasterDataItem.taskCategories) {
                    Label("Task categories", systemImage: "point.fill.topleft.down.curvedto.point.fill.bottomright.up")
                }
                
                NavigationLink(value: MasterDataItem.userFields) {
                    Label("Userfields", systemImage: "bookmark.fill")
                }
                
                NavigationLink(value: MasterDataItem.userEntities) {
                    Label("User entities", systemImage: "bookmark")
                }
            }
        }
        .navigationTitle("Master data")
        .navigationDestination(for: MasterDataItem.self, destination: { masterDataItem in
            switch masterDataItem {
            case .products:
                MDProductsView()
            case .locations:
                MDLocationsView()
            case .stores:
                MDStoresView()
            case .quantityUnits:
                MDQuantityUnitsView()
            case .productGroups:
                MDProductGroupsView()
            case .chores:
                MDChoresView()
            case .batteries:
                MDBatteriesView()
            case .taskCategories:
                MDTaskCategoriesView()
            case .userFields:
                MDUserFieldsView()
            case .userEntities:
                MDUserEntitiesView()
            }
        })
    }
}

struct MasterDataView_Previews: PreviewProvider {
    static var previews: some View {
        MasterDataView()
    }
}
