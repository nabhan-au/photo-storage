//
//  FavoriteView.swift
//  photo-storage
//
//  Created by Nabhan Suwanachote on 15/4/2567 BE.
//

import SwiftUI

struct FavoriteView: View {
    @StateObject var imageView: ImageResultViewModel
    @Binding var showToast: ToastObject?
    var body: some View {
        GeometryReader { reader in
            ZStack {
                Color.white
                VStack(alignment: .leading, spacing: 10, content: {
                    let column = Array(repeating: GridItem(.flexible(), spacing: 15), count: 2)
                    LazyVGrid(columns: column, alignment: .center, spacing: 10, content: {
                        ForEach(imageView.getFavorites(),id: \.identifier){result in
                            GridImageView(imageView: imageView, showToast: $showToast, imageResult: result, screenWidth: (reader.size.width - 40)/2, isMainPage: false)
                        }
                    })
                    Spacer()
                })
            }
            .padding()
        }
    }
}

//#Preview {
//    FavoriteView(ImageResultViewModel)
//}
