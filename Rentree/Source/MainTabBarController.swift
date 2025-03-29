//
//  MainTabarController.swift
//  Rentree
//
//  Created by jun on 3/25/25.
//
import UIKit
import Moya
import RxSwift
import RxCocoa
var isOpenModal: Bool = false
class MainTabBarController: UITabBarController {
    let socketManager = SocketManager()
    var disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        let postListView = PostListView(nibName: "PostListView", bundle: nil)
        let postListNavi = MainNavigationViewController(rootViewController: postListView)
        postListNavi.tabBarItem = .init(title: "홈", image: UIImage(resource: .home).resize(newWidth: 34), tag: 0)
        postListNavi.title = "홈"
        
        
        // 이름을 표시할 UILabel 생성
        let nameLabel = UILabel()
        nameLabel.text = user.schoolCode
        nameLabel.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        nameLabel.textColor = .black
        nameLabel.sizeToFit()           // 레이블 크기 자동 조정
        
        // UILabel을 navigation bar의 왼쪽에 customView로 추가
        postListView.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: nameLabel)
        
       
        
        let vc1 = ApplyTabman()
        let navi1 = MainNavigationViewController(rootViewController: vc1)
        navi1.tabBarItem = .init(title: "내역", image: .iconList.resize(newWidth: 34), tag: 1)
        navi1.title = "내역"
        
        
       
        
        let chatView = RoomListView(nibName: "RoomListView", bundle: nil)
        let chatProvider = MoyaProvider<ChatAPI>()
        chatView.reactor = .init(chatProvider: chatProvider, socketManager: socketManager)
        
        
        let navi2 = MainNavigationViewController(rootViewController: chatView)
        navi2.tabBarItem = .init(title: "채팅", image: .chat.resize(newWidth: 34), tag: 2)
        navi2.title = "채팅"
        
        let profileView = ProfileView(nibName: "ProfileView", bundle: nil)
        let profileNavi = MainNavigationViewController(rootViewController: profileView)
        profileNavi.tabBarItem = .init(title: "프로필", image: .iconProfile.resize(newWidth: 34), tag: 3)
        profileNavi.title = "프로필"
        
        setViewControllers([postListNavi,navi1, navi2 ,profileNavi], animated: true)
        
        MainNotification.default
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: {[weak self, weak chatView] notification in
                guard let notification, let self else { return }
                MainNotification.default.onNext(nil)
                
                switch notification {
                case .moveToRoom(let room):
                    guard let chatView else { return }
                    navigationController?.popToRootViewController(animated: true)
                    if chatView.isViewLoaded {
                        chatView.reactor?.action.onNext(.itemSelected(room))
                    }
                    else{
                        self.selectedIndex = 2
                        chatView.reactor?.state.map({$0.rooms})
                            .filter({!$0.isEmpty})
                            .take(1)
                            .subscribe(onNext: {  _ in
                                self.selectedIndex = 2
                                chatView.reactor?.action.onNext(.itemSelected(room))
                            }).disposed(by: chatView.disposeBag)
                    }
                case .moveToPost(let post):
                    navigationController?.popToRootViewController(animated: true)
                    let vc = PostDetailView(nibName: "PostDetailView", bundle: nil)
                    vc.rx.viewDidLoad
                        .subscribe(onNext: {[weak vc] _ in
                            vc?.borrowButton.isHidden = true
                            
                        }).disposed(by: vc.disposeBag)
                    vc.post = post
                    navigationController?.pushViewController(vc, animated: true)
//                    if chatView.isViewLoaded {
//                        chatView.reactor?.action.onNext(.itemSelected(room))
//                    }
//                    else{
//                        self.selectedIndex = 2
//                        chatView.reactor?.state.map({$0.rooms})
//                            .filter({!$0.isEmpty})
//                            .take(1)
//                            .subscribe(onNext: {  _ in
//                                self.selectedIndex = 2
//                                chatView.reactor?.action.onNext(.itemSelected(room))
//                            }).disposed(by: chatView.disposeBag)
//                    }
                case .refresh:
                    break
                }
            }).disposed(by: disposeBag)
        
        updateTabBarAppearance()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isOpenModal {
            isOpenModal = false
            return
        }
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func updateTabBarAppearance() {
        let tabBarAppearance: UITabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        let barTintColor: UIColor = .jiuNavigationBackground
        tabBarAppearance.backgroundColor = barTintColor

        updateTabBarItemAppearance(appearance: tabBarAppearance.compactInlineLayoutAppearance)
        updateTabBarItemAppearance(appearance: tabBarAppearance.inlineLayoutAppearance)
        updateTabBarItemAppearance(appearance: tabBarAppearance.stackedLayoutAppearance)
        tabBarAppearance.shadowColor = .clear
//        tabBarAppearance.shadowImage =
        self.tabBar.standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            self.tabBar.scrollEdgeAppearance = tabBarAppearance
        }
        UITabBar.appearance().shadowImage = UIImage()
        
        let lineView = UIView()
        view.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        lineView.backgroundColor = .jiuItem3
    }
    
    func updateTabBarItemAppearance(appearance: UITabBarItemAppearance) {
        let tintColor: UIColor = .jiuTabbarTint
        let unselectedItemTintColor: UIColor = .jiuTabbarUnselected
        appearance.selected.iconColor = tintColor
        appearance.selected.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: tintColor
        ]
        appearance.normal.iconColor = unselectedItemTintColor
        appearance.normal.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: unselectedItemTintColor
        ]
    }
    
}

