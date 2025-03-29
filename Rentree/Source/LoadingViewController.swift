//
//  LoadingViewController.swift
//  Rentree
//
//  Created by jun on 3/29/25.
//
import RxSwift
import RxCocoa
import UIKit
import Moya

class LoadingViewController : UIViewController{
    var provider: MoyaProvider<API> = .init()
    var disposeBag: DisposeBag = .init()
    override func viewDidLoad() {
        super.viewDidLoad()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navigation = storyboard.instantiateViewController(identifier: "MainNavigationViewController")
        
        provider.rx.request(.login(userId: "67e2ddfd89aa2d7acbbd5f84"))
            .observe(on: MainScheduler.asyncInstance)
            .map(User.self)
            .subscribe(onSuccess: { newUser in
                user = newUser
                navigation.modalPresentationStyle = .overFullScreen
                navigation.modalTransitionStyle = .crossDissolve
                self.present(navigation, animated: true)
            }, onFailure: { e in
                print(e)
            }).disposed(by: disposeBag)
            
        
        
        
    }
}
