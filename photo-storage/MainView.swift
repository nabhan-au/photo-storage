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
    
    func getNotExistImage(results: [PHPickerResult], uid: String) async throws -> [PHPickerResult] {
        let identifiers = results.map {
            $0.assetIdentifier ?? ""
        }.filter {
            $0 != ""
        }
        let notExistImageIdentifier = try await ImageManager.shared.getNotExistImageIdentifier(identifer: identifiers, uid: uid)
        return results.filter {
            let iden = $0.assetIdentifier ?? ""
            if notExistImageIdentifier.contains(iden) {
                return true
            }
            return false
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
}


struct MainView: View {
    @StateObject var imageView: ImageResultViewModel
    @StateObject private var viewModel = MainViewModel()
    @Binding var showToast: ToastObject?
    @State var showPicker = false
    @State var searchText = ""
    @State private var isUploading = false
    @State private var uploadProgress: Float = 0.0
    
    func uploadPhotoAndUpadate(results: [PHPickerResult]) async throws {
        let uid = try AuthenticationManager.shared.getAuthenticatedUser().uid
        let uniqueResult = try await viewModel.getNotExistImage(results: results, uid: uid)
        if uniqueResult.count == 0 {
            return
        }
        isUploading = true
        uploadProgress = 0.0  // Reset progress at start
        let increment = 1.0 / Float(uniqueResult.count)
        
        for result in uniqueResult {
            let processResult = viewModel.processSelectedImages(results: [result])
            imageView.concat(imageResult: processResult)
            uploadProgress += increment
            try await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
        }
        try await Task.sleep(nanoseconds: UInt64(4 * Double(NSEC_PER_SEC)))
        let imageResultList = try await ImageManager.shared.getImageByUid(uid: uid)
        imageView.setImageResult(imageResultList: imageResultList)
        
        isUploading = false
        uploadProgress = 1.0
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
                    ScrollView (.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 10, content: {
                            let column = Array(repeating: GridItem(.flexible(), spacing: 15), count: 2)
                            LazyVGrid(columns: column, alignment: .center, spacing: 10, content: {
                                ForEach(getImageListWithFilter(imageListResult: imageView.ImageResultList),id: \.identifier){result in
                                    GridImageView(imageView: imageView, showToast: $showToast, imageResult: result, screenWidth: (reader.size.width - 40)/2, isMainPage: true)
                                }
                            })
                            Spacer()
                        })
                    }
                    VStack {
                        if isUploading {
                            ZStack {
                                Color.white  // Set background to white
                                        .cornerRadius(10)  // Rounded corners for aesthetic
                                        .frame(height: 60)  // Fixed height for the ZStack
                                        .shadow(color: .gray, radius: 3, x: 0, y: 2)  // Apply a shadow beneath the bar  // Optional rounded corners for aesthetic
                                VStack {
                                    Text("Uploading image")
                                                .foregroundColor(.black)  // Text color changed to black for contrast on white background
                                                .padding(.top, 4)  // Vertical padding to ensure text is not too close to the edges
                                                .padding(.horizontal)  // Horizontal padding for the text
                                            ProgressView(value: uploadProgress, total: 1.0)
                                                .progressViewStyle(LinearProgressViewStyle(tint: .gray))  // Tint color can be adjusted
                                                .scaleEffect(x: 1, y: 2, anchor: .center)  // Scale Progress bar for a thicker look
                                                .padding(.horizontal)  // Horizontal padding around the progress bar
                                                .padding(.bottom, 4)
                                }
                            }.frame(maxWidth: .infinity, maxHeight: 60)
                        }
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
