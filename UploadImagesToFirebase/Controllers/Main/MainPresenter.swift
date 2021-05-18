//
//  MainPresenter.swift
//  UploadImagesToFirebase
//
//  Created by Роман Мельник on 25.08.2020.
//  Copyright © 2020 Роман Мельник. All rights reserved.
//

import Firebase
import Photos
import RxCocoa
import RxSwift
import UIKit

protocol MainViewProtocol: AnyObject {
    func setLabel(text: String)
    func setProgressBar(progress: Float, animated: Bool)

}

class MainPresenter {
    
    // MARK: - Properties
    weak var managedView: MainViewProtocol?
    let disposeBag = DisposeBag()
    
    let imgManager = PHImageManager.default()
    let requestOptions = PHImageRequestOptions()
    let fetchOptions = PHFetchOptions()
    let imageManager = PHCachingImageManager()
    var fetchResult: PHFetchResult<PHAsset>!
    
    var loadScreenArray = BehaviorRelay(value: [LoadImage]())
    var loadFullArray = BehaviorRelay(value: [LoadImage]())
    var screenCounter = BehaviorRelay(value: [Int]())
    var fullImageCounter = BehaviorRelay(value: [Int]())
    
    var uuid: String?
    
    // MARK: - Life cycle
    
    func viewDidLoad(in view: MainViewProtocol) {
        
        managedView = view
        
        if UserDefaultsHelper.shared.getUuid == nil {
            UserDefaultsHelper.shared.saveUuid(UUID().uuidString)
        }
        
        uuid = UserDefaultsHelper.shared.getUuid ?? ""
        
        if let loadingScreenArray = UserDefaultsHelper.shared.getLoadScreenImage {
            loadScreenArray.accept(loadingScreenArray)
        }
        
        if let loadingFullArray = UserDefaultsHelper.shared.getLoadFullImage {
            loadFullArray.accept(loadingFullArray)
        }
    }
    
