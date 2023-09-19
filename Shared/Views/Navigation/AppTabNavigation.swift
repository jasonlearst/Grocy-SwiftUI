//
//  AppTabNavigation.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

extension AppTabNavigation {
    private enum Tab: String {
        case quickScanMode = "barcode.viewfinder"
        case stockOverview = "books.vertical"
        case shoppingList = "cart"
        case more = "ellipsis.circle"
        case masterData = "text.book.closed"
        case activities = "play.rectangle"
        case settings = "gear"
        case openFoodFacts = "barcode"
        case recipes = "list.bullet.below.rectangle"
    }
}

struct AppTabNavigation: View {
    @AppStorage("tabSelection") private var tabSelection: Tab = .stockOverview
    @AppStorage("devMode") private var devMode: Bool = false
    
    var body: some View {
        TabView(selection: $tabSelection) {
            QuickScanModeView()
                .tabItem {
                    Label(LocalizedStringKey("str.nav.quickScan"), systemImage: Tab.quickScanMode.rawValue)
                        .accessibility(label: Text(LocalizedStringKey("str.nav.quickScan")))
                }
                .tag(Tab.quickScanMode)
            
            NavigationStack {
                StockView()
            }
            .tabItem {
                Label(LocalizedStringKey("str.nav.stockOverview"), systemImage: Tab.stockOverview.rawValue)
                    .accessibility(label: Text("str.nav.stockOverview"))
            }
            .tag(Tab.stockOverview)
            
            NavigationStack {
                ShoppingListView()
            }
            .tabItem {
                Label("str.nav.shoppingList", systemImage: Tab.shoppingList.rawValue)
                    .accessibility(label: Text("str.nav.shoppingList"))
            }
            .tag(Tab.shoppingList)
            
            if devMode {
                NavigationView {
                    RecipesView()
                }
                .tabItem({
                    Label("str.nav.recipes", systemImage: Tab.recipes.rawValue)
                })
                .tag(Tab.recipes)
            }
            
            NavigationStack {
                MasterDataView()
            }
            .tabItem {
                Label("str.nav.md", systemImage: Tab.masterData.rawValue)
                    .accessibility(label: Text("str.nav.md"))
            }
            .tag(Tab.masterData)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("str.nav.settings", systemImage: Tab.settings.rawValue)
                    .accessibility(label: Text("str.nav.settings"))
            }
            .tag(Tab.settings)
        }
    }
}

struct AppTabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        AppTabNavigation()
    }
}
