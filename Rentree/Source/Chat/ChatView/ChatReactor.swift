//
//  ChatReactor.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//
import Starscream
import ReactorKit
import Moya
import RxCocoa
import RxDataSources

class ChatReactor: Reactor {
    static let PagingCount = 50
    deinit {
        print("<ChatReactor> deinit")
    }
    struct Scroll: Equatable{
        var indexPath: IndexPath
        var position: UITableView.ScrollPosition
        var animated: Bool
        var shake: Bool
    }
    var userId = user.id
    let dateConverter = ChatDateConverter()
    var initialState: State
    let socketManager: SocketManager
    let provider: MoyaProvider<ChatAPI>
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()
    init(socketManager: SocketManager,provider: MoyaProvider<ChatAPI>,room: any RoomType) {
        self.initialState = .init(roomId: room.id,room: room)
        self.socketManager = socketManager
        self.provider = provider
    }
    struct State{
        let roomId: String
        var messages: [ChatType] = []
        var modifiedRoom: ModifiedRoom?
        var addContentOffset:CGFloat?
        var isPagingLoading:Bool = false
        var room: (any RoomType)?
        var loadingMessages: [Chat] = []
        var failMessages: [Chat] = []
//        var announcement: Announcement?
//        var applicant: HRApplication?
        var uidSet: Set<String> = Set<String>()
        /// 이거슨 nil 일 경우엔 안보이게, nil 이 아닌 경우엔 textView 위에 표시해 주면 된다.
        var lastestChat:Chat?
        var scrollTo: IndexPath?
        var isOldPagingAble: Bool = true
        var isRecentPagingAble: Bool = true
//        var lastVisibleIndexPath: IndexPath?
//        var presentRoomInformation: Bool = false
//        var roomInformation: RoomInformation?
//        var announcementDetailReactor: AnnouncementDetailReactor?
        var popToRootView = false
        var addedChatSize: CGFloat?
        var isWithdrawal: Bool = false
//        var alert: APIError?
        var isBlocked: Bool = false
        var tampShows: [Show] = []
//        var openParticipantView: Bool = false
        var mention: Chat.Mention?
        var scroll: Scroll?
//        var announcementDetail: BaseAnnouncement?
//        var openDelegationHostView: Bool = false
    }
    enum SendType{
        case string(String)
        case image(Data)
        case stringData(Data)
    }
    enum Action{
        case imageAdded(Data)
        case updateRoom(RoomListItem)
//        case updateLocalRoom(LocalRoomItem)
        case viewDidAppear
        case blockUser(targetId: String)
        case unblockUser(targetId: String)
        case refresh(lastest: Bool)
        case registerSocket
        case registerSocketConnect
        case sendButtonClicked(String)
        case didDisplayCell(IndexPath)
        case retryButtonClicked(Chat)
        case removeButtonClicked(Chat)
//        case showedCell(IndexPath)
        case sideMenuOpen
        case changeNotificationStatus(isOn: Bool)
        case withdrawalRoom
        
        case scrollToBottomClicked
        
//        case hrBlock
//        case hrReport
        
        case mention(chatId: String?)
        case mentionClicked(messageId: String)
        case removeMessage(messageId: String)
        
        case forceWithdrawal(targetId: String)
    }
    enum Mutation{
        
        case setMessages([ChatType])
        case setLastestCell(Chat?)
        case setAddedChatSize(CGFloat?)
        case setIsPagingLoading(Bool)
        case setWithdrawal(Bool)
        case setMention(Chat.Mention?)
//        case setLastIndexPath(IndexPath)
//        case setRecentLastId(String)
        case setScrollTo(IndexPath?)
        case setScroll(Scroll?)
        case setAddContentOffset(CGFloat?)
        case setOldPagingAble(Bool)
        case setRecentPagingAble(Bool)
        case setRoom((any RoomType)?)
        case popToRootView
        case setfailMessages([Chat])
        case setLoadingMessages([Chat])
        case setMessageTypes(fail:[Chat],loading:[Chat],messages:[ChatType])
        case setTampShowed([Show])
        case setBlocked(Bool)
        
