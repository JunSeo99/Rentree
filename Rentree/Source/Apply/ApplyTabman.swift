//
//  ApplyTabman.swift
//  Rentree
//
//  Created by jun on 3/27/25.


import Foundation
import Tabman
import Pageboy
import Moya
import RxSwift
import RxCocoa

class ApplyTabman: TabmanViewController,
                         PageboyViewControllerDataSource,
                         TMBarDataSource {
    var defualtPage: PageboyViewController.Page = .first
    var provider: MoyaProvider<API> = .init()
    var viewControllers: Array<UIViewController> = []
    
    func numberOfViewControllers(in pageboyViewController: Pageboy.PageboyViewController) -> Int {
        viewControllers.count
    }
    
    func viewController(for pageboyViewController: Pageboy.PageboyViewController, at index: Pageboy.PageboyViewController.PageIndex) -> UIViewController? {
        viewControllers[index]
    }
    
    func defaultPage(for pageboyViewController: Pageboy.PageboyViewController) -> Pageboy.PageboyViewController.Page? {
        return defualtPage
    }
    
    func barItem(for bar: Tabman.TMBar, at index: Int) -> Tabman.TMBarItemable {
        switch index {
        case 0:
            let item = TMBarItem(title: "내 물품")

            return item
        case 1:
            let item =  TMBarItem(title: "빌린 물품")
            return item
//        case 2:
//            return TMBarItem(title: "채팅")
        default:
            return TMBarItem(title: "")
        }
    }
    var disposeBag = DisposeBag()
    var isViewDidLoaded: Bool = false
//    var socketManager: SocketManager?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let lineView = UIView()
        lineView.backgroundColor = .jiuItem3
        self.view.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        let lineView2 = UIView()
        lineView2.backgroundColor = .jiuItem3
        self.view.addSubview(lineView2)
        lineView2.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottomMargin)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(2)
        }
        
        
        self.navigationItem.title = "물품 관리"
        
        viewControllers.append(UIViewController())
        viewControllers.append(UIViewController())
        
        let bar = TMBar.ButtonBar()
//        let badgeView1 = BadgeDotView()
//        let badgeView2 = BadgeDotView()
//        let firstTitleWidth = "지원".width(withConstrainedHeight: 16, font: .systemFont(ofSize: 15, weight: .bold))
//        let secondTitleWidth = "내가 한 제안".width(withConstrainedHeight: 16, font: .systemFont(ofSize: 15, weight: .bold))
        bar.backgroundView.style = .clear
        bar.layout.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        bar.buttons.customize { (button) in
            
            button.font = .systemFont(ofSize: 15,weight: .bold)
            button.tintColor = .jiuItem6 // 선택 안되어 있을 때
            button.selectedTintColor = .jiuFontMain // 선택 되어 있을 때
            bar.backgroundColor = .jiuDefualt
        }
         
        bar.indicator.weight = .light
        bar.indicator.tintColor = .jiuFontMain
        bar.indicator.overscrollBehavior = .compress
        bar.layout.alignment = .centerDistributed
        bar.layout.contentMode = .fit
        bar.layout.interButtonSpacing = 0 // 버튼 사이 간격
        bar.layout.transitionStyle = .progressive // Customize
        // Add to view
        addBar(bar, dataSource: self, at: .top)
        dataSource = self
        isViewDidLoaded = true
    }
}
