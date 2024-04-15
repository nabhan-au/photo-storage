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
            var city = ""
            var country = ""
            let identifier = result.assetIdentifier!
            if let assetId = result.assetIdentifier {
                let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
                let location = assetResults.firstObject?.location
                print("lat: \(location?.coordinate.latitude), lon: \(location?.coordinate.longitude)")
                location?.fetchCityAndCountry { cityValue, countryValue, error in
                    city = cityValue ?? ""
                    country = countryValue ?? ""
                }
            }
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
                            let imageResult = ImageManager.shared.uploadFile(imageData: imageData, fileName: fileName, uid: uid, identifier: identifier, city: city, country: country)
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
    @Binding var showToast: ToastObject?
    @State var showPicker = false
    @State var searchText = ""
    
    func uploadPhotoAndUpadate(results: [PHPickerResult]) async throws {
        let result = viewModel.processSelectedImages(results: results)
        let uid = try AuthenticationManager.shared.getAuthenticatedUser().uid
        imageView.concat(imageResult: result)
        try await Task.sleep(nanoseconds: UInt64(4 * Double(NSEC_PER_SEC)))
        let imageResultList = try await ImageManager.shared.getImageByUid(uid: uid)
        imageView.setImageResult(imageResultList: imageResultList)
    }
    
    func getImageListWithFilter(imageListResult: [ImageResult]) -> [ImageResult] {
        if searchText == "" {
            return imageListResult
        }
        
        var result: [ImageResult] = []
        for image in imageListResult {
            if image.city.contains(searchText)  || image.country.contains(searchText) {
                result.append(image)
            }
        }
        return result
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
        NavigationStack {
            GeometryReader { reader in
                ZStack {
                    Color.white
                    VStack(alignment: .leading, spacing: 10, content: {
                        let column = Array(repeating: GridItem(.flexible(), spacing: 15), count: 2)
                        LazyVGrid(columns: column, alignment: .center, spacing: 10, content: {
                            ForEach(getImageListWithFilter(imageListResult: imageView.ImageResultList),id: \.identifier){result in
                                GridImageView(imageView: imageView, showToast: $showToast, imageResult: result, screenWidth: (reader.size.width - 40)/2, isMainPage: true)
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
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search cities, countries")
        }
    }
        
    
}

extension CLLocation {
    func fetchCityAndCountry(completion: @escaping (_ city: String?, _ country:  String?, _ error: Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(self) { completion($0?.first?.locality, $0?.first?.country, $1) }
    }
}

//#Preview {
//    MainView(imageView: ImageResultViewModel())
//}