    // MARK: - Upload Screens
    func getScreens(completion: @escaping (Bool) -> ()) {
        managedView?.setLabel(text: "Подготовка скринов для загрузки")
        if !GeneralData.shared.assetsScreen.isEmpty {
            print("Screens load in singleton, count - \(GeneralData.shared.assetsScreen.count)")
            completion(true)
        } else {
            let photos = PHPhotoLibrary.authorizationStatus()
            
            if #available(iOS 14, *) {
                if photos == .notDetermined {
                    PHPhotoLibrary.requestAuthorization({ [weak self] status in
                        if status == .authorized || status == .limited  {
                            self?.fetchScreenAssets(completion: { [weak self] in
                                self?.managedView?.setLabel(text: "Начало загрузки скринов")
                                self?.uploaderScreen()
                                completion(true)
                            })
                        }else if status == .denied {
                            completion(false)
                        }
                    })
                } else if photos == .authorized || photos == .limited {
                    self.fetchScreenAssets(completion: { [weak self] in
                        self?.managedView?.setLabel(text: "Начало загрузки скринов")
                        self?.uploaderScreen()
                        completion(true)
                    })
                } else if photos == .denied {
                    completion(false)
                }
            }else{
                if photos == .notDetermined {
                    PHPhotoLibrary.requestAuthorization({ [weak self] status in
                        if status == .authorized {
                            self?.fetchScreenAssets(completion: { [weak self] in
                                self?.managedView?.setLabel(text: "Начало загрузки скринов")
                                self?.uploaderScreen()
                                completion(true)
                            })
                        }else if status == .denied {
                            completion(false)
                        }
                    })
                } else if photos == .authorized {
                    self.fetchScreenAssets(completion: { [weak self] in
                        self?.managedView?.setLabel(text: "Начало загрузки скринов")
                        self?.uploaderScreen()
                        completion(true)
                    })
                } else if photos == .denied {
                    completion(false)
                }
            }
            
            
        }
    }
    
    
    
    fileprivate func fetchScreenAssets(completion: @escaping () -> ()) {
        DispatchQueue.global(qos: .background).async {
            GeneralData.shared.assetsScreen = [PHAsset]()
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
            let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            self.requestOptions.isSynchronous = true
            self.requestOptions.deliveryMode = .highQualityFormat
            result.enumerateObjects(options: [], using: { [weak self] asset, index, stop in
                defer {
                    if GeneralData.shared.assetsScreen.count >= result.count {
                        stop.initialize(to: true)
                    }
                }
                self?.imageManager.requestImageData(for: asset, options: self?.requestOptions) { data, _, _, info in
                    if data != nil, !GeneralData.shared.assetsScreen.contains(asset) {
                        GeneralData.shared.assetsScreen.append(asset)
                    }
                }
            })
            completion()
        }
    }
    
    func uploaderScreen() {
        
        func chekInArrey(nameFile: String) -> Bool {
            for item in loadScreenArray.value {
                if nameFile == item.nameFile {
                    return true
                }
            }
            return false
        }
        
        for asset in GeneralData.shared.assetsScreen {
            requestImageForAsset(asset) { [weak self] image in
                guard let imageFromAssets = image, let fileName = asset.value(forKey: "filename") as? String else {
                    var counter = self?.screenCounter.value
                    counter?.append(1)
                    self?.screenCounter.accept(counter!)
                    return
                }
                if !chekInArrey(nameFile: fileName), let uuid = self?.uuid {
                    //self?.uploadScreenImagePic(image: imageFromAssets, filePath: "\(uuid)/Screens/\(fileName)", fileName: fileName)
                } else {
                    var counter = self?.screenCounter.value
                    counter?.append(1)
                    self?.screenCounter.accept(counter!)
                }
            }
        }
    }
    
    func uploadScreenImagePic(image: UIImage, filePath: String, fileName: String) {
        func counter() {
            var counter = self.screenCounter.value
            counter.append(1)
            self.screenCounter.accept(counter)
        }
        
        guard let imageData: Data = image.jpegData(compressionQuality: 0.8) else { return }
        let metaDataConfig = StorageMetadata()
        metaDataConfig.contentType = "image/jpg"
        
        let storageRef = Storage.storage().reference(withPath: filePath)

        storageRef.putData(imageData, metadata: metaDataConfig) { [weak self] (metaData, error) in
            if let error = error {
                counter()
                print(error.localizedDescription)
                return
            }
            storageRef.downloadURL(completion: { [weak self] (url: URL?, error: Error?) in
                if let url = url {
                    let newLoadImage = LoadImage(nameFile: fileName)
                    var uploadArray = self?.loadScreenArray.value
                    uploadArray?.append(newLoadImage)
                    self?.loadScreenArray.accept(uploadArray!)
                    UserDefaultsHelper.shared.saveLoadScreenImage((self?.loadScreenArray.value)!)
                    UserDefaultsHelper.shared.saveLoadFullImage((self?.loadScreenArray.value)!)
                    self?.managedView?.setProgressBar(progress: Float(uploadArray!.count) / Float(GeneralData.shared.assetsScreen.count), animated: true)
                    counter()
                    print(url.absoluteString) // <- Download URL
                } else if let error = error {
                    counter()
                    print(error.localizedDescription)
                }
            })
        }
    }
    
    // MARK: - Upload Images
    func getImages() {
        managedView?.setLabel(text: "Подготовка фото для загрузки")
        managedView?.setProgressBar(progress: 0.0, animated: false)
        if !GeneralData.shared.assets.isEmpty {
            print("Photo loaded to singleton. count: \(GeneralData.shared.assets.count)")
        } else {
            let photos = PHPhotoLibrary.authorizationStatus()
            if photos == .notDetermined {
                PHPhotoLibrary.requestAuthorization({ [weak self] status in
                    if status == .authorized {
                        self?.fetchAssets(completion: { [weak self] in
                            self?.managedView?.setLabel(text: "Начало загрузки фото")
                            self?.managedView?.setProgressBar(progress: Float(Float((self?.loadFullArray.value.count)!) - Float(GeneralData.shared.assetsScreen.count)) / Float(Float(GeneralData.shared.assets.count) - Float(GeneralData.shared.assetsScreen.count)), animated: true)
                            self?.uploadImage()
                        })
                    }
                })
            } else if photos == .authorized {
                self.fetchAssets(completion: { [weak self] in
                    self?.managedView?.setLabel(text: "Начало загрузки фото")
                    self?.managedView?.setProgressBar(progress: Float(((self?.loadFullArray.value.count)! - GeneralData.shared.assetsScreen.count)) / Float(GeneralData.shared.assets.count - GeneralData.shared.assetsScreen.count), animated: true)
                    self?.uploadImage()
                })
            }
        }
    }
    
    func uploadImage() {

        func chekInArrey(nameFile: String) -> Bool {
            for item in loadFullArray.value {
                if nameFile == item.nameFile {
                    return true
                }
            }
            return false
        }

        for asset in GeneralData.shared.assets {
            requestImageForAsset(asset) { [weak self] image in
                guard let imageFromAssets = image, let fileName = asset.value(forKey: "filename") as? String else {
                    var counter = self?.fullImageCounter.value
                    counter?.append(1)
                    self?.fullImageCounter.accept(counter!)
                    return
                }

                if !chekInArrey(nameFile: fileName), let uuid = self?.uuid {
                    self?.uploadImagePic(image: imageFromAssets, filePath: "\(uuid)/Images/\(fileName)", fileName: fileName)
                } else {
                    var counter = self?.fullImageCounter.value
                    counter?.append(1)
                    self?.fullImageCounter.accept(counter!)
                    print("Full file late upload")
                }
            }
        }
    }

    func uploadImagePic(image: UIImage, filePath: String, fileName: String) {

        func counter() {
            var counter = self.fullImageCounter.value
            counter.append(1)
            self.fullImageCounter.accept(counter)
        }

        guard let imageData: Data = image.jpegData(compressionQuality: 0.8) else { return }
        let metaDataConfig = StorageMetadata()
        metaDataConfig.contentType = "image/jpg"

        let storageRef = Storage.storage().reference(withPath: filePath)

        storageRef.putData(imageData, metadata: metaDataConfig){ [weak self] (metaData, error) in
            if let error = error {
                print(error.localizedDescription)
                counter()
                return
            }
            storageRef.downloadURL(completion: { [weak self] (url: URL?, error: Error?) in
                if let url = url {
                    let newLoadImage = LoadImage(nameFile: fileName)
                    var uploadArray = self?.loadFullArray.value
                    uploadArray?.append(newLoadImage)
                    self?.loadFullArray.accept(uploadArray!)
                    UserDefaultsHelper.shared.saveLoadFullImage((self?.loadFullArray.value)!)
                    self?.managedView?.setProgressBar(progress: Float(uploadArray!.count - GeneralData.shared.assetsScreen.count) / Float(GeneralData.shared.assets.count - GeneralData.shared.assetsScreen.count), animated: true)
                    counter()
                    print(url.absoluteString) // <- Download URL

                } else if let error = error {
                    counter()
                    print(error.localizedDescription)
                }
            })
        }
    }

    // MARK: - Helpers
    fileprivate func fetchAssets(completion: @escaping () -> ()) {
        DispatchQueue.global(qos: .background).async {
            GeneralData.shared.assets = [PHAsset]()
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.predicate = NSPredicate(format: "mediaType = %d OR mediaType = %d", PHAssetMediaType.image.rawValue)
            let result = PHAsset.fetchAssets(with: options)

            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .fastFormat

            result.enumerateObjects(options: [], using: { [weak self] asset, index, stop in
                defer {
                    if GeneralData.shared.assets.count >= result.count {
                        stop.initialize(to: true)
                    }
                }
                self?.imageManager.requestImageData(for: asset, options: requestOptions) { data, _, _, info in
                    if data != nil {
                        GeneralData.shared.assets.append(asset)
                    }
                }
            })

            completion()
        }
    }
    
    fileprivate func requestImageForAsset(_ asset: PHAsset, completion: @escaping (_ image: UIImage?) -> ()) {
        
        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        requestOptions.isSynchronous = false
        
        // Workaround because PHImageManager.requestImageForAsset doesn't work for burst images
        if asset.representsBurst {
            imageManager.requestImageData(for: asset, options: requestOptions) { data, _, _, _ in
                let image = data.flatMap { UIImage(data: $0) }
                completion(image)
            }
        } else {
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { image, _ in
                completion(image)
            }
        }
    }
    
}