        case setUid(Set<String>)
        case setModifiedRoom(ModifiedRoom?)
       
    }
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation{
        case .setMessages(let messages):
            newState.messages = messages
        case .setScrollTo(let indexPath):
            newState.scrollTo = indexPath
        case .setLastestCell(let chat):
            newState.lastestChat = chat
        case .setTampShowed(let shows):
            newState.tampShows = shows
//        case .setRecentLastId(let id):
//            newState.recentLastId = id
//        case .setLastIndexPath(let indexPath):
//            newState.lastVisibleIndexPath = indexPath
        case .setAddContentOffset(let v):
            newState.addContentOffset = v
        case .setOldPagingAble(let able):
            newState.isOldPagingAble = able
        case .setRecentPagingAble(let able):
            newState.isRecentPagingAble = able
//        case .setLoadingMessages(let times):
//            newState.loadingMessages = times
        case .setRoom(let room):
            newState.room = room
        case .popToRootView:
            newState.popToRootView = true
        case .setfailMessages(let messages):
            newState.failMessages = messages
        case .setLoadingMessages(let messages):
            newState.loadingMessages = messages
        case .setMessageTypes(fail: let fail, loading: let loading, messages: let messages):
            newState.failMessages = fail
            newState.loadingMessages = loading
            newState.messages = messages
        case .setAddedChatSize(let size):
            newState.addedChatSize = size
        case .setIsPagingLoading(let loading):
            newState.isPagingLoading = loading
        case .setWithdrawal(let withdrawal):
            newState.isWithdrawal = withdrawal
//        case .setAnnouncement(let announcement):
//            newState.announcement = announcement
//        case .setApplicant(let applicant):
//            newState.applicant = applicant
        case .setBlocked(let isBlock):
            newState.isBlocked = isBlock
        case .setMention(let mention):
            newState.mention = mention
        case .setScroll(let scroll):
            newState.scroll = scroll
        case .setUid(let uids):
            newState.uidSet = uids
        case .setModifiedRoom(let room):
            newState.modifiedRoom = room
        }
        return newState
    }
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .sendButtonClicked(let str):
            if str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .empty()
            }
            let uid = UUID().uuidString
            let mention: Chat.Mention? = currentState.mention
            if currentState.isRecentPagingAble {
                return getLastestMessages().flatMap {[weak self] messages -> Observable<Mutation> in
                    guard let self else {return .empty()}
                    var loadingChat = self.makeLoadingItem(str, uid: uid)
                    loadingChat.mention = currentState.mention
                    return .concat([
                        .just(.setMention(nil)),
                        .just(.setLastestCell(nil)),
                        .just(.setRecentPagingAble(false)),
                        .just(.setMessageTypes(fail: self.currentState.failMessages, loading: [loadingChat], messages: self.mappingModel(messages))),
                        .just(.setScrollTo(IndexPath(row: 0, section: 2))),
                        .just(.setScrollTo(nil)).do(afterNext: { _ in
                            guard let data = self.textToSender(str, uid: uid, mentionChat: mention) else {return}
                            self.socketManager.socket.write(string: String(data: data, encoding: .utf8)!)
                        }),
                        .just(.setOldPagingAble(messages.count == ChatReactor.PagingCount)),
                    ]).subscribe(on: MainScheduler.instance)
                }
            }
            else{
                
                if let data = textToSender(str, uid: uid, mentionChat: mention) {
                    socketManager.socket.write(string: String(data: data, encoding: .utf8)!)
                }
                var loadingMessage = makeLoadingItem(str, uid: uid)
                loadingMessage.mention = currentState.mention
                return .concat([
                    .just(.setMention(nil)),
                    .just(.setLoadingMessages([loadingMessage] + currentState.loadingMessages)),
                    .just(.setScrollTo(IndexPath(row: 0, section: 1))),
                    .just(.setScrollTo(nil)),
                    Observable<Void>.just(Void())
                        .delay(.seconds(30), scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
                        .flatMap({[weak self] _ -> Observable<Mutation> in
                            guard let self else {return .empty()}
                            var loadingMessages = self.currentState.loadingMessages
                            if let index = loadingMessages.firstIndex(of: loadingMessage) {
                                let failMessages = [loadingMessages[index]] + self.currentState.failMessages
                                loadingMessages.remove(at: index)
                                return .just(.setMessageTypes(fail: failMessages, loading: loadingMessages, messages: self.currentState.messages))
                            }
                            return .empty()
                        })
                ]).subscribe(on: MainScheduler.instance)
            }
            
        
        case .refresh(lastest: let lastest):
            if lastest{
                return getLastestMessages()
                    .flatMap {[weak self] messages -> Observable<Mutation> in
                    guard let self = self else {return .empty()}
                    let models = self.mappingModel(messages)
                    return .concat([
                        .just(.setMessages(models)),
                        .just(.setRecentPagingAble(false)),
                        .just(.setOldPagingAble(messages.count == ChatReactor.PagingCount))
                    ])
                }
            }
            let newMessageMutation = getMassages()
                .flatMap({[weak self] messages -> Observable<Mutation> in
                guard let self = self else {return .empty()}
                if messages.new.isEmpty{
                    var models = self.mappingModel(messages.old)
                    if let date = messages.old.last?.createdAt{
                        let currentDateFormatted = dateConverter.getDatePretty(formattedString: date, formatType: .day)
                        models.append(.date(currentDateFormatted))
                    }
                    return .concat([
                        .just(.setMessages(models)),
                        .just(.setRecentPagingAble(false)),
                        .just(.setOldPagingAble(messages.old.count == ChatReactor.PagingCount))
                    ])
                }
                else{
                    var unread: [ChatType] = []
                    if !messages.old.isEmpty{
                        unread.append(.unread)
                    }
                    var models = self.mappingModel(messages.new) + unread + self.mappingModel(messages.old)
                    if let date = messages.old.last?.createdAt{
                        let currentDateFormatted = dateConverter.getDatePretty(formattedString: date, formatType: .day)
                        models.append(.date(currentDateFormatted))
                    }
                    var mutations:[Observable<Mutation>] = []
                    mutations.append(.just(.setRecentPagingAble(messages.new.count == ChatReactor.PagingCount)))
                    mutations.append(.just(.setOldPagingAble(messages.old.count == ChatReactor.PagingCount)))
                    mutations.append(.just(.setMessages(models)))
                    mutations.append(.just(.setScrollTo(IndexPath(row: messages.new.count - 1, section: 2))))
                    mutations.append(.just(.setScrollTo(nil)))
                    if messages.new.count > 20 {
                        mutations.append(.just(.setLastestCell(messages.new.first)))
                    }
                    return .concat(mutations)
                        .subscribe(on: MainScheduler.instance)
                }
            })
            return newMessageMutation
        case .mentionClicked(let messageId):
            if let index = currentState.messages.firstIndex(where: {$0.identity == messageId}) {
                let scroll = Scroll(indexPath: IndexPath(row: index, section: 2),
                                    position: .middle,
                                    animated: false,
                                    shake: true)
                return .concat([
                    .just(.setScroll(scroll)),
                    .just(.setScroll(nil))
                ])
            }
            return getMessages(with: messageId)
                .flatMap({[weak self] messages -> Observable<Mutation> in
                    guard let self,!messages.new.isEmpty else {return .empty()}
                    var unread: [ChatType] = []
                    if !messages.old.isEmpty{
                        unread.append(.unread)
                    }
                    let new = self.mappingModel(messages.new)
                    let old = self.mappingModel(messages.old)
                    
                    var models = new + old
                    if let date = messages.old.last?.createdAt{
                        let currentDateFormatted = dateConverter.getDatePretty(formattedString: date, formatType: .day)
                        models.append(.date(currentDateFormatted))
                    }
                    var mutations:[Observable<Mutation>] = []
                    mutations.append(.just(.setRecentPagingAble(messages.new.count == ChatReactor.PagingCount)))
                    mutations.append(.just(.setOldPagingAble(messages.old.count == ChatReactor.PagingCount)))
                    mutations.append(.just(.setMessages(models)))
                    if let row = old.firstIndex(where: {$0.identity == messageId}) {
                        let scroll = Scroll(indexPath: IndexPath(row: (new.count) + row, section: 2),
                                            position: .middle,
                                            animated: false,
                                            shake: true)
                        mutations.append(.just(.setScroll(scroll)))
                        mutations.append(.just(.setScroll(nil)))
                    }
                    
                    return .concat(mutations)
                        .subscribe(on: MainScheduler.instance)
                })
        case .registerSocket:
            return socketManager
                .didReceiveMessage
                .buffer(timeSpan: .milliseconds(300), count: 30, scheduler: ConcurrentDispatchQueueScheduler.init(qos: .userInteractive))
                .filter({!$0.isEmpty})
                .flatMap({[weak self] jsons -> Observable<Mutation> in
                    guard let self, !jsons.isEmpty else {return .empty()}
//                    var newModifiedRoom = self.currentState.modifiedRoom
                    var newMessages = self.currentState.messages
                    var newLoadingMessages = self.currentState.loadingMessages
                    var newShows = self.currentState.tampShows
                    var addContentOffset: CGFloat = 0.0
                    var mutation: [Observable<Mutation>] = []
                    var uidSets = self.currentState.uidSet
                    if uidSets.count > 30 {
                        uidSets = .init()
                    }
//                    let isLocalRoom = (self.currentState.room as? RoomListItem)?.type.hasPrefix("S") == true ||
//                    (self.currentState.room as? RoomListItem)?.type.hasPrefix("D") == true
                    jsons.forEach({ ws, json in
                        guard let data = json.data(using: .utf8) else { return }
                        
                        if let modifiedRoom = try? self.jsonDecoder.decode(ModifiedRoom.self, from: data) {
                            if modifiedRoom.roomId == self.currentState.roomId{
                                mutation.append(.just(.setModifiedRoom(modifiedRoom)))
                                mutation.append(.just(.setModifiedRoom(nil)))
                            }
                            return
                        }
//                        if let block = try? self.jsonDecoder.decode(HRBlock.self, from: data) {
//                            if user == nil, block.targetId == self.currentState.applicant?.userId{
//                                mutation.append(.just(.setAlert(APIError.hrUserOut)))
//                                mutation.append(.just(.setAlert(nil)))
//                            }
//                            else if block.targetId == self.currentState.announcement?.managerId{
//                                mutation.append(.just(.setAlert(APIError.hrManagerOut)))
//                                mutation.append(.just(.setAlert(nil)))
//                            }
//                            return
//                        }
                        if let removed = try? self.jsonDecoder.decode(RemoveChat.self, from: data),
                           removed.roomId == self.currentState.roomId {
                            guard let messageIndex = newMessages.firstIndex(where: {$0.identity == removed.removedId}),
                                  var message = newMessages[messageIndex].getChat() else { return }
                            message.removed = true
                            if message.userId == self.userId {
                                newMessages[messageIndex] = .sent(message)
                            }
                            else{
                                newMessages[messageIndex] = .received(message)
                            }
                            return
                        }
                        guard var chat = try? self.jsonDecoder.decode(Chat.self, from: data), chat.roomId == self.currentState.roomId else { return }
                        switch chat.type {
                        case "notice":
                            newMessages.insert(.notice(chat), at: 0)
                        case "chat","image":
                            guard !uidSets.contains(chat.uid) else {
                                return
                            }
                            uidSets.insert(chat.uid)
                            if chat.userId == self.userId{
                                newLoadingMessages.removeAll(where: {$0.uid == chat.uid})
                                if case .sent = newMessages.first{
                                    chat.isFirst = false
                                }
                                else{
                                    chat.isFirst = true
                                }
                                newMessages.insert(.sent(chat), at: 0)
                            }
                            else{
                                let sender = [
                                    "type": "show2",
                                    "roomId": self.currentState.roomId,
                                    "messageId": chat.id
                                ]
                                if let sender = try? self.jsonEncoder.encode(sender) {
                                    self.socketManager.socket.write(string: String(data: sender, encoding: .utf8)!)
                                }
                                if chat.block == true {
                                    return
                                }
                                chat.isFirst = true
                                if case let .received(rChat) = newMessages.first{
                                    if chat.userId == rChat.userId {
                                        chat.isFirst = false
                                    }
                                }
                                if let show = newShows.filter({$0.showedId == chat.id}).min(by: {($0.unreadCount ?? 0) < ($1.unreadCount ?? 0)}) {
                                    chat.unreadCount = min(show.unreadCount ?? 0, chat.unreadCount)
                                    newShows.removeAll(where: {$0.showedId == chat.id})
                                }
                                let contentOffset = RecivedCell.calculatingCellHeight(chat)
                                addContentOffset += contentOffset
                                newMessages.insert(.received(chat), at: 0)
                                mutation.append(.just(.setLastestCell(chat)))
                            }
                        case "withdrawal":
                            chat.content = chat.name + " 님이 퇴장하셨습니다."
                            newMessages.insert(.notice(chat), at: 0)
                        case "participate":
                            chat.content = chat.name + " 님이 입장하셨습니다."
                            newMessages.insert(.notice(chat), at: 0)
                            
                        case "delegatingHost":
                            chat.content = chat.name + " 님이 방장이 되었습니다."
                            newMessages.insert(.notice(chat), at: 0)
                        default:
                            return
                        }
                    })
                    
                   
                    jsons.forEach({ ws, json in
                        guard let data = json.data(using: .utf8) else { return }
                        guard let show = try? self.jsonDecoder.decode(Show.self, from: data),show.roomId == self.currentState.roomId else { return }
                        if let showedId = show.showedId {
                            if let index = newMessages.firstIndex(where: {$0.identity == showedId}) {
                                switch newMessages[index] {
                                case .sent(var sent):
                                    sent.unreadCount = min(show.unreadCount ?? 0, sent.unreadCount)
                                    newMessages[index] = .sent(sent)
                                case .received(var received):
                                    received.unreadCount = min(show.unreadCount ?? 0, received.unreadCount)
                                    newMessages[index] = .received(received)
                                default:
                                    break
                                }
                            }
                            else{
                                newShows.append(show)
                            }
                        }
                        else if let lastId = show.oldLastId {
                            newMessages = newMessages.map({ chatType in
                                switch chatType{
                                case .sent(let chat):
                                    if chat.id > lastId{
                                        var newChat = chat
                                        newChat.unreadCount -= 1
                                        return ChatType.sent(newChat)
                                    }
                                case .received(let chat):
                                    if let lastId = show.oldLastId, chat.id > lastId{
                                        var newChat = chat
                                        newChat.unreadCount -= 1
                                        return ChatType.received(newChat)
                                    }
                                default:
                                    break
                                }
                                return chatType
                            })
                        }
                    })
                    mutation.append(.just(.setMessages(newMessages)))
                    mutation.append(.just(.setLoadingMessages(newLoadingMessages)))
                    if addContentOffset != 0{
                        mutation.append(.just(.setAddedChatSize(addContentOffset)))
                        mutation.append(.just(.setAddedChatSize(nil)))
                    }
                    mutation.append(.just(.setTampShowed(newShows)))
                    mutation.append(.just(.setUid(uidSets)))
                    return .concat(mutation).subscribe(on: MainScheduler.instance)
                })
            
        case .didDisplayCell(let indexPath):
            if !currentState.isRecentPagingAble{
                if indexPath.section == 2 && indexPath.row <= 5{
                    return .just(.setLastestCell(nil))
                }
            }
            if indexPath.row >= currentState.messages.count - 5 && currentState.isOldPagingAble && !currentState.isPagingLoading{
                guard let last = currentState.messages.last(where: { chatType in
                    if case .date = chatType{
                        return false
                    }
                    if case .loading = chatType{
                        return false
                    }
                    return true
                }) else {return .empty()}
                if let firstId = getModelId(chatType: last) {
                    return .just(.setIsPagingLoading(true))
                        .concat(
                            getOldMessages(oldId: firstId)
                                .flatMap {[weak self] chats -> Observable<Mutation> in
                                    guard let self = self else {return .empty()}
                                    let chatTypes = self.mappingModel(chats)
                                    var currentMessages = self.currentState.messages
                                    if case .date = currentMessages.last {
                                        currentMessages.removeLast()
                                    }
                                    switch currentMessages.last{
                                    case .sent(var lastChat):
                                        if case .sent = chatTypes.last{
                                            lastChat.isFirst = false
                                            currentMessages[currentMessages.count - 1] = .sent(lastChat)
                                        }
                                    case .received(var lastChat):
                                        if case let .received(firstChat) = chatTypes.last{
                                            if lastChat.userId == firstChat.userId {
                                                lastChat.isFirst = false
                                                currentMessages[currentMessages.count - 1] = .received(lastChat)
                                            }
                                        }
                                    default:
                                        break
                                    }
                                    return .concat([
                                        .just(.setOldPagingAble(chats.count == ChatReactor.PagingCount)),
                                        .just(.setMessages(currentMessages + chatTypes)),
                                        .just(.setIsPagingLoading(false))
                                    ])
                                }
                        )
                }
            }
            else if indexPath.row <= 5 && currentState.isRecentPagingAble && !currentState.isPagingLoading{
                guard let first = currentState.messages.first(where: {getModelId(chatType: $0) != nil}) else {return .empty()}
                if let firstId = getModelId(chatType: first) {
                    return .just(.setIsPagingLoading(true))
                        .concat(getRecentMessages(recentId: firstId)
                            .observe(on: MainScheduler.instance)
                            .flatMap {[weak self] chats -> Observable<Mutation> in
                                guard let self = self else {return .empty()}
                                let chatTypes = self.mappingModel(chats)
                                let addHeight = chatTypes.reduce(0) { partialResult, type -> CGFloat in
                                    switch type{
                                    case .sent(let chat):
                                        return SentCell.calculatingCellHeight(chat) + partialResult
                                    case .received(let chat):
                                        return RecivedCell.calculatingCellHeight(chat) + partialResult
                                    case .unread:
                                        return partialResult + 44
                                    case .notice:
                                        return partialResult + 44
                                    case .loading(let chat, fail: _):
                                        return SentCell.calculatingCellHeight(chat) + partialResult
                                    default:
                                        return partialResult + 44
                                    }
                                }
                                let newChats = chatTypes + self.currentState.messages
                                return .concat([
                                    .just(.setMessages(newChats)),
                                    .just(.setAddContentOffset(addHeight)),
                                    .just(.setAddContentOffset(nil)),
                                    .just(.setRecentPagingAble(chats.count == ChatReactor.PagingCount)),
                                    .just(.setIsPagingLoading(false))
                                ]).subscribe(on: MainScheduler.instance)
                            })
                }
            }
            return .empty()
//        case .showedCell(let indexPath):
//            if let id = currentState.messages[safe: indexPath.row]?.identity,
//               id > currentState.recentLastId{
//                return .just(.setRecentLastId(id))
//            }
//            else{
//                return .empty()
//            }
        case .sideMenuOpen:
            return .empty()
        case .registerSocketConnect:
            return socketManager.didConnect
                .subscribe(on: MainScheduler.asyncInstance)
                .flatMap({ [weak self] _ -> Observable<ChatTypes> in
                    guard let self = self else {return .empty()}
                    if self.currentState.isRecentPagingAble{
                        // 스크롤 냅두기 v1/message/show 요청
                        // (마지막 채팅)리턴 받고 방에 들어와있는 애들한테 show 보내고
                    }
                    else{
                        // 무조건 v1/message
                        //  -> new == 50 isRecentPagingAble = true , 여기까지 읽었습니다가 가운데 오게
                        // -> 10 < new < 50 isRecentPagingAble = false , 여기까지 읽었습니다가 가운데
                        // -> new =< 10 isRecentPagingAble, 여기까지 읽었습니다 없애기.
                        
                    }
                    if self.currentState.isRecentPagingAble{
                        return self.getRecentMessage()
                            .map { chat in
                                return .init(chats: nil, newCount: 50,recentChat: chat)
                            }
                    }
                    else if self.currentState.loadingMessages.isEmpty{
                        return self.getMassages()
                            .flatMap({ chats -> Observable<ChatTypes> in
                                if chats.new.isEmpty{
                                    return .empty()
                                }
                                if chats.new.count > 10{
                                    let newMessages = self.mappingModel(chats.new) + [.unread] + self.mappingModel(chats.old)
                                    return .just(.init(chats: newMessages, newCount: chats.new.count,recentChat: chats.new.first))
                                }
                                else{
                                    let newMessages = self.mappingModel(chats.new) + self.mappingModel(chats.old)
                                    return .just(.init(chats: newMessages, newCount: chats.new.count,recentChat: chats.new.first))
                                }
                            })
                    }
                    else{
                        return self.uploadMessages(loadingChat: self.currentState.loadingMessages)
                            .map { chats in
                                return .init(chats: self.mappingModel(chats), newCount: 0,recentChat: nil)
                            }
                    }
                })
                .flatMap {[weak self] newChats -> Observable<Mutation> in
                    guard let self else {return .empty()}
                    guard let newMessges = newChats.chats else {
                        guard let recentMessage = newChats.recentChat else {return .empty()}
                        return .just(.setLastestCell(recentMessage))
                    }
                    return .concat([
                        .just(.setRecentPagingAble(newChats.newCount == ChatReactor.PagingCount)),
                        .just(.setMessageTypes(fail: self.currentState.failMessages, loading: [], messages: newMessges)),
                        .just(.setScrollTo(IndexPath(row: newChats.newCount, section: 2))),
                        .just(.setScrollTo(nil)),
                    ]).subscribe(on: MainScheduler.instance)
                }
        case .retryButtonClicked(let chat):
            var newFailMessage = currentState.failMessages
            var newLoadingMessage = currentState.loadingMessages
            newFailMessage.removeAll(where: {$0.id == chat.id})
//            let uid = UUID().uuidString
            if let data = textToSender(chat.content, uid: chat.uid, mentionChat: chat.mention){
                socketManager.socket.write(stringData: data, completion: nil)
            }
            newLoadingMessage.insert(chat, at: 0)
            return .concat([
                .just(.setMessageTypes(fail: newFailMessage, loading: newLoadingMessage, messages: currentState.messages)),
                Observable<Chat>.just(chat)
                    .delay(.seconds(30), scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
                    .observe(on: MainScheduler.asyncInstance)
                    .flatMap({[weak self] chat -> Observable<Mutation> in
                        guard let self else {return .empty()}
                        if currentState.loadingMessages.contains(where: {$0.uid == chat.uid}) {
                            newFailMessage.insert(chat, at: 0)
                            newLoadingMessage.removeAll(where: {$0.id == chat.id})
                            return .just(.setMessageTypes(fail: newFailMessage, loading: newLoadingMessage, messages: self.currentState.messages))
                        }
                        return .empty()
                    })
            
            ])
        case .updateRoom(let newRoom):
            return .just(.setRoom(newRoom))
        case .changeNotificationStatus(isOn: let isOn):
            return changeNotificationStatus(isOn: isOn)
                .flatMap {[weak self] _  -> Observable<Mutation> in
                    guard let self,var newRoom = self.currentState.room else {return .empty()}
                    newRoom.notificationStatus = isOn
                    return .just(.setRoom(newRoom))
                }
        case .withdrawalRoom:
            return withdrawal()
                .flatMap({ _ -> Observable<Mutation> in
                    return .concat([
                        .just(.setWithdrawal(true)),
                        .just(.popToRootView)
                    ])
                })
        case .imageAdded(let data):
            let image = UIImage(data: data)!
            let uid = UUID().uuidString
            let loadingChat = Chat(id: "\(Date().timeIntervalSince1970)", userId: userId, name: user.name, createdAt: DateConverter.dateToString(date: Date()), content: "(사진)", type: "image", roomId: currentState.roomId, image: .init(url: "", height: image.size.height, width: image.size.width,data: data), unreadCount: 0, uid: uid, profileImage: user.profileImage ?? "", block: nil)
            if currentState.isRecentPagingAble{
                return getLastestMessages().flatMap {[weak self] messages -> Observable<Mutation> in
                    guard let self else {return .empty()}
                    return .concat([
                        .just(.setMention(nil)),
                        .just(.setRecentPagingAble(false)),
                        .just(.setMessages(self.mappingModel(messages))),
                        .just(.setLoadingMessages([loadingChat] + self.currentState.loadingMessages)),
                        .just(.setScrollTo(IndexPath(row: 0, section: 2))),
                        .just(.setScrollTo(nil)),
                        .just(.setOldPagingAble(messages.count == ChatReactor.PagingCount)),
                        self.uploadImage(data: data, imageHeight: image.size.height, imageWidth: image.size.width, uid: uid)
                            .flatMap({chat -> Observable<Mutation> in
                                var chat = chat
                                var loadingMessages = self.currentState.loadingMessages
                                loadingMessages.removeAll(where: {$0.id == loadingChat.id})
                                var currentMessages = self.currentState.messages
                                chat.image?.data = loadingChat.image?.data
                                currentMessages.insert(.sent(chat), at: 0)
                                return .just(.setMessageTypes(fail: self.currentState.failMessages, loading: loadingMessages, messages: currentMessages))
                            }).catch({ error in
                                var loadingMessages = self.currentState.loadingMessages
                                loadingMessages.removeAll(where: {$0.id == loadingChat.id})
                                var failMessages = self.currentState.failMessages
                                failMessages.insert(loadingChat, at: 0)
                                return .just(.setMessageTypes(fail: failMessages, loading: loadingMessages, messages: self.currentState.messages))
                            })
                    ]).subscribe(on: MainScheduler.instance)
                }
            }
            else{
                var messages = currentState.loadingMessages
                messages.insert(loadingChat, at: 0)
                return .concat([
                    .just(.setMention(nil)),
                    .just(.setLoadingMessages(messages)),
                    uploadImage(data: data, imageHeight: image.size.height, imageWidth: image.size.width, uid: uid)
                        .flatMap({[weak self] chat -> Observable<Mutation> in
                            guard let self else {return .empty()}
                            var chat = chat
                            chat.image?.data = loadingChat.image?.data
                            var currentMessages = self.currentState.messages
                            var loadingMessages = self.currentState.loadingMessages
                            loadingMessages.removeAll(where: {$0.id == loadingChat.id})
                            if let message = currentMessages.first{
                                if case .sent = message{
                                    chat.isFirst = false
                                }
                                else{
                                    chat.isFirst = true
                                }
                            }
                            else{
                                chat.isFirst = true
                            }
                            currentMessages.insert(.sent(chat), at: 0)
                            return .just(.setMessageTypes(fail: self.currentState.failMessages, loading: loadingMessages, messages: currentMessages))
                        })
                ])
            }
        case .removeButtonClicked(let chat):
            var failMessages = currentState.failMessages
            failMessages.removeAll(where: {$0.uid == chat.uid})
            return .just(.setfailMessages(failMessages))
        case .blockUser(targetId: let targetId):
            return blockUser(targetId: targetId)
                .flatMap({[weak self] _ -> Observable<Mutation> in
                    guard let self = self else {return .empty()}
                    return self.mutate(action: .refresh(lastest: false))
                })
        case .unblockUser(targetId: let targetId):
            return unblockUser(targetId: targetId)
                .flatMap({[weak self] _ -> Observable<Mutation> in
                    guard let self = self else {return .empty()}
                    return self.mutate(action: .refresh(lastest: false))
                })
        case .scrollToBottomClicked:
            if currentState.isRecentPagingAble {
                return getLastestMessages().flatMap {[weak self] messages -> Observable<Mutation> in
                    guard let self else {return .empty()}
                    return .concat([
                        .just(.setRecentPagingAble(false)),
                        .just(.setMessages(self.mappingModel(messages))),
                        .just(.setScrollTo(IndexPath(row: 0, section: 2))),
                        .just(.setScrollTo(nil)),
                        .just(.setOldPagingAble(messages.count == ChatReactor.PagingCount)),
                    ])
                    .subscribe(on: MainScheduler.instance)
                }
            }
            else{
                return .concat([
                    .just(.setScrollTo(IndexPath(row: 0, section: 2))),
                    .just(.setScrollTo(nil))
                ]).subscribe(on: MainScheduler.instance)
            }
      
        case .viewDidAppear:
            
            return .empty()
    
        case .mention(chatId: let chatId):
            guard let chatId else {return .just(.setMention(nil))}
            guard let message = currentState.messages.first(where: {$0.identity == chatId})?.getChat() else {return .empty()}
            let mention = Chat.Mention(content: message.image != nil ? "사진" : message.content,
                                       messageId:  message.id,
                                       name: message.name,
                                       userId: message.userId,
                                       image: message.image?.url
            )
            
            return .concat([
                .just(.setMention(nil)),
                .just(.setMention(mention))
            ])
        case .removeMessage(messageId: let messageId):
            return removeMessage(messageId: messageId)
                .observe(on: MainScheduler.instance)
                .flatMap({[weak self] _ -> Observable<Mutation> in
                    guard let self else {return .empty()}
                    var messages = self.currentState.messages
                    guard let index = messages.firstIndex(where: {$0.identity == messageId}),
                          case var .sent(message) = messages[index] else {return .empty()}
                    message.removed = true
                    messages[index] = .sent(message)
                    return .just(.setMessages(messages))
                })
        case .forceWithdrawal(targetId: let targetId):
            return  provider.rx.request(.forcingToWithdrawal(userId: userId,targetId: targetId, roomId: currentState.roomId))
                .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
                .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
                .asObservable()
                .flatMap({ response -> Observable<Mutation> in
                    if response.statusCode == 403 {
                        return .concat([
//                            .just(.setAlert(.alreadyForceWithdrawal)),
//                            .just(.setAlert(nil))
                        ])
                    }
                    return .empty()
                })
           
        }
    }
    struct MessageSender: Codable{
        let userId: String
        let roomId: String
        let content: String
        let uid: String
        let type: String
        var hrOption: String?
        var mention: Chat.Mention?
    }
    func textToSender(_ str: String,uid: String, mentionChat: Chat.Mention?) -> Data?{
        var chat = MessageSender(userId: userId, roomId: currentState.roomId, content: str, uid: uid, type: "chat")
        if let mentionChat {
            chat.mention = mentionChat
        }
        let data = try? jsonEncoder.encode(chat)
        return data
    }
    func makeLoadingItem(_ str: String,uid: String) -> Chat{
        let date = DateConverter.dateToString(date: Date())
        let messages = currentState.messages
        let refrenceDate = Date().timeIntervalSince1970
        var isFirst = true
        if case .loading =  messages.first{
            isFirst = false
        }
        if case .sent = messages.first{
            isFirst = false
        }
        let loadingChat = Chat(isFirst: isFirst, id: "\(refrenceDate)", userId: userId, name: user.name, createdAt: date, content: str, type: "chat", roomId: currentState.roomId, image: nil, unreadCount: 0, uid: uid, profileImage: user.profileImage, block: nil)
        return loadingChat
    }
    func mappingModel(_ messages: [Chat]) -> [ChatType]{
        
        return messages.enumerated().flatMap { index, message in
//            if message.uid == "secondNotice", user != nil {
//                return [ChatType].init()
//            }
            
            let lastDate = messages[safe: index + 1]?.createdAt
            let currentDateFormatted = dateConverter.getDatePretty(formattedString: message.createdAt, formatType: .day)
            let isOtherDay = lastDate == nil ? false : dateConverter.getDatePretty(formattedString: lastDate!, formatType: .day) != currentDateFormatted
            var chatTypes:[ChatType] = []
            var newMessage = message
           
            if message.type == "withdrawal" || message.type == "notice" || message.type == "participate" || message.type == "delegatingHost" {
                if message.type == "participate" {
                    newMessage.content = (message.name) + " 님이 입장하셨습니다."
                }
                if message.type == "withdrawal" {
                   
                    newMessage.content = (message.name) + " 님이 퇴장하셨습니다."
                }
                if message.type == "delegatingHost" {
                    newMessage.content = (newMessage.name) + " 님이 방장이 되었습니다."
                }
               
                chatTypes.append(.notice(newMessage))
//                if message.uid == "firstNotice"{
//                    if  user != nil {
//                        chatTypes.append(.announcement(currentState.announcement))
//                    }
//                    else {
//                        if let applicant = currentState.applicant{
//                            chatTypes.append(.applicant(applicant))
//                        }
//                        chatTypes.append(.announcement(currentState.announcement))
//                    }
//                }
                if isOtherDay {
                    chatTypes.append(.date(currentDateFormatted))
                }
                return chatTypes
            }
            if message.userId == userId {
                if index == messages.count - 1 || messages[index + 1].type != "chat" || messages[index + 1].userId != message.userId || isOtherDay{
                    newMessage.isFirst = true
                }
                else{
                    newMessage.isFirst = false
                }
                chatTypes.append(.sent(newMessage))
            }
            else{
                if index == messages.count - 1 || messages[index + 1].type != "chat" || messages[index + 1].userId != message.userId || isOtherDay{
                    if messages[safe: index + 1]?.uid == "secondNotice" && messages[safe: index + 2]?.userId == message.userId {
                        newMessage.isFirst = false
                    }
                    else{
                        newMessage.isFirst = true
                    }
                }
                else{
                    newMessage.isFirst = false
                }
                chatTypes.append(.received(newMessage))
            }
            if isOtherDay{
                chatTypes.append(.date(currentDateFormatted))
            }
            return chatTypes
        }
    }
    func getMassages() -> Observable<ChatSeperated>{
        provider.rx.request(.getMessageList(userId: userId, roomId: currentState.roomId))
            .map(ChatSeperated.self)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .asObservable()
    }
    func getMessages(with messageId: String) -> Observable<ChatSeperated>{
        provider.rx.request(.getMiddleMessage(userId: userId, roomId: currentState.roomId, messageId: messageId))
            .map(ChatSeperated.self)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .asObservable()
    }
   
