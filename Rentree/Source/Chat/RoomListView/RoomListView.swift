//
//  RoomListView.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import ReactorKit
import Moya
import Kingfisher
import AVFoundation
import SnapKit
import Reusable

class RoomListView: UIViewController, StoryboardView {
    typealias DataSoruce = RxTableViewSectionedReloadDataSource<RoomListModelType>
    @IBOutlet weak var tableView: UITableView!
    var disposeBag = DisposeBag()
    var viewDidLoaded = false
    func bind(reactor: RoomListReactor) {
        reactor.action.onNext(.refresh)
//        reactor.action.onNext(.registerSocket)
        reactor.action.onNext(.registerSocketConnect)

        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)


        let dataSource = DataSoruce(configureCell: { datasource, tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(for: indexPath, cellType: RoomCell.self)
            cell.bind(item)
            return cell
        }, canEditRowAtIndexPath: { d,i in
            return true
        })
        
        reactor.state.map({$0.rooms})
            .distinctUntilChanged()
            .map({[RoomListModelType(items: $0)]})
            .observe(on: MainScheduler.instance)
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        reactor.state.compactMap({$0.chatReactor})
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] chatReactor in
                guard let self else {return}
                if let chatView = (self.navigationController?.navigationController?.viewControllers.last as? ChatView),let roomId = chatView.reactor?.currentState.roomId {
                    if roomId == chatReactor.currentState.roomId{
                        return
                    }
                    self.navigationController?.navigationController?.popViewController(animated: true)
                }
                let storyboard = UIStoryboard(name: "ChatMain", bundle: nil)
                guard let chatView = storyboard.instantiateViewController(withIdentifier: "ChatView") as? ChatView else {return}
                chatView.reactor = chatReactor
                self.navigationController?.navigationController?.pushViewController(chatView, animated: true)
                chatView.rx.viewWillDisappear
                    .map({ _ in Reactor.Action.unreadCountToZero(roomId: chatReactor.currentState.roomId) })
                    .bind(to: reactor.action)
                    .disposed(by: chatView.disposeBag)
                
                chatReactor.state.compactMap({$0.room as? Room})
                    .distinctUntilChanged()
                    .skip(1)
                    .map({Reactor.Action.updateRoom($0)})
                    .bind(to: reactor.action)
                    .disposed(by: chatView.disposeBag)
                
                
                if (chatReactor.initialState.room as? Room)?.isBlock == true{
                    chatView.rx.viewDidAppear
                        .take(1)
                        .subscribe(onNext: { _ in
                            chatReactor.action.onNext(.initAlert(.hrUserOut))
                        }).disposed(by: chatView.disposeBag)
                }
                if user?.userType == "manager" {
                    chatView.navigationItem.title = "지원자 채팅"
                }
                else{
                    chatView.navigationItem.title = "사장님 채팅"
                }
            }).disposed(by: disposeBag)
        
        tableView.rx.modelSelected(Room.self)
            .map(Reactor.Action.itemSelected)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        
//        rx.viewWillAppear
//            .subscribe(onNext: { _ in
//                reactor.action.onNext(.refresh)
//            }).disposed(by: disposeBag)

//        reactor.state.map({!$0.isEmpty})
//            .distinctUntilChanged()
//            .observe(on: MainScheduler.instance)
//            .bind(to: emptyView.rx.isHidden)
//            .disposed(by: disposeBag)
        
    }
//    lazy var emptyView = EmptyView(text: user?.userType == "manager" ? "아직 하고있는 채팅이 없어요!\n새로운 인재를 뽑아보세요!" : "아직 채팅이 없어요.\n공고에 지원해보세요!")
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.view.addSubview(emptyView)
        viewDidLoaded = true
//        emptyView.snp.makeConstraints { make in
//            make.center.equalToSuperview()
//        }
        tableView.register(cellType: RoomCell.self)
        tableView.separatorStyle = .none
        self.title = "채팅"
    }
    
    
}

