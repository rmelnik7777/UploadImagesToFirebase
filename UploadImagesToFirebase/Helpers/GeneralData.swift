//
//  GeneralData.swift
//  UploadImagesToFirebase
//
//  Created by Роман Мельник on 25.08.2020.
//  Copyright © 2020 Роман Мельник. All rights reserved.
//

import Foundation
import UIKit
import Photos

class GeneralData {
    
    static let shared = GeneralData()
    var assetsScreen = [PHAsset]()
    var assets = [PHAsset]()
}
