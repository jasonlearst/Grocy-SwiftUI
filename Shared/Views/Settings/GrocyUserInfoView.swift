//
//  GrocyUserInfoView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 05.01.21.
//

import SwiftUI

struct GrocyUserInfoView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @State private var userPictureURL: URL? = nil
    
    var grocyUser: GrocyUser? = nil
    
    var body: some View {
        if let grocyUser = grocyUser {
            HStack{
                if let pictureFileName = grocyUser.pictureFileName {
                    PictureView(pictureFileName: pictureFileName, pictureType: .userPictures)
                }
                VStack(alignment: .leading){
                    Text(grocyUser.username)
                        .font(.title)
                    Text(grocyUser.displayName)
                }
            }
        } else {
            Text("str.details.unknown")
        }
    }
}

#Preview {
    GrocyUserInfoView(grocyUser: nil)
}