extension RoomListView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var actions: [UIContextualAction] = []
        let pushOption = UIContextualAction(style: .normal, title: "", handler: { [weak self] action,view, success
            in
            guard let self = self else {
                success(false)
                return
            }
            
            self.reactor?.action.onNext(.notificationSwitch(indexPath: indexPath))
            success(true)
        })
        if let room = self.reactor?.currentState.rooms[safe:indexPath.row]{
            pushOption.title = room.notificationStatus ? "ㅤ⠀알림 끄기⠀" : "⠀알림 켜기⠀"
            actions.append(pushOption)
        }
        let config = UISwipeActionsConfiguration(actions: actions)
        config.performsFirstActionWithFullSwipe = true
        return config
    }
}
class RoomListReactor: Reactor {
    var initialState: State = State()
    var socketManager: SocketManager
    var userType: String
    var chatProvider: MoyaProvider<ChatAPI>
    init(chatProvider: MoyaProvider<ChatAPI>, socketManager: SocketManager,userType: String) {
        self.userType = userType // "alba", "manager"
        self.chatProvider = chatProvider
        self.socketManager = socketManager
    }
    struct State{
        var rooms: [Room] = []
        var chatReactor: ChatReactor?
        var isEmpty: Bool = false
//        var alert: APIError?
        var badgeCount: Int = 0
    }
    enum Action{
        case refresh
        case updateRoom(Room)
        case itemSelected(Room)
        case registerSocket
        case registerSocketConnect
        case unreadCountToZero(roomId: String)
        case notificationSwitch(indexPath: IndexPath)
    }
    enum Mutation{
        case setRooms([Room])
        case setChatReactor(ChatReactor?)
        case setEmpty(Bool)
//        case setAlert(APIError?)
        case setBagedCount(Int)
    }
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation{
        case .setRooms(let rooms):
            newState.rooms = rooms
        case .setEmpty(let isEmpty):
            newState.isEmpty = isEmpty
        case .setChatReactor(let reactor):
            newState.chatReactor = reactor
//        case .setAlert(let alert):
//            newState.alert = alert
        case .setBagedCount(let badgeCount):
            newState.badgeCount = badgeCount
        }
        return newState
    }
    func mutate(action: Action) -> Observable<Mutation> {
        switch action{
        case .refresh:
            return chatProvider.rx.request(.getRooms(userId: user!.id, userType: userType))
                .map([Room].self)
                .debug()
                .asObservable()
                .flatMap({ items -> Observable<Mutation> in
                    return .concat([
                        .just(.setRooms(items)),
                        .just(.setEmpty(items.isEmpty)),
                        .just(.setBagedCount(items.reduce(0, {$0 + $1.unreadCount})))
                    ])
                })
                
        case .itemSelected(var item):
            let chatReactor = ChatReactor(socketManager: self.socketManager, provider: self.chatProvider, room: item)
            item.unreadCount = 0
            if !currentState.rooms.contains(where: {$0.id == item.id}) {
                var newRooms = currentState.rooms
                newRooms.insert(item, at: 0)
                return .concat([
                    .just(.setRooms(newRooms)),
                    .just(.setChatReactor(chatReactor)),
                    .just(.setChatReactor(nil))
                ])
            }
            return .concat([
                .just(.setChatReactor(chatReactor)),
                .just(.setChatReactor(nil))
            ])
        case .registerSocket:
            return socketManager.didReceiveMessage
                .observe(on: MainScheduler.instance)
                .distinctUntilChanged({$0.1})
                .flatMap {[weak self] ws ,text -> Observable<Mutation> in
                    guard let self, let data = text.data(using: .utf8) else {return .empty()}
                    let jsonDecoder = JSONDecoder()
                    if let refresh = try? jsonDecoder.decode(JSONData.self, from: data) ,
                       case let .object(r) = refresh, case let .string(type) = r["type"], type == "alba_room_refresh" {
                        return self.mutate(action: .refresh)
                    }
                    if let removed = try? jsonDecoder.decode(RemoveChat.self, from: data){
                        var rooms = self.currentState.rooms
                        guard let roomIndex = rooms.firstIndex(where: {
                            return $0.lastMessage.messageId == removed.removedId
                        }),var room  = rooms[safe: roomIndex] else { return .empty()}
                        room.lastMessage.content = "삭제된 메세지입니다."
                        rooms[roomIndex] = room
                        return .just(.setRooms(rooms))
                    }
                    if let chat = try? jsonDecoder.decode(Chat.self, from: data){
                        var currentRooms = self.currentState.rooms
                        if let roomIndex = currentRooms.firstIndex(where: { item in
                            item.id == chat.roomId
                        }){
                            if chat.block == true{
                                return .empty()
                            }
                            if chat.type == "chat" || chat.type == "image" {
                                var removed = currentRooms.remove(at: roomIndex)
                                removed.lastMessage = .init(content: chat.content,date: chat.createdAt, messageId: chat.id, containMention: (chat.mention?.userId == user!.id) || removed.lastMessage.containMention)
                                if chat.userId != user!.id{
                                    removed.unreadCount += 1
                                }
                                currentRooms.insert(removed, at: 0)
                            }
                            else if chat.type == "withdrawal" {
                                if chat.userId == user!.id{
                                    currentRooms.removeAll(where: {
                                        return $0.id == chat.roomId
                                    })
                                }
                                else{
                                    currentRooms[roomIndex].partnerOut = true
                                }
                            }
                            return .concat([
                                .just(.setRooms(currentRooms)),
                                .just(.setBagedCount(currentRooms.reduce(0, {$0 + $1.unreadCount})))
                            ])
                        }
                        else{
                            return self.mutate(action: .refresh)
                        }
                    }
                    return .empty()
                }
        case .registerSocketConnect:
            return socketManager.didConnect
                .asObservable()
                .flatMap {[weak self] _ -> Observable<Mutation> in
                    return self?.mutate(action: .refresh) ?? .empty()
                }
        case .unreadCountToZero(roomId: let roomId):
            let rooms = currentState.rooms.map({ room in
                var newRoom = room
                if room.id == roomId {
                    newRoom.unreadCount = 0
                    newRoom.lastMessage.containMention = false
                }
                return newRoom
            })
            return .concat([
                .just(.setRooms(rooms)),
                .just(.setBagedCount(rooms.reduce(0, {$0 + $1.unreadCount})))
            ])
            
            
        case .notificationSwitch(let indexPath):
            var room = currentState.rooms[indexPath.row]
            return changeNotificationStatus(roomId: room.id, isOn: !room.notificationStatus)
                .flatMap {[weak self] _ -> Observable<Mutation> in
                    guard let self = self else {return .empty()}
                    room.notificationStatus = !room.notificationStatus
                    var newRooms = self.currentState.rooms
                    newRooms[indexPath.row] = room
                    return .just(.setRooms(newRooms))
                        .delay(.milliseconds(400), scheduler: ConcurrentDispatchQueueScheduler.init(qos: .default))
                }
        case .updateRoom(let room):
            if let index = currentState.rooms.firstIndex(where: { result in
                return result.id == room.id
            }) {
                var newRoom = currentState.rooms
                newRoom[index] = room
                return .just(.setRooms(newRoom))
            }
            return .empty()
        }
    }
    
    func changeNotificationStatus(roomId: String,isOn: Bool) -> Observable<Void> {
        chatProvider.rx.request(.notificationStatus(userId: user.id, roomId: roomId, isOn: isOn))
            .map({_ in Void()})
            .asObservable()
//            .debug()
    }
    
}
