//
//  MyPostView.swift
//  Rentree
//
//  Created by jun on 3/28/25.
//

import UIKit
import Moya
import RxSwift
import RxCocoa
import ReactorKit
import RxDataSources
import Reusable
import AVFoundation

class MyPostView: UIViewController, StoryboardView {
    typealias AnnouncementSectionModel = AnimatableSectionModel<String, MyPostItem>
    typealias Reactor = MyPostReactor
    typealias DataSoruce = RxTableViewSectionedAnimatedDataSource<AnnouncementSectionModel>
    @IBOutlet weak var tableView: UITableView!
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView.register(cellType: MyPostCell.self)
        tableView.register(cellType: MyPostUserCell.self)
        if reactor?.currentState.posts.isEmpty == true {
            reactor?.action.onNext(.refresh)
        }
        // Do any additional setup after loading the view.
    }
    
    func bind(reactor: MyPostReactor) {
        let handler = RefreshHandler(view: tableView)
        
        handler.refresh
            .map({Reactor.Action.refresh})
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.map({$0.endUpdate})
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { end in
                if end {
                    handler.end()
                }
            }).disposed(by: disposeBag)
        
//        tableView.rx.setDelegate(self)
//            .disposed(by: disposeBag)
        
        
        let animationConfiguration = AnimationConfiguration(insertAnimation: .fade, reloadAnimation: .none, deleteAnimation: .fade)
        
        let dataSource = DataSoruce(
            animationConfiguration: animationConfiguration,
            decideViewTransition: { dataSource, tableView, changeSet in
                let insertedSections = changeSet.flatMap { set in
                    set.insertedSections
                }
                if insertedSections.count > 0 {
                    return .reload
                }
                return .animated
            },configureCell: {[weak self] datasource, tableView, indexPath, item in
                guard let self else {return UITableViewCell()}
                switch item {
                case .post(let post):
                    let cell = tableView.dequeueReusableCell(for: indexPath, cellType: MyPostCell.self)
                    cell.bindUI(post: post)
                    
                    if reactor.currentState.opendSectionIds.contains(where: {$0 == post.id}) {
                        cell.arrowImageView.transform = .identity
                    }
                    else {
                        cell.arrowImageView.transform = .init(rotationAngle: .pi)
                    }
                    
                    cell.seperatorView.isHidden = indexPath.section == 0
                    //                cell.mainStackViewTop.constant = indexPath.section == 0 ? 16 : 29
                    //                cell.bottomBarView.isHidden =
                    //                cell.contentView.layoutIfNeeded()
                    cell.goToPostClicked
                        .map({Reactor.Action.movePostView(post)})
                        .bind(to: reactor.action)
                        .disposed(by: cell.disposeBag)
                    
                    cell.openClicked
                        .map({Reactor.Action.openSection(id: post.id)})
                        .bind(to: reactor.action)
                        .disposed(by: cell.disposeBag)
                    return cell
                case .user(let post, let user2):
                    let cell = tableView.dequeueReusableCell(for: indexPath, cellType: MyPostUserCell.self)
//                    let post = reactor.currentState.posts[indexPath.section]
                    
                    cell.bindUI(borrower: user2, indexText: "(\(indexPath.row )/\(post.borrowerInfo.count))")
                    
                    cell.goToChat
                        .map({Reactor.Action.moveToChat(userId: user.id, targetId: user2.userId)})
                        .bind(to: reactor.action)
                        .disposed(by: cell.disposeBag)
                    
                    cell.returnBack
                        .subscribe(onNext: { _ in
                            self.openCameraView(borrowerId: user2.userId, postId: post.id)
                        }).disposed(by: disposeBag)
                    //                if let announcementId = user.announcementId {
                    //                    cell.moveChatView.map({Reactor.Action.moveToChat(userId: user.userId, announcementId: announcementId)})
                    //                        .bind(to: reactor.action)
                    //                        .disposed(by: cell.disposeBag)
                    //
                    //                    cell.moveAlbaInformationView
                    //                        .map({Reactor.Action.moveAlbaInformationView(userId: userId)})
                    //                        .bind(to: reactor.action)
                    //                        .disposed(by: cell.disposeBag)
                    //
                    //                    cell.changedState
                    //                        .flatMap({[weak self] state -> Observable<Int> in
                    //                            guard let self else {return .empty() }
                    //                            if state == -1 {
                    //                                return self.showAlert(title: "제안을 취소하시겠습니까?",message: nil, okTitle: "예",cancelTitle: "아니오", onlyOk: false).flatMap { actionType -> Observable<Int> in
                    //                                    switch actionType {
                    //                                    case .ok:
                    //                                        return .just(state)
                    //                                    case .cancel:
                    //                                        return .empty()
                    //                                    }
                    //                                }
                    //                            }
                    //                            return .just(state)
                    //                        })
                    //                        .map({Reactor.Action.changedState(userId: userId, announcementId: announcementId, state: $0)})
                    //                        .bind(to: reactor.action)
                    //                        .disposed(by: cell.disposeBag)
                    //                }
                    return cell
                }
            })
        
        reactor.state.compactMap({$0.alert})
            .subscribe(onNext: {[weak self] e in
                self?.presentAlert(title: e, content: nil, okAction: {}, cancleAction: nil)
            }).disposed(by: disposeBag)
        
        
        Observable.combineLatest(
            reactor.state.map({$0.opendSectionIds})
                .distinctUntilChanged()
                .do(onNext: {[weak self] sections in
                    guard let self else { return }
                    if sections.isEmpty {
                        self.tableView.indexPathsForSelectedRows?.forEach({ indexPath in
                            self.tableView.deselectRow(at: indexPath, animated: true)
                        })
                    }
                }),
            reactor.state.map({$0.posts})
                .distinctUntilChanged()
        )
        .map({ ids, posts in
            return posts.map { post in
                if ids.contains(post.id) {
                    return AnnouncementSectionModel(model: post.id,
                                                    items: [AnnouncementSectionModel.Item.post(post)] + post.borrowerInfo.map({ borrower in
                        return AnnouncementSectionModel.Item.user(post, borrower)
                    }))
                }
                else{
                    return AnnouncementSectionModel(model: post.id,
                                                    items: [AnnouncementSectionModel.Item.post(post)])
                }
            }
        })
        //        .observe(on: MainScheduler.asyncInstance)
        .bind(to: tableView.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
    }
    var returningBorrowerId: String?
    var returningPostId: String?
    func openCameraView(borrowerId: String, postId: String) {
        returningBorrowerId = borrowerId
        returningPostId = postId
        AVCaptureDevice.requestAccess(for: .video, completionHandler: {(granted: Bool) in
            if granted {
                DispatchQueue.main.async {
                    let camera = UIImagePickerController()
                    camera.sourceType = .camera
                    camera.allowsEditing = false
                    camera.cameraDevice = .rear
                    camera.cameraCaptureMode = .photo
                    camera.delegate = self
                    
                    self.present(camera, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                        UIApplication.shared.open(appSettings)
                    }
                }
            }
        })
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
extension MyPostView: UIImagePickerControllerDelegate & UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: { [weak self] in
            guard let self = self else { return }
//            self.reloadInputViews()
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                let resizer = ImageResizer()
                resizer.imageResize(image: image)
                    .subscribe(onNext:{ image in
                        guard let returningPostId = self.returningPostId, let returningBorrowerId = self.returningBorrowerId else { return }
                        self.reactor?.action.onNext(.returnBack(postId: returningPostId, borrowerId: returningBorrowerId, image: image))
                    }).disposed(by: self.disposeBag)
            }
        })
    }
}


