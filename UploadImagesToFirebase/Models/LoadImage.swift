//
//  LoadImage.swift
//  UploadImagesToFirebase
//
//  Created by Роман Мельник on 27.08.2020.
//  Copyright © 2020 Роман Мельник. All rights reserved.
//

import UIKit

class LoadImage: NSObject, NSCoding {
    
    var nameFile: String
    
    init(nameFile: String) {
        self.nameFile = nameFile
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let nameFile = aDecoder.decodeObject(forKey: "nameFile") as? String ?? " "
        self.init(nameFile: nameFile)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(nameFile, forKey: "nameFile")
    }
    
}
