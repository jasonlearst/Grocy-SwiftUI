//
//  MDTaskCategoriesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDTaskCategoryRowView: View {
    var taskCategory: MDTaskCategory
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(taskCategory.name)
                .font(.title)
            if let description = taskCategory.mdTaskCategoryDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
    }
}

struct MDTaskCategoriesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @State private var searchString: String = ""
    @State private var showAddTaskCategory: Bool = false
    
    @State private var shownEditPopover: MDTaskCategory? = nil
    
    @State private var taskCategoryToDelete: MDTaskCategory? = nil
    @State private var showDeleteAlert: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.task_categories]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredTaskCategories: MDTaskCategories {
        grocyVM.mdTaskCategories
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func deleteItem(itemToDelete: MDTaskCategory) {
        taskCategoryToDelete = itemToDelete
        showDeleteAlert.toggle()
    }
    private func deleteTaskCategory(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .task_categories, id: toDelID)
            grocyVM.postLog("Deleting task category was successful.", type: .info)
            await updateData()
        } catch {
            grocyVM.postLog("Deleting task category failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
#if os(macOS)
            NavigationView{
                bodyContent
                    .frame(minWidth: Constants.macOSNavWidth)
            }
#else
            bodyContent
#endif
        } else {
            ServerProblemView()
                .navigationTitle(LocalizedStringKey("str.md.taskCategories"))
        }
    }
    
    var bodyContent: some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
#if os(macOS)
                    //                    RefreshButton(updateData: { updateData() })
#endif
                    Button(action: {
                        showAddTaskCategory.toggle()
                    }, label: {Image(systemName: MySymbols.new)})
                }
            }
            .navigationTitle(LocalizedStringKey("str.md.taskCategories"))
#if os(iOS)
            .sheet(isPresented: self.$showAddTaskCategory, content: {
                NavigationView {
                    MDTaskCategoryFormView(isNewTaskCategory: true, showAddTaskCategory: $showAddTaskCategory)
                }
            })
#endif
    }
    
    var content: some View {
        List{
            if grocyVM.mdTaskCategories.isEmpty {
                Text(LocalizedStringKey("str.md.taskCategories.empty"))
            } else if filteredTaskCategories.isEmpty {
                ContentUnavailableView.search
            }
#if os(macOS)
            if showAddTaskCategory {
                NavigationLink(destination: MDTaskCategoryFormView(isNewTaskCategory: true, showAddTaskCategory: $showAddTaskCategory), isActive: $showAddTaskCategory, label: {
                    NewMDRowLabel(title: "str.md.taskCategory.new")
                })
            }
#endif
            ForEach(filteredTaskCategories, id:\.id) { taskCategory in
                NavigationLink(destination: MDTaskCategoryFormView(isNewTaskCategory: false, taskCategory: taskCategory, showAddTaskCategory: $showAddTaskCategory)) {
                    MDTaskCategoryRowView(taskCategory: taskCategory)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: taskCategory) },
                           label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .task {
            Task {
                await updateData()
            }
        }
        .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
        .refreshable {
            await updateData()
        }
        .animation(.default, value: filteredTaskCategories.count)
        .alert(LocalizedStringKey("str.md.taskCategory.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let toDelID = taskCategoryToDelete?.id {
                    Task {
                        await deleteTaskCategory(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(taskCategoryToDelete?.name ?? "Name not found") })
    }
}

struct MDTaskCategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            //            MDTaskCategoryRowView(taskCategory: MDTaskCategory(id: "0", name: "Name", mdTaskCategoryDescription: "Description", rowCreatedTimestamp: "", userfields: nil))
#if os(macOS)
            MDTaskCategoriesView()
#else
            NavigationView() {
                MDTaskCategoriesView()
            }
#endif
        }
    }
}