//    func getAnnouncementWithApplicant() -> Observable<AnnouncementWithApplicant> {
//        guard let room = currentState.room as? HRRoom else {return .empty()}
//        return hrProvider.rx.request(.getChatAnnouncementWithApplicant(applicantId: room.applicantId))
//            .map(AnnouncementWithApplicant.self)
//            .asObservable()
//    }
    func getOldMessages(oldId: String) -> Observable<[Chat]> {
        provider.rx.request(.getOldMessages(userId: userId, roomId: currentState.roomId, oldId: oldId))
            .map([Chat].self)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .asObservable()
//            .debug()
    }
    
    func getRecentMessages(recentId: String) -> Observable<[Chat]> {
        provider.rx.request(.getRecentMessages(userId: userId, roomId: currentState.roomId, recentId: recentId))
            .map([Chat].self)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .asObservable()
//            .debug()
    }
    func getLastestMessages() -> Observable<[Chat]>{
        provider.rx.request(.getLastestMessageList(userId: userId,roomId: currentState.roomId))
            .map([Chat].self)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .asObservable()
    }
    
    func changeNotificationStatus(isOn: Bool) -> Observable<Void> {
        provider.rx.request(.notificationStatus(userId: userId, roomId: currentState.roomId, isOn: isOn))
            .map({_ in Void()})
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .asObservable()
    }
   
    func withdrawal() -> Observable<Void> {
        provider.rx.request(.withdrawal(userId: userId, roomId: currentState.roomId))
            .map({_ in Void()})
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .asObservable()
    }
    func uploadImage(data:Data,imageHeight:CGFloat,imageWidth: CGFloat,uid:String) -> Observable<Chat> {
        provider.rx.request(.sendImage(roomId: currentState.roomId, userId: userId, imageHeight: imageHeight, imageWidth: imageWidth, imageData: data, uid: uid))
            .map(Chat.self)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .asObservable()
    }
    func uploadMessages(loadingChat:[Chat]) -> Observable<[Chat]> {
        provider.rx.request(.sendMessages(roomId: currentState.roomId, userId: userId, contents: loadingChat.map({
            return .init(content: $0.content, uid: $0.uid)
        })))
        .map([Chat].self)
        .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
        .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
        .asObservable()
    }
    func getRecentMessage() -> Observable<Chat> {
        provider.rx.request(.getRecentMessage(userId: userId, roomId: currentState.roomId))
            .map(Chat.self)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .asObservable()
    }
