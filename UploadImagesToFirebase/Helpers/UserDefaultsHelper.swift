//
//  UserDefaultsHelper.swift
//  UploadImagesToFirebase
//
//  Created by Роман Мельник on 26.08.2020.
//  Copyright © 2020 Роман Мельник. All rights reserved.
//

import Foundation

class UserDefaultsHelper: NSObject {

    // MARK: - Properties
    static let shared = UserDefaultsHelper()

    private let kUuid = "uuid"
    private let kLoadScreenImage = "loadScreenImage"
    private let kLoadFullImage = "loadFullImage"
      
    // MARK: - Get
    var getUuid: String? {
        get { return UserDefaults.standard.value(forKey: kUuid) as? String }
    }
    
    var getLoadScreenImage: [LoadImage]? {
        get {
            if let udLoadImage = UserDefaults.standard.data(forKey: kLoadScreenImage),
            let udArchivLoadImage = NSKeyedUnarchiver.unarchiveObject(with: udLoadImage) as? [LoadImage] {
                return udArchivLoadImage
            }
            return nil
        }
    }
    
    var getLoadFullImage: [LoadImage]? {
        get {
            if let udLoadImage = UserDefaults.standard.data(forKey: kLoadFullImage),
            let udArchivLoadImage = NSKeyedUnarchiver.unarchiveObject(with: udLoadImage) as? [LoadImage] {
                return udArchivLoadImage
            }
            return nil
        }
    }
    
    // MARK: - Save
    func saveUuid(_ token: String) {
        UserDefaults.standard.set(token, forKey: kUuid)
    }
    
    func saveLoadScreenImage(_ loadImages: [LoadImage]) {
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: loadImages)
        UserDefaults.standard.set(encodedData, forKey: kLoadScreenImage)
    }
    func saveLoadFullImage(_ loadImages: [LoadImage]) {
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: loadImages)
        UserDefaults.standard.set(encodedData, forKey: kLoadFullImage)
    }
}