class MyPostReactor: Reactor {
    var initialState: State = State()
    let chatProvider =  MoyaProvider<ChatAPI>()
    var provider =  MoyaProvider<API>()
    struct State {
        var endUpdate: Bool = false
        var posts: [Post] = []
        var post: Post?
        var alert: String?
        var opendSectionIds: [String] = []
    }
    
    enum Action {
        case refresh
        case itemSelected(Post)
        case movePostView(Post?)
        case moveToChat(userId: String, targetId: String)
        case openSection(id: String)
        case returnBack(postId: String, borrowerId: String, image: Data)
    }
    
    enum Mutation {
        //        case setIsEmpty(Bool)
        case setPosts([Post])
        case setPostView(Post?)
        case setEndUpdate(Bool)
        case setAlert(String?)
        case setOpenedSectionIds( [String])
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation{
        case .setPosts(let posts):
            newState.posts = posts
        case .setPostView(let post):
            newState.post = post
            //        case .setIsEmpty(let empty):
            //            newState.isEmpty = empty
        case .setEndUpdate(let end):
            newState.endUpdate = end
        case .setAlert(let alert):
            newState.alert = alert
        case .setOpenedSectionIds(let ids):
            newState.opendSectionIds = ids
        }
        return newState
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .refresh:
            return .concat([
                .just(.setEndUpdate(false)),
                provider.rx.request(API.getMyPost(userId: user.id))
                    .map([Post].self)
                    .asObservable()
                    .do(onError: {
                        print("error: ", $0)
                    })
                    .flatMap({[weak self] datas -> Observable<Mutation> in
                        guard let self else {return .empty() }
                        var isEmpty = datas.isEmpty
                        return Observable.concat([
                            .just(.setPosts(datas)),
                            .just(.setEndUpdate(true)),
                        ])
                    })
                    .catch({ _ -> Observable<Mutation> in
                        return Observable.concat([
                            .just(.setEndUpdate(true))
                        ])
                    })
            ])
            
