//
//  MainView.swift
//  photo-storage
//
//  Created by Nabhan Suwanachote on 14/4/2567 BE.
//

import SwiftUI
import PhotosUI

@MainActor
final class MainViewModel: ObservableObject {
    @Published var imageListMem: [UIImage] = []
    
    func getImageList() async throws {
        let result = try await ImageManager.shared.getImageList()
        print(result.items)
        for image in result.items {
            print("\(image.bucket), \(image.fullPath)")
            let storageLocation = String(describing: image)
            print("Storage Path: \(storageLocation)")
            let test = try await ImageManager.shared.getDownloadUrlFromPath(path: storageLocation)
            print("Download URL: \(test)")
        }
    }
    
    func processSelectedImages(results: [PHPickerResult]) -> [ImageResult] {
        var imageResultList: [ImageResult] = []
        for result in results {
            guard let fileName = result.itemProvider.suggestedName else {
                continue
            }
            let identifier = result.assetIdentifier!
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                // Check for errors
                if let error = error {
                    print("Sick error dawg \(error.localizedDescription)")
                } else {
                    // Convert the image into Data so we can upload to firebase
                    if let image = object as? UIImage {
                        let imageData = image.jpegData(compressionQuality: 1.0)
                        
                        do {
                            let uid = try AuthenticationManager.shared.getAuthenticatedUser().uid
                            guard let imageData = imageData else {
                                return
                            }
                            let imageResult = ImageManager.shared.uploadFile(imageData: imageData, fileName: fileName, uid: uid, identifier: identifier)
                            print("Uploaded to firebase")
                            
                            guard let imageResult = imageResult else {
                                print("Error: unabel to get image result object")
                                return
                            }
                            imageResultList.append(imageResult)
                        } catch {
                            print("Error: Unable to upload image")
                        }
                    } else {
                        print("There was an error.")
                    }
                }
            }
        }
        return imageResultList
    }
    
//    func processSelectedImages(results: [PHPickerResult]) -> [ImageResult] {
//        var imageResultList: [ImageResult] = []
//        let dispatchGroup = DispatchGroup()
//        let resultQueue = DispatchQueue(label: "imageResultListQueue", attributes: .concurrent)
//        
//        for result in results {
//            guard let fileName = result.itemProvider.suggestedName else {
//                continue
//            }
//            dispatchGroup.enter()
//            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
//                // Check for errors
//                if let error = error {
//                    print("Sick error dawg \(error.localizedDescription)")
//                } else {
//                    // Convert the image into Data so we can upload to firebase
//                    if let image = object as? UIImage, let imageData = image.jpegData(compressionQuality: 1.0) {
//                        do {
//                            let uid = try AuthenticationManager.shared.getAuthenticatedUser().uid
//                            let imageResult = ImageManager.shared.uploadFile(imageData: imageData, fileName: fileName, uid: uid)
//                            print("Uploaded to firebase")
//                            
//                            guard let imageResult = imageResult else {
//                                print("Error: unable to get image result object")
//                                dispatchGroup.leave()
//                                return
//                            }
//                            resultQueue.async(flags: .barrier) {
//                                imageResultList.append(imageResult)
//                            }
//                        } catch {
//                            print("Error: Unable to upload image")
//                        }
//                    } else {
//                        print("There was an error.")
//                    }
//                }
//                dispatchGroup.leave()
//            }
//        }
//        
//        dispatchGroup.wait()
//        return imageResultList
//    }
//
}


struct MainView: View {
    @StateObject var imageView: ImageResultViewModel
    @StateObject private var viewModel = MainViewModel()
    @State var showPicker = false
    
    func uploadPhotoAndUpadate(results: [PHPickerResult]) async throws {
        let result = viewModel.processSelectedImages(results: results)
        let uid = try AuthenticationManager.shared.getAuthenticatedUser().uid
        imageView.concat(imageResult: result)
        try await Task.sleep(nanoseconds: UInt64(4 * Double(NSEC_PER_SEC)))
        let imageResultList = try await ImageManager.shared.getImageByUid(uid: uid)
        imageView.setImageResult(imageResultList: imageResultList)
    }
    
    var pickerConfig: PHPickerConfiguration {
        var config = PHPickerConfiguration(
            photoLibrary: PHPhotoLibrary.shared())
        config.filter = .images
        config.selectionLimit = 20
        config.preferredAssetRepresentationMode = .current
        config.preselectedAssetIdentifiers = preselectedAssetIdentifiers
        return config
    }
    
    var body: some View {
        GeometryReader { reader in
            ZStack {
                Color.white
                VStack(alignment: .leading, spacing: 10, content: {
                    let column = Array(repeating: GridItem(.flexible(), spacing: 15), count: 2)
                    LazyVGrid(columns: column, alignment: .center, spacing: 10, content: {
                        ForEach(imageView.ImageResultList,id: \.identifier){result in
                            GridImageView(imageView: imageView, imageResult: result, screenWidth: (reader.size.width - 40)/2, isMainPage: true)
                        }
                    })
                    Spacer()
                })
                VStack {
                    Spacer()
                    Button {
                        showPicker.toggle()
                    }label: {
                        Image(systemName: "plus")
                            .font(.title.weight(.semibold))
                            .padding()
                            .background(Color.pink)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .sheet(isPresented: $showPicker, content: {
                        PHPickerSwiftUI(config: pickerConfig) { selectedImages in
                            Task {
                                try await uploadPhotoAndUpadate(results: selectedImages)
                            }
                        }
                        .ignoresSafeArea()
                    })
                }
                
            }
            .padding()
            .onAppear {
                Task {
                    do {
                        let uid = try AuthenticationManager.shared.getAuthenticatedUser().uid
                        let imageResultList = try await ImageManager.shared.getImageByUid(uid: uid)
                        imageView.setImageResult(imageResultList: imageResultList)
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }
        }
    }
        
    
}

#Preview {
    MainView(imageView: ImageResultViewModel())
}
