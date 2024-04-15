//
//  GridImageView.swift
//  photo-storage
//
//  Created by Nabhan Suwanachote on 15/4/2567 BE.
//

import SwiftUI

struct GridImageView: View {
    @StateObject var imageView: ImageResultViewModel
    @Binding var showToast: ToastObject?
    var imageResult: ImageResult
    var screenWidth: CGFloat
    var isMainPage: Bool
    
    func getImageUrl() -> URL {
        let url = URL(string: imageResult.downloadURL)
        guard let url = url else {
            return URL(fileURLWithPath: "")
        }
        return url
    }
    
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AsyncImage(
                url: getImageUrl(),
                content: {image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: screenWidth, height: screenWidth)
                        .clipped()
                },
                placeholder: {
                    ProgressView()
                }
            )
            if imageResult.isFavorite && isMainPage {
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.red)
                    .padding()   // Adds some space around the heart image inside its frame
                    .background(Color.white.opacity(0.7)) // Slightly transparent white background
                    .clipShape(Circle())  // Makes the background circular
                    .zIndex(1)  // Ensures the heart symbol is on top
            }
        }
        .padding()
        .onTapGesture(count: 2, perform: {
            do {
                let uid = try AuthenticationManager.shared.getAuthenticatedUser().uid
                ImageManager.shared.updateFavorite(uid: uid, identifier: imageResult.identifier, isFavorite: !imageResult.isFavorite)
                imageView.updateWithCondition(identifier: imageResult.identifier, isFavorite: !imageResult.isFavorite)
            } catch {
                print("Error: \(error)")
            }
            
        })
        .onLongPressGesture(minimumDuration: 0.1) {
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: getImageUrl())
                let uiImage = UIImage(data: data!)
                guard let uiImage = uiImage else { return }
                DispatchQueue.main.async {
                    UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                    showToast = ToastObject(message: "Download picture success", symbol: "square.and.arrow.down.on.square", color: Color.green.opacity(0.9))
                }
                
            }
            
        }
    }
}

//#Preview {
//    GridImageView()
//}