        case .itemSelected(let post):
            return .concat([
                .just(.setPostView(post)),
                .just(.setPostView(nil)),
                
            ])
            
        case .movePostView(post: let post):
            if let post {
                MainNotification.default.onNext(.moveToPost(post))                
            }
            return .concat([
                .just(.setPostView(post)),
                .just(.setPostView(nil))
            ])
            
        case .moveToChat(userId: let userId, targetId: let targetId):
            return chatProvider.rx.request(.getRoomTarget(userId: userId, targetId: targetId))
                .do(onSuccess: {
                    print(String(data:$0.data,encoding: .utf8)!)
                })
                .asObservable()
                .flatMap({[weak self] response -> Observable<Mutation> in
                    guard let self else { return .empty() }
                    if let json = try? response.map([String: String].self),
                       let errMsg = json["errMsg"] {
                        return .concat([
                            .just(.setAlert(errMsg)),
                            .just(.setAlert(nil))
                        ])
                    }
                    if let room = try? response.map(Room.self) {
                        MainNotification.default.onNext(.moveToRoom(room))
                        return .empty()
                    }
                    else{
                        return .concat([
                            .just(.setAlert(APIError.failConnect.rawValue)),
                            .just(.setAlert(nil))
                        ])
                    }
                })
            
        case .openSection(id: let id):
            
            
            if currentState.opendSectionIds.contains(id) {
                var newIds = currentState.opendSectionIds
                newIds.removeAll(where: {$0 == id})
                return .just(.setOpenedSectionIds(newIds))
            }
            else{
                var newIds = currentState.opendSectionIds
                newIds.append(id)
                return .just(.setOpenedSectionIds(newIds))
            }
        case .returnBack(postId: let postId, borrowerId: let borrowerId, image: let image):
            return provider.rx.request(API.allowBorrowing(postId: postId, userId: borrowerId))
                .asObservable()
                .flatMap({[weak self] datas -> Observable<Mutation> in
                    guard let self else {return .empty() }
                    return self.mutate(action: .refresh)
                })
                .catch({ _ -> Observable<Mutation> in
                    return .empty()
                })
        }
        
    }
}

enum MyPostItem: Equatable, IdentifiableType {
    typealias Identity = String
    var identity: String {
        switch self {
        case .post(let post):
            return post.id
        case .user(let post, let user):
            return post.id + user.userId
        }
    }
    case post(Post)
    case user(Post, BorrowerInfo)
}