//    func getRoomInformation() -> Observable<RoomInformation> {
//        provider.rx.request(.getRoomInformation(userId: userId, roomId: currentState.roomId))
//            .map(RoomInformation.self)
//            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
//            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
//            .asObservable()
//    }
    
//    func forceWithdrawal(targetId:String) -> Observable<Void> {
//
//    }
    
    func blockUser(targetId:String) -> Observable<Void> {
        provider.rx.request(.blockUser(roomId: currentState.roomId, userId: userId, targetId: targetId))
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .asObservable()
            .filter(statusCode: 200)
            .map({_ in Void()})
    }
    func unblockUser(targetId:String) -> Observable<Void> {
        provider.rx.request(.unblockUser(roomId: currentState.roomId, userId: userId, targetId: targetId))
//            .map([Chat].self)
            .debug("<차단 해제>")
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .asObservable()
            .filter(statusCode: 200)
            .map({_ in Void()})
    }
    func removeMessage(messageId: String) -> Observable<Void> {
        provider.rx.request(.removeMessage(roomId: currentState.roomId, messageId: messageId))
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .observe(on: ConcurrentDispatchQueueScheduler.init(qos: .default))
            .asObservable()
            .filter(statusCode: 200)
            .map({_ in Void()})
    }
    func getModelId(chatType:ChatType) -> String? {
        if case let .sent(chat) = chatType{
            return chat.id
        }
        else if case let .received(chat) = chatType{
            return chat.id
        }
        else if case let .notice(chat) = chatType{
            return chat.id
        }
        return nil
    }
    struct ChatTypes: Equatable{
        var chats: [ChatType]?
        var newCount:Int
        var recentChat: Chat?
    }
    
}
