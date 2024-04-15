//
//  ImageManager.swift
//  photo-storage
//
//  Created by Nabhan Suwanachote on 14/4/2567 BE.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseFirestore
import SwiftUI

final class ImageResultViewModel: ObservableObject {
    @Published var ImageResultList: [ImageResult] = []
    @Published var currentLoadedImage: Int = 0
    
    func setImageResult(imageResultList: [ImageResult]) {
        ImageResultList = imageResultList
        print("Image List: \(imageResultList)")
    }
    
    func append(imageResult: ImageResult) {
        ImageResultList.append(imageResult)
    }
    
    func concat(imageResult: [ImageResult]) {
        ImageResultList.append(contentsOf: imageResult)
    }
    
    func increaseLoadedImage() {
        currentLoadedImage += 10
    }
    
    func updateWithCondition(identifier: String, isFavorite: Bool) {
        guard var index = ImageResultList.firstIndex(where: { $0.identifier == identifier }) else { return }
        ImageResultList[index].isFavorite = isFavorite
    }
    
    func getFavorites() -> [ImageResult] {
        return ImageResultList.filter { $0.isFavorite }
    }
}

struct ImageResult {
    private let storage = Storage.storage()
    private let MAX_SIZE: Int64 = 10 * 1024 * 1024
    
    var uid: String
    var downloadURL: String
    var storageLocation: String
    var createdWhen: Double
    var isFavorite: Bool
    var identifier: String
    var city: String
    var country: String
    
    init(uid: String, downloadURL: String, storageLocation: String, createdWhen: String, isFavorite: Bool, identifier: String, city: String, country: String) {
        self.uid = uid
        self.downloadURL = downloadURL
        self.storageLocation = storageLocation
        self.createdWhen = Double(createdWhen) ?? 0
        self.isFavorite = isFavorite
        self.identifier = identifier
        self.city = city
        self.country = country
    }
}
      

final class ImageManager {
    
    static let shared = ImageManager()
    private let storage = Storage.storage()
    private let database = Firestore.firestore()
    
    private init () {}
    
    func getImageList(pageToken: String? = nil) async throws -> StorageListResult {
        let storageReference = storage.reference().child("Images")
        
        let listResult: StorageListResult
        if let pageToken = pageToken {
            listResult = try await storageReference.list(maxResults: 10, pageToken: pageToken)
        } else {
            listResult = try await storageReference.list(maxResults: 10)
          }
        return listResult
    }
    
    func getDownloadUrlFromPath(path: String) async throws -> URL {
        let storageReference = storage.reference(forURL: path)
        return try await storageReference.downloadURL()
    }
    
    func addImageURLToDatabase(uid: String, values: [String : AnyObject]) {
        database.collection("ImageData").document().setData(values)
    }
    
    func getImageByUid(uid: String) async throws -> [ImageResult] {
        var result: [ImageResult] = []
        var identifiers: [String] = []
        let querySnapshot = try await database.collection("ImageData").whereField("uid", isEqualTo: uid).order(by: "createdWhen").getDocuments()
        for document in querySnapshot.documents {
            let imageInfo = document.data()
            let uid = imageInfo["uid"] as? String ?? ""
            let downloadURL = imageInfo["downloadURL"] as? String ?? ""
            let storageLocation = imageInfo["storageLocation"] as? String ?? ""
            let createdWhen = imageInfo["createdWhen"] as? String ?? ""
            let isFavorite = imageInfo["isFavorite"] as? Bool ?? false
            let identifier = imageInfo["identifier"] as? String ?? ""
            let city = imageInfo["city"] as? String ?? ""
            let country = imageInfo["country"] as? String ?? ""
            let imageObject = ImageResult(uid: uid, downloadURL: downloadURL, storageLocation: storageLocation, createdWhen: createdWhen, isFavorite: isFavorite, identifier: identifier, city: city, country: country)
            if identifier != "" {
                identifiers.append(identifier)
            }
            result.append(imageObject)
        }
        preselectedAssetIdentifiers = identifiers
        print(preselectedAssetIdentifiers)
        return result
    }
    
    func updateFavorite(uid: String, identifier: String, isFavorite: Bool) {
        let querySnapshot = database.collection("ImageData").whereField("uid", isEqualTo: uid).whereField("identifier", isEqualTo: identifier).getDocuments(completion: { documentSnapshot, error in
            if let err = error {
                print(err.localizedDescription)
                return
            }

            guard let docs = documentSnapshot?.documents else { return }

            for doc in docs { //iterate over each document and update
                let docRef = doc.reference
                docRef.updateData(["isFavorite" : isFavorite])
            }
        })
    }
    
    func uploadFile(imageData: Data, fileName: String, uid: String, identifier: String?, city: String, country: String) -> ImageResult? {
        let storageReference = Storage.storage().reference().child("Images").child("\(uid)-\(fileName).jpg")
        var result: ImageResult? = nil
        storageReference.putData(imageData, metadata: nil) { metadata, error in
            if(error != nil){
                print(error)
                return
            }
            // Fetch the download URL
            let storageLocation = String(describing: storageReference)
            storageReference.downloadURL { url, error in
                if let error = error {
                    // Handle any errors
                    if(error != nil){
                        print(error)
                        return
                    }
                } else {
                    // Get the download URL for 'images/stars.jpg'

                    let urlStr:String = (url?.absoluteString) ?? ""
                    let createdWhen = String(NSDate().timeIntervalSince1970)
                    let values = ["uid": uid, "downloadURL": urlStr, "storageLocation": storageLocation, "isFavorite": false, "createdWhen": createdWhen, "identifier": identifier ?? "", "city": city, "country": country]
                    self.addImageURLToDatabase(uid: uid, values: values as [String : AnyObject])
                    result = ImageResult(uid: uid, downloadURL: urlStr, storageLocation: storageLocation, createdWhen: createdWhen, isFavorite: false, identifier: identifier ?? "", city: city, country: country)
                }
            }
        }
        return result
    }
}
