//
//  ImagePicker.swift
//  photo-storage
//
//  Created by Nabhan Suwanachote on 14/4/2567 BE.
//

import PhotosUI
import SwiftUI

func resetPreselectedAssetIdentifiers() {
    preselectedAssetIdentifiers = []
}

var preselectedAssetIdentifiers:[String] = []

struct PHPickerSwiftUI: UIViewControllerRepresentable {
   
    @Environment(\.presentationMode) var presentationMode
    let config: PHPickerConfiguration
    let completion: (_ selectedImages: [PHPickerResult]) -> Void
    
    func makeUIViewController(context: Context) ->  PHPickerViewController {
        let controller = PHPickerViewController(configuration: config)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // We'll not update anything on this view.
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: PHPickerViewControllerDelegate {
        let parent: PHPickerSwiftUI
        
        init(parent: PHPickerSwiftUI) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            preselectedAssetIdentifiers = results.map(\.assetIdentifier!)
            do {
                let uid = try AuthenticationManager.shared.getAuthenticatedUser().uid
            } catch {
                print("Error \(error)")
            }
            self.parent.completion(results)
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
}
