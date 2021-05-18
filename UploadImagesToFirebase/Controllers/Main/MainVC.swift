//
//  MainVC.swift
//  UploadImagesToFirebase
//
//  Created by Роман Мельник on 25.08.2020.
//  Copyright © 2020 Роман Мельник. All rights reserved.
//

import RxSwift
import UIKit

class MainVC: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var itemLabel: UILabel!
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var showSharokuButton: UIButton!
    @IBOutlet weak var bgView: UIView!
    
    // MARK: - Properties
    private let presenter = MainPresenter()
    
    private let pickerController = UIImagePickerController()
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupPicker()
        presenter.viewDidLoad(in: self)
        imageView.layer.cornerRadius = imageView.frame.size.height/2
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.darkGray.cgColor
        
        showSharokuButton.layer.cornerRadius = 15
        showSharokuButton.layer.borderWidth = 2
        showSharokuButton.layer.borderColor = UIColor.darkGray.cgColor
        
        bgView.layer.cornerRadius = 15
    }
    
    // MARK: - Picker
    
    func setupPicker(){
        pickerController.delegate = self
        pickerController.allowsEditing = true
        pickerController.sourceType = .photoLibrary
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        presenter.screenCounter.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] uploaded in
                if GeneralData.shared.assetsScreen.count == 0 {
                    self?.presenter.getScreens(completion: { [weak self] success in
                        if success {
                            self?.animationBgView(show: success)
                            DispatchQueue.main.async {
                                if GeneralData.shared.assetsScreen.count == 0 {
                                    self?.presenter.getImages()
                                }
                            }
                        }else{
                            self?.openSettingsAlert()
                        }
                        
                    })
                }
                if uploaded.count != 0 && uploaded.count == GeneralData.shared.assetsScreen.count {
                    if self?.presenter.loadScreenArray.value.count == GeneralData.shared.assetsScreen.count {
                        self?.itemLabel.text = "Загрузка скринов завершена"
                        self?.presenter.getImages()
                    } else {
                        self?.presenter.getScreens(completion: {success in
                            if !success {
                                self?.animationBgView(show: success)
                                self?.openSettingsAlert()
                            }
                        })
                    }
                }
                
            }).disposed(by: presenter.disposeBag)
        presenter.fullImageCounter.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] uploaded in
                if uploaded.count != 0 && uploaded.count == GeneralData.shared.assets.count {
                    if UserDefaultsHelper.shared.getLoadFullImage?.count == GeneralData.shared.assets.count {
                        self?.itemLabel.text = "Загрузка завершена"
                    } else {
                        self?.presenter.getImages()
                    }
                }
            }).disposed(by: presenter.disposeBag)
    }
    
    @IBAction func sharakuButtonTapped(_ sender: Any) {
            self.presenter.getScreens(completion: {success in
                if success {
                    DispatchQueue.main.async {
                        self.present(self.pickerController, animated: true, completion: nil)
                    }
                }else{
                    self.openSettingsAlert()
                }
            })
    }
    
    func openSettingsAlert(){
        DispatchQueue.main.async {
            let alertController = UIAlertController (title: "Для работы с фото разрешите доступ к библиотеке в настройках телефона", message: "Открыть настройки?", preferredStyle: .alert)
            
            let settingsAction = UIAlertAction(title: "Настройки", style: .default) { (_) -> Void in
                
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)") // Prints true
                    })
                }
            }
            alertController.addAction(settingsAction)
            let cancelAction = UIAlertAction(title: "Отмена", style: .default, handler: nil)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func animationBgView(show: Bool){
        UIView.animate(withDuration: 0.5, delay: 0.2, options: .transitionCrossDissolve, animations: {
            DispatchQueue.main.async {
                self.bgView.isHidden = show ? false : true
            }
        }, completion: { _ in
            
        })
    }
}

extension MainVC: MainViewProtocol {
    func setProgressBar(progress: Float, animated: Bool) {
        DispatchQueue.main.async {
            self.progressBar.setProgress(progress, animated: animated)
        }
    }
    
    func setLabel(text: String) {
        DispatchQueue.main.async {
            self.itemLabel.text = text
        }
    }
}

extension MainVC: SHViewControllerDelegate {
    func shViewControllerImageDidFilter(image: UIImage) {
        imageView.image = image
    }
    
    func shViewControllerDidCancel() {
    }
}

extension MainVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController  , didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        print("assert enter function") /// not entered
        
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            dismiss(animated: true, completion: {
                let vc = SHViewController(image: pickedImage.forceSameOrientation())
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
            })
            print("picked image: \(pickedImage)")
        }
        
        
    }
}


extension UIImage {
    func forceSameOrientation() -> UIImage {
        UIGraphicsBeginImageContext(self.size)
        self.draw(in: CGRect(origin: CGPoint.zero, size: self.size))
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return self
        }
        UIGraphicsEndImageContext()
        return image
    }
}
