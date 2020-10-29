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
    
    // MARK: - Properties
    private let presenter = MainPresenter()

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        presenter.viewDidLoad(in: self)
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        presenter.screenCounter.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] uploaded in
                if GeneralData.shared.assetsScreen.count == 0 {
                    self?.presenter.getScreens(completion: { [weak self] in
                        DispatchQueue.main.async {
                            if GeneralData.shared.assetsScreen.count == 0 {
                                self?.presenter.getImages()
                            }
                        }
                    })
                }
                if uploaded.count != 0 && uploaded.count == GeneralData.shared.assetsScreen.count {
                    if self?.presenter.loadScreenArray.value.count == GeneralData.shared.assetsScreen.count {
                        self?.itemLabel.text = "Загрузка скринов завершена"
                        self?.presenter.getImages()
                    } else {
                        self?.presenter.getScreens(completion: {})
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
