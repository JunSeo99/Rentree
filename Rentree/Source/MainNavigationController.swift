//
//  MainNavigationViewController.swift
//  OurSchool
//
//  Created by 송준서 on 2021/12/20.
//

import UIKit
import RxSwift
import Moya
import RxCocoa
class MainNavigationViewController: UINavigationController {
    var disposBag = DisposeBag()
    
    private var backButtonAppearance: UIBarButtonItemAppearance {
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear, .font: UIFont.systemFont(ofSize: 0.0)]
        
        return backButtonAppearance
    }
    private var backButtonImage: UIImage? {
        return UIImage(named: "Icon_Back")?.withAlignmentRectInsets(UIEdgeInsets(top: 10.0, left: 0, bottom: 10, right: 10.0))
    }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    override var shouldAutorotate:Bool{
        return false
    }
    static func makeNavigationController(rootViewController: UIViewController) -> MainNavigationViewController {
        let navigationController = MainNavigationViewController(rootViewController: rootViewController)
        navigationController.modalPresentationStyle = .fullScreen
        return navigationController
    }
    enum BarColor {
        case gray
        case defaultBackground
        case clear
    }
    func settingBarColor(type: BarColor) {
        switch type {
        case .clear:
            let appearance = navigationBar.standardAppearance
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.backgroundImage = UIImage()
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationBar.isTranslucent = false
        case .defaultBackground:
            let appearance = navigationBar.standardAppearance
            appearance.shadowImage = UIImage()
            appearance.backgroundColor = .systemBackground
            appearance.backgroundImage = UIImage()
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.setBackgroundImage(UIImage(), for: .default)
        case .gray:
            navigationBar.shadowImage = UIImage()
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = UIColor(resource: .jiuNavigationBackground)
            appearance.shadowColor = .clear
            appearance.setBackIndicatorImage(backButtonImage, transitionMaskImage: backButtonImage)
            appearance.backButtonAppearance = backButtonAppearance
            appearance.shadowImage = UIImage()
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.isTranslucent = false
            navigationBar.tintColor = UIColor.label
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        //        self.delegate = self
        view.backgroundColor = .systemBackground
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        navigationBar.shadowImage = UIImage()
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        /// transitionMaskImage파라미터: push되거나 pop될때의 backButton 마스크 이미지
        appearance.setBackIndicatorImage(backButtonImage, transitionMaskImage: backButtonImage)
        appearance.backButtonAppearance = backButtonAppearance
        appearance.shadowImage = UIImage()
        
        navigationBar.standardAppearance = appearance
        //            navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.isTranslucent = false
        /// navigationItem의 버튼 색상을 .white로 지정
        //        navigationBar.tintColor = UIColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1)
        navigationBar.tintColor = UIColor.label
        
        
        // Do any additional setup after loading the view.
    }
}
