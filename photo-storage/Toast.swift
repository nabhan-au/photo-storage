//
//  Toast.swift
//  photo-storage
//
//  Created by Nabhan Suwanachote on 15/4/2567 BE.
//

import Foundation
import SwiftUI

struct ToastObject : Identifiable {
    var id = UUID()
    let message: String
    var symbol: String
    var color: Color
}
