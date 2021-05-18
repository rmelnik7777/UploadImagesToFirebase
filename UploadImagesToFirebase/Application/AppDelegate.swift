//
//  AppDelegate.swift
//  UploadImagesToFirebase
//
//  Created by Роман Мельник on 25.08.2020.
//  Copyright © 2020 Роман Мельник. All rights reserved.
//

import Firebase
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        return true
    }


}

