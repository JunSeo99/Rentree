//
//  ViewController.swift
//  ChatAppTest
//
//  Created by 송준서 on 2023/02/20.
//
import Reusable
import UIKit
import ReactorKit
import RxCocoa
import RxDataSources
import RxKeyboard
import RxGesture
import PhotosUI
import SpriteKit
//import FirebaseAnalytics
import SnapKit

enum RoomInformationAction{
    case block(String)
    case unblock(String)
    case leave
    case notificationChanged(Bool)
}
class ChatView: UIViewController,
                StoryboardView,
                UITableViewDelegate {
    struct CellSizeCache: Equatable {
        var isFirst: Bool
        var isRemoved: Bool
        var height: CGFloat
    }
    
    deinit {
        print("<ChatView> deinit")
    }
    
//    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    var count = 0
    var inputViewHidden: Bool = false
    var inputView2: ChatAccessoryView! = ChatAccessoryView(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
//    lazy var autoAskingView = AutoAskingBarView()
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if let tableView = scrollView as? UITableView {
            if tableView.numberOfSections > 2 {
                let lastRow = tableView.numberOfRows(inSection: 2) - 1
                tableView.scrollToRow(at: IndexPath(row: lastRow, section: 2), at: .top, animated: true)
            }
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        print("111111111111")
        guard let reactor else { return 0 }
        if indexPath.section == 0 {
            guard let item = reactor.currentState.failMessages[safe: indexPath.row] else { return 0 }
            return SentCell.calculatingCellHeight(item)
        }
        else if indexPath.section == 1 {
            guard let item = reactor.currentState.loadingMessages[safe: indexPath.row] else { return 0 }
            return SentCell.calculatingCellHeight(item)
        }

        guard let item = reactor.currentState.messages[safe: indexPath.row] else { return 0 }
        switch item{
        case .sent(let chat):
            if let cache = cacheHeight[chat.id], cache.isFirst == chat.isFirst, cache.isRemoved == chat.removed {
                return cache.height
            }
            else{
                let height = SentCell.calculatingCellHeight(chat)
                cacheHeight[chat.id] = .init(isFirst: chat.isFirst ?? false, isRemoved: chat.removed ?? false, height: height)
                return height
            }
        case .received(let chat):
            if let cache = cacheHeight[chat.id], cache.isFirst == chat.isFirst, cache.isRemoved == chat.removed {
                return cache.height
            }
            else{
                let height = RecivedCell.calculatingCellHeight(chat)
                cacheHeight[chat.id] = .init(isFirst: chat.isFirst ?? false, isRemoved: chat.removed ?? false, height: height)
                return height
            }
        case .notice(let chat):
            if chat.uid == "firstNotice" && user != nil {
                return 64
            }
            return 44
        case .unread:
            return 44
        case .loading(let chat, fail: _):
            return SentCell.calculatingCellHeight(chat)
        default:
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let reactor else {return 0}
        return UITableView.automaticDimension
    }
    
    let sideBarButton = UIButton()
    
    typealias Reactor = ChatReactor
    
    typealias Model = SectionModel<Int, ChatType>
    @IBOutlet weak var tableView: UITableView!
    
    var disposeBag: DisposeBag = DisposeBag()
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        disposeBag = DisposeBag()
        print("<ChatView> disappeared")
//        disposeBag = DisposeBag()
//        reactor = nil
    }
    
    
    var lastestChatIsShowing = false
    var scrollToBottomIsShowing = false
    var cacheHeight:[String: CellSizeCache] = [:]
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let _ = reactor?.currentState.lastestChat, -tableView.contentOffset.y < tableView.contentInset.top{
            if !lastestChatIsShowing{
                lastestChatIsShowing = true
                lastestChatView.alpha = 0
                lastestChatView.isHidden = false
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: { [weak self] in
                    self?.lastestChatView.alpha = 1
                },completion: { [weak self] _ in
                    self?.lastestChatView.isHidden = false
                })
            }
        }
        else{
            if lastestChatIsShowing && reactor?.currentState.isRecentPagingAble == false{
                lastestChatIsShowing = false
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: { [weak self] in
                    self?.lastestChatView.alpha = 0
                }, completion: { [weak self] _ in
                    self?.lastestChatView.isHidden = true
                })
            }
        }
        if scrollView.contentOffset.y > 100{
            if !scrollToBottomIsShowing {
                scrollToBottomIsShowing = true
                scrollToBottomButton.transform = .init(scaleX: 0.3, y: 0.3)
                scrollToBottomButton.alpha = 0
                scrollToBottomButton.isHidden = false
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: { [weak self] in
                    self?.scrollToBottomButton.alpha = 1
                    self?.scrollToBottomButton.transform = .identity
                },completion: { [weak self] _ in
                    self?.scrollToBottomButton.isHidden = false
                })
            }
        }
        else{
//            if lastestChatIsShowing{
//                lastestChatIsShowing = false
//                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: { [weak self] in
//                    self?.lastestChatView.alpha = 0
//                }, completion: { [weak self] _ in
//                    self?.lastestChatView.isHidden = true
//                })
//            }
            if scrollToBottomIsShowing && reactor?.currentState.isRecentPagingAble == false{
                scrollToBottomIsShowing = false
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: { [weak self] in
                    self?.scrollToBottomButton.transform = .init(scaleX: 0.3, y: 0.3)
                    self?.scrollToBottomButton.alpha = 0
                }, completion: { [weak self] _ in
                    self?.scrollToBottomButton.isHidden = true
                    self?.scrollToBottomButton.transform = .identity
                })
                
            }
        }
    }
    
    
    func bind(reactor: ChatReactor) {
        
        reactor.action.onNext(.refresh(lastest: false))
        
        reactor.action.onNext(.registerSocket)
        
        reactor.action.onNext(.registerSocketConnect)
        
//        let isHR = (reactor.initialState.room as? HRRoom) != nil
//        let hiddenUnreadCount = (reactor.initialState.room as? LocalRoomItem)?.type.hasPrefix("S") == true || (reactor.initialState.room as? LocalRoomItem)?.type.hasPrefix("D") == true || reactor.initialState.roomId == "642e6dabff4cc09ccd7a6767"
//        let hiddenSchool = (reactor.initialState.room as? LocalRoomItem)?.type.hasPrefix("S") == true
        var mentionSetting: MessageMentionSetting?
//        tableView.rx.didEndDecelerating
////            .throttle(<#T##dueTime: RxTimeInterval##RxTimeInterval#>, scheduler: <#T##SchedulerType#>)
//            .subscribe(onNext: { _ in
//
//            }).disposed(by: disposeBag)
        tableView.rx.panGesture { gesture, delegate in
            
            delegate.beginPolicy = .custom({[weak self] gesture in
                guard let self else { return false }
                if gesture.location(in: self.inputView2).y > 0 {
                    return false
                }
//                if isHR {
//                    return false
//                }
                let velocity = gesture.translation(in: self.view)
                return abs(velocity.y) < abs(velocity.x) && velocity.x < 0
            })
            delegate.simultaneousRecognitionPolicy = .custom({[weak self] (gesture, otherGestrue) in
                guard let self else { return false }
                if otherGestrue is UITapGestureRecognizer {
                    print(otherGestrue.view)
                    return true
                }
                guard let pan = otherGestrue as? UIPanGestureRecognizer else {
                    return false
                }
                let velocity = pan.velocity(in: self.tableView)
                return abs(velocity.y) > abs(velocity.x)
            })
        }.subscribe(onNext: {[weak self] gesture in
            guard let self else {return}
            let location = gesture.location(in: self.tableView)
            switch gesture.state{
            case .began:
                guard let indexPath = tableView.indexPathForRow(at: location),
                      let cell = tableView.cellForRow(at: indexPath) as? MentionAbleChatCell,
                      let chatId = cell.id,
                      !cell.isRemoved else { return }
                mentionSetting = MessageMentionSetting(firstLocation: gesture.location(in: cell.contentView),
                                                       movingLeftConstraint: cell.setMentionState(gap: 0),
                                                       movingMessageId: chatId)
            case .changed:
                guard let mention = mentionSetting else { return }
                guard let row = reactor.currentState.messages.firstIndex(where: {$0.identity == mention.movingMessageId}) else {return}
                let indexPath = IndexPath(row: row, section: 2)
                guard let cell = tableView.cellForRow(at: indexPath) as? MentionAbleChatCell  else { return }
                let gap = mention.firstLocation.x - gesture.location(in: cell.contentView).x
                if gap < 60 && (mention.isBibrate == true){
                    mentionSetting?.isBibrate = false
                }
                if gap > 60 && (mentionSetting?.isBibrate == false){
                    mentionSetting?.generator.impactOccurred()
                    mentionSetting?.isBibrate = true
                    return
                }
                mentionSetting?.movingLeftConstraint = cell.setMentionState(gap: gap)
//                cell.leftConstraint.constant = max(min(space - gap,space), -(60 - space))
//                cell.contentView.layoutIfNeeded()
//                cell.mentionImageView.alpha = gap/60
            case .ended,.cancelled,.failed:
                guard let mention = mentionSetting else { return }
                guard let row = reactor.currentState.messages.firstIndex(where: {$0.identity == mention.movingMessageId}) else {return}
                let indexPath = IndexPath(row: row, section: 2)
                guard let cell = tableView.cellForRow(at: indexPath) as? MentionAbleChatCell  else { return }
                let gap = mention.firstLocation.x - gesture.location(in: cell.contentView).x
                DispatchQueue.main.async {
                    cell.leftConstraint.constant = cell.setMentionState(gap: 0)
                    UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                        cell.layoutIfNeeded()
                        cell.mentionIconView.alpha = 0
                    }, completion: nil)
                }
                if gap >= 60{
                    reactor.action.onNext(.mention(chatId: mention.movingMessageId))
                }
                mentionSetting = nil
            default:
                break
            }
        }).disposed(by: disposeBag)
        
        let dateConverter = ChatDateConverter()
        let dataSource = RxTableViewSectionedReloadDataSourceWithReloadSignal<MySectionModel> (configureCell:{ [weak self] dataSource, tableView, indexPath, item in
            switch item{
            case .sent(let chat):
                let cell = tableView.dequeueReusableCell(withIdentifier: "SentCell", for: indexPath) as! SentCell
                cell.bindUI(chat, dateConverter: dateConverter, fail: nil, isHR: false, hiddenUnreadCount: false)
                if let messageId = chat.mention?.messageId{
                    cell.chatView.rx.tapGesture(configuration: { gesture, delegate in
                        delegate.simultaneousRecognitionPolicy = .never
                    })
                    .when(.recognized)
                    .subscribe(onNext: { _ in
                        reactor.action.onNext(.mentionClicked(messageId: messageId))
                    }).disposed(by: cell.disposeBag)
                }
                cell.removeClicked
                    .observe(on: MainScheduler.instance)
                    .map({Reactor.Action.removeMessage(messageId: chat.id)})
                    .subscribe(onNext: { action in
                        self?.presentAlert(title: "삭제하시겠습니까?", content: "삭제하시면 더 이상\n이 채팅이 노출되지 않아요", okAction: {
                            reactor.action.onNext(action)
                        }, cancleAction: {}, retryAction: nil)
                    }).disposed(by: cell.disposeBag)
                
                cell.mentionClicked
                    .observe(on: MainScheduler.instance)
                    .map({Reactor.Action.mention(chatId: chat.id)})
                    .bind(to: reactor.action)
                    .disposed(by: cell.disposeBag)
                
                
                return cell
            case .received(let chat):
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecivedCell", for: indexPath) as! RecivedCell
                
                cell.bindUI(chat, dateConverter: dateConverter,skipMenu: false,managerName: nil,hiddenUnreadCount: false, hiddenSchool: true, roomHost: false)
                
                
                cell.mentionClicked
                    .observe(on: MainScheduler.instance)
                    .map({Reactor.Action.mention(chatId: chat.id)})
                    .bind(to: reactor.action)
                    .disposed(by: cell.disposeBag)
                
                if let messageId = chat.mention?.messageId{
                    cell.chatView.rx.tapGesture(configuration: { gesture, delegate in
                        delegate.simultaneousRecognitionPolicy = .never
                    })
                    .when(.recognized)
                    .subscribe(onNext: { _ in
                        reactor.action.onNext(.mentionClicked(messageId: messageId))
                    }).disposed(by: cell.disposeBag)
                }
                
                return cell
            case .notice(let notice):
                let cell = tableView.dequeueReusableCell(withIdentifier: "UnreadCell", for: indexPath) as! UnreadCell
//                cell.contentView.backgroundColor = .white
                cell.contentLabel.text = notice.content
                return cell
            case .date(let str):
                let cell = tableView.dequeueReusableCell(withIdentifier: "UnreadCell", for: indexPath) as! UnreadCell
//                cell.contentView.backgroundColor = .white
                cell.contentLabel.text = dateConverter.getDatePretty(formattedString: str, formatType: .day)
                return cell
            case .loading(let chat,fail: let status):
                let cell = tableView.dequeueReusableCell(withIdentifier: "SentCell", for: indexPath) as! SentCell
                cell.bindUI(chat, dateConverter: dateConverter, fail: status, hiddenUnreadCount: false)
                if status{
                    cell.resentButtonOption.rx.tap
                        .subscribe(onNext:{ _ in
                            self?.presentAlert(code: .sendFail, action1: {
                                //삭제
                                reactor.action.onNext(.removeButtonClicked(chat))
                            }, action2: {
                                //재전송
                                reactor.action.onNext(.retryButtonClicked(chat))
                            })
                        }).disposed(by: cell.disposeBag)
                }
                return cell
            case .unread:
                let cell = tableView.dequeueReusableCell(withIdentifier: "UnreadCell", for: indexPath) as! UnreadCell
                cell.contentLabel.text = "여기까지 읽으셨습니다."
                return cell
            }
        })
        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)
        
//        reactor.state.map({$0.announcementDetailReactor})
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: { [weak self] detailReactor in
//                guard let self, let detailReactor else {return}
//                let storyboard = UIStoryboard(name: "HRStoryboard", bundle: nil)
//                guard let vc = storyboard.instantiateViewController(withIdentifier: "AnnouncementDetailView") as? AnnouncementDetailView else {return}
//                vc.reactor = detailReactor
//                self.navigationController?.pushViewController(vc, animated: true)
//            }).disposed(by: disposeBag)
        
        
        reactor.state.map({[
            MySectionModel(header: "fail", items: $0.failMessages.map({ChatType.loading($0, fail: true)})),
            MySectionModel(header: "loading", items: $0.loadingMessages.map({ChatType.loading($0, fail: false)})),
            MySectionModel(header: "messages", items: $0.messages)
        ]})
        .observe(on: MainScheduler.instance)
        .distinctUntilChanged()
        .bind(to: tableView.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
        
        tableView.rx.willDisplayCell
//            .skip(until: reactor.state.map({$0.messages.isEmpty}).filter({!$0})
//                .delay(.milliseconds(300), scheduler: ConcurrentDispatchQueueScheduler.init(qos: .background)))
            .throttle(.milliseconds(10), scheduler: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .map({Reactor.Action.didDisplayCell($0.indexPath)})
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
       
       
        reactor.state.map({$0.scrollTo})
            .subscribe(on: MainScheduler.instance)
            .distinctUntilChanged()
            .compactMap({$0})
            .observe(on: MainScheduler.instance)
            .filter({ [weak self] indexPath in
                guard let self else {return false}
                if self.tableView.numberOfRows(inSection: indexPath.section) > indexPath.row {
                    print("이건 성공")
                    return true
                } else {
                    print("실패~ ",self.tableView.numberOfRows(inSection: indexPath.section))
                    return false
                }
            })
            .map({($0,UITableView.ScrollPosition.bottom,false)})
            .bind(onNext: tableView.scrollToRow)
            .disposed(by: disposeBag)
        
        reactor.state.map({$0.scroll})
            .subscribe(on: MainScheduler.instance)
            .distinctUntilChanged()
            .compactMap({$0})
            .observe(on: MainScheduler.instance)
            .filter({ [weak self] scroll in
                guard let self else {return false}
                if self.tableView.numberOfRows(inSection: scroll.indexPath.section) > scroll.indexPath.row {
                    return true
                } else {
                    return false
                }
            })
            .map({($0.indexPath, $0.position, $0.animated)})
            .do(afterNext: {[weak self] scroll in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: {
                    if let cell = self?.tableView.cellForRow(at: scroll.0) {
                        let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
                        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                        animation.duration = 1.0
                        animation.keyTimes = [0, 0.25, 0.5, 0.75, 1]
                        animation.timingFunctions = [.init(controlPoints: 0.5, 0, 1, 0.5),
                                                     .init(controlPoints: 0, 0.5, 0.5, 1),
                                                     .init(controlPoints: 0.5, 0, 1, 0.5),
                                                     .init(controlPoints: 0, 0.5, 0.5, 1)]
                        animation.values = [0, 13, 0, 13, 0]
                        
                        cell.layer.add(animation, forKey: "shake")
                    }
                })
            })
            .bind(onNext: tableView.scrollToRow)
            .disposed(by: disposeBag)
//        reactor.state.map({$0.lastestChat})
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: {[weak self] chat in
//                guard let self else {return}
//                if let chat{
//                    self.lastestChatView.isHidden = false
//                }
//                else{
//                    self.lastestChatView.isHidden = true
//                }
//            }).disposed(by: disposeBag)
        reactor.state.map({$0.addedChatSize})
            .observe(on: MainScheduler.asyncInstance)
            .distinctUntilChanged()
            .flatMap({[weak self] height -> Observable<CGPoint> in
                guard let self = self, let height = height else {return .empty()}
                if -self.tableView.contentOffset.y + 100 < self.tableView.contentInset.top  {
                    var currentContentOffset = self.tableView.contentOffset
                    currentContentOffset.y += height
                    return .just(currentContentOffset)
                }
                else{
                    if self.tableView.numberOfSections > 2, !self.tableView.isDragging {
                        if self.tableView.numberOfRows(inSection: 0) > 0 {
                            DispatchQueue.main.async {
                                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                            }
                        }
                        else if self.tableView.numberOfRows(inSection: 1) > 0 {
                            DispatchQueue.main.async {
                                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: false)
                            }
                        }
                        else if self.tableView.numberOfRows(inSection: 2) > 0 {
                            DispatchQueue.main.async {
                                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 2), at: .top, animated: false)
                            }
                        }
                    }
                    return .empty()
                }
            })
            .do(onNext: {[weak self] _ in
                self?.tableView.layoutIfNeeded()
            })
            .bind(to: tableView.rx.contentOffset)
            .disposed(by: disposeBag)
                rx.viewDidAppear
                .take(1)
                .subscribe(onNext: { _ in
                    reactor.action.onNext(.viewDidAppear)
                }).disposed(by: disposeBag)
                
        reactor.state.map({$0.mention})
            .distinctUntilChanged()
            .skip(1)
            .debounce(.milliseconds(10), scheduler: MainScheduler.asyncInstance)
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: {[weak self] mention in
                guard let self else {return}
                if let mention {
                   
                    self.inputView2.cameraButton.setImage(.init(named: "mention"), for: .normal)
                    self.inputView2.cameraButton.isUserInteractionEnabled = false
                    if let image = mention.image {
                        self.inputView2.mentionImageView.isHidden = false
                        self.inputView2.mentionImageView.kf.setImage(with: URL(string: image))
                    }
                    else{
                        self.inputView2.mentionImageView.isHidden = true
                    }
                    self.inputView2.mentionContentLabel.text = mention.content
                    if mention.userId == user.id {
                        self.inputView2.mentionNicknameLabel.text = "나"
                    }
                    else{
                        self.inputView2.mentionNicknameLabel.text = mention.name
                    }
                    lastestChatView.snp.remakeConstraints { make in
                        make.centerX.equalToSuperview()
                        make.bottom.equalTo(self.inputView2.mentionView.snp.top).offset(-7)
                        make.height.equalTo(35)
                    }
                    scrollToBottomButton.snp.remakeConstraints { make in
                        make.bottom.equalTo(self.inputView2.mentionView.snp.top).offset(-7)
                        make.trailing.equalToSuperview().offset(-10)
                        make.width.equalTo(35)
                        make.height.equalTo(35)
                    }
                    self.view.layoutIfNeeded()
                    if self.inputView2.mentionView.isHidden {
                        let topInset = self.tableView.contentInset.top
                        self.tableView.contentInset.top = topInset + 45
                        self.tableView.contentOffset.y -= 45
                    }
                    self.inputView2.mentionView.isHidden = false
                    
                }
                else{
                  
                    self.inputView2.cameraButton.setImage(.init(named: "camera"), for: .normal)
                    self.inputView2.cameraButton.isUserInteractionEnabled = true
                    lastestChatView.snp.remakeConstraints { make in
                        make.centerX.equalToSuperview()
                        make.bottom.equalTo(self.inputView2.snp.top)
                        make.height.equalTo(35)
                    }
                    scrollToBottomButton.snp.remakeConstraints { make in
                        make.bottom.equalTo(self.inputView2.snp.top)
                        make.trailing.equalToSuperview().offset(-10)
                        make.width.equalTo(35)
                        make.height.equalTo(35)
                    }
                    self.tableView.contentOffset.y += 45
                    self.view.layoutIfNeeded()
                    self.inputView2.mentionView.isHidden = true
                    let topInset = self.tableView.contentInset.top
                    print("etet1",self.tableView.contentInset.top)
                    self.tableView.contentInset.top = topInset - 45
                }
            }).disposed(by: disposeBag)
                

        reactor.state.map({$0.addContentOffset})
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .flatMap({[weak self] height -> Observable<CGPoint> in
                guard let self = self, let height = height else {return .empty()}
                var currentContentOffset = self.tableView.contentOffset
                currentContentOffset.y += height
                return .just(currentContentOffset)
            })
            .do(onNext: {[weak self] _ in
                self?.tableView.layoutIfNeeded()
            })
            .subscribe(on: ConcurrentMainScheduler.instance)
            .bind(to: tableView.rx.contentOffset)
            .disposed(by: disposeBag)
                
        tableView.rx.modelSelected(ChatType.self)
            .subscribe(onNext:{ model in
                if case let .loading(chat, fail: fail) = model,
                    fail{
                    reactor.action.onNext(.retryButtonClicked(chat))
                }
            }).disposed(by: disposeBag)
                
        sideBarButton.rx.tap
            .map({Reactor.Action.sideMenuOpen})
            .observe(on: MainScheduler.instance)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
            roomInformationButton.rx.tap
                .map({Reactor.Action.sideMenuOpen})
                .observe(on: MainScheduler.instance)
                .bind(to: reactor.action)
                .disposed(by: disposeBag)
                
        reactor.state.map({$0.popToRootView})
            .filter({$0})
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] _ in
                self?.navigationController?.popToRootViewController(animated: true)
            }).disposed(by: disposeBag)
                
        
        inputView2.sendButton.rx.tap
        .compactMap({[weak self] _ in
            self?.inputView2.textView.text
        })
        .map(Reactor.Action.sendButtonClicked)
        .do(onNext: {[weak self] _ in
            self?.inputView2.mentionView.isHidden = true
            self?.inputView2.textView.text = ""
        })
        .bind(to: reactor.action)
        .disposed(by: inputView2.disposeBag)
            
//        tableView.rx.tapGesture(configuration: { gesture, delegate in
//            delegate.beginPolicy = .custom({[weak self] tap in
//                guard let self else {return false}
//                let location = tap.location(in: self.inputView2.mentionView)
//                return self.inputView2.mentionCancelButton.frame.contains(location)
//            })
//        })
//        .when(.recognized)
        inputView2.mentionCancelButton.rx.tap
        .map({ _ in Reactor.Action.mention(chatId: nil)})
        .bind(to: reactor.action)
        .disposed(by: inputView2.disposeBag)
            
         let lastChatViewTap = lastestChatView.rx.tapGesture()
            .when(.recognized)
            .map({_ in Void()})
            
        let scrollToBottomTap = scrollToBottomButton.rx.tap.asObservable()
            
        Observable<Void>.merge([
            scrollToBottomTap,
            lastChatViewTap
        ])
        .map({Reactor.Action.scrollToBottomClicked})
        .bind(to: reactor.action)
        .disposed(by: disposeBag)
            
        reactor.state.map({$0.isBlocked})
            .distinctUntilChanged()
            .subscribe(onNext: {[weak self] isBlocked in
                if isBlocked{
                    self?.navigationController?.popViewController(animated: true)
                }
            }).disposed(by: disposeBag)
            
//        reactor.state.compactMap({$0.alert})
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: {[weak self] alert in
//                if alert == .hrManagerOut {
//                    self?.inputView2.textView.isUserInteractionEnabled = false
//                    self?.inputView2.textView.resignFirstResponder()
//                    self?.inputView2.sendButton.isUserInteractionEnabled = false
//                    self?.inputView2.cameraButton.isUserInteractionEnabled = false
//                    self?.inputView2.textView.text = nil
//                }
//                if alert == .hrUserOut {
//                    self?.inputView2.textView.isUserInteractionEnabled = false
//                    self?.inputView2.textView.resignFirstResponder()
//                    self?.inputView2.sendButton.isUserInteractionEnabled = false
//                    self?.inputView2.cameraButton.isUserInteractionEnabled = false
//                    self?.inputView2.textView.text = nil
//                }
//                if case .hrUserOutAskagain = alert{
//                    self?.presentAlert(code: alert,action1: {
//                        reactor.action.onNext(.withdrawalRoom)
//                    })
//                }
//                else if case .hrManagerOutAskagain = alert{
//                    self?.presentAlert(code: alert, action1: {
//                        reactor.action.onNext(.withdrawalRoom)
//                    })
//                }
//                else{
//                    self?.presentAlert(code: alert)
//                }
//            }).disposed(by: disposeBag)
            
//        reactor.state.compactMap({$0.announcement?.title})
//            .take(1)
//            .subscribe(onNext: {[weak self] title in
//                if user != nil{
//                    let components = title.components(separatedBy: " ・ ").first
//                    self?.navigationItem.title = components
//                }
//            }).disposed(by: disposeBag)
            
        
        
            reactor.state.map({$0.modifiedRoom})
            .distinctUntilChanged()
            .subscribe(onNext: {[weak self] modifiedRoom in
                guard let self,let modifiedRoom else {return}
                let titleView = UIView()
                let imageView = UIImageView()
                let titleLabel = UILabel()
                titleLabel.text = modifiedRoom.content
                if let imageURLstr = modifiedRoom.imageURL,
                   let imageURL = URL(string: imageURLstr){
                    imageView.kf.setImage(with: imageURL)
                }
                else if let image = modifiedRoom.image,image != ""{
                    imageView.image = UIImage(named: image )
                }
                imageView.layer.cornerRadius = 16
                imageView.clipsToBounds = true
                titleView.addSubview(imageView)
                titleView.addSubview(titleLabel)
                titleView.addSubview(sideBarButton)
                titleLabel.textColor = .jiuFontMain
                titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
                imageView.snp.makeConstraints { make in
                    make.height.width.equalTo(32)
                    make.top.leading.bottom.equalToSuperview()
                }
                titleLabel.snp.makeConstraints { make in
                    make.leading.equalTo(imageView.snp.trailing).offset(8)
                    make.centerY.equalToSuperview()
                    make.trailing.equalToSuperview()
                }
                
                self.navigationItem.leftItemsSupplementBackButton = true
                self.navigationItem.setLeftBarButton(.init(customView: titleView), animated: true)
                sideBarButton.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                
                
            }).disposed(by: disposeBag)
        
    }
    override func handleTap2(_ sender: UITapGestureRecognizer? = nil) {
        if let location = sender?.location(in: nil) {
            if self.inputView2.frame.contains(location) {
                return
            }
        }
        self.inputView2.textView.resignFirstResponder()
    }
    let lastestChatView = UIView().then { view in
        view.backgroundColor = UIColor(red: 111/255, green: 111/255, blue: 112/255, alpha: 1)
        view.layer.cornerRadius = 18
    }
    let lastestChatLabel = UILabel().then { label in
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .regular)
    }
    let scrollToBottomButton = UIButton().then { button in
        button.layer.cornerRadius = 17.5
        button.backgroundColor = UIColor(red: 111/255, green: 111/255, blue: 112/255, alpha: 1)
        button.setImage(UIImage(systemName:"chevron.down"), for: .normal)
        button.tintColor = UIColor.white
    }
    let roomInformationButton = UIButton().then { button in
        button.setImage(UIImage(resource: .moreButtonNavi), for: .normal)
        button.tintColor = UIColor(red: 127/255, green: 127/255, blue: 127/255, alpha: 1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lastestChatView.addSubview(lastestChatLabel)
        lastestChatView.isHidden = true
        scrollToBottomButton.isHidden = true
        lastestChatLabel.text = "새로운 메시지 확인하기"
        lastestChatLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
//            make.top.equalToSuperview().offset(8)
//            make.bottom.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }
        
        view.addSubview(scrollToBottomButton)
        view.addSubview(inputView2)
        view.addSubview(lastestChatView)
        
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(1)
            make.bottom.equalToSuperview()
        }
        lastestChatView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(inputView2.snp.top)
            make.height.equalTo(35)
        }
        
        scrollToBottomButton.snp.makeConstraints { make in
            make.bottom.equalTo(inputView2.snp.top)
            make.trailing.equalToSuperview().offset(-10)
            make.width.equalTo(35)
            make.height.equalTo(35)
        }
       
        if let roomItem = reactor?.initialState.room as? RoomListItem{
            let titleView = UIView()
            let imageView = UIImageView()
            let titleLabel = UILabel()
            titleLabel.text = roomItem.content
            if let imageURLstr = roomItem.imageURL,
               let imageURL = URL(string: imageURLstr){
                imageView.kf.setImage(with: imageURL)
            }
            else if roomItem.image != ""{
                imageView.image = UIImage(named: roomItem.image)
            }
            if roomItem.image == "" {
                titleView.addSubview(titleLabel)
                titleView.addSubview(sideBarButton)
                titleLabel.textColor = .jiuFontMain
                titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
                titleLabel.snp.makeConstraints { make in
                    make.bottom.leading.equalToSuperview()
                    make.centerY.equalToSuperview()
                    make.trailing.equalToSuperview()
                }
            }
            else{
                imageView.layer.cornerRadius = 16
                imageView.clipsToBounds = true
                titleView.addSubview(imageView)
                titleView.addSubview(titleLabel)
                titleView.addSubview(sideBarButton)
                titleLabel.textColor = .jiuFontMain
                titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
                imageView.snp.makeConstraints { make in
                    make.height.width.equalTo(32)
                    make.top.leading.bottom.equalToSuperview()
                }
                titleLabel.snp.makeConstraints { make in
                    make.leading.equalTo(imageView.snp.trailing).offset(8)
                    make.centerY.equalToSuperview()
                    make.trailing.equalToSuperview()
                }
            }

            self.navigationItem.leftItemsSupplementBackButton = true
            self.navigationItem.setLeftBarButton(.init(customView: titleView), animated: true)
            sideBarButton.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        roomInformationButton.imageEdgeInsets = .init(top: 2, left: 8, bottom: -2, right: -8)
        let barButton = UIBarButtonItem(customView: roomInformationButton)
        barButton.setBackButtonTitlePositionAdjustment(.init(horizontal: -16, vertical: 0), for: .default)
//        barButton.setBackgroundVerticalPositionAdjustment(-16, for: .default)
//        barButton.backgroundVerticalPositionAdjustment(for: .compact)
        self.navigationItem.setRightBarButton(barButton, animated: true)
        
//        self.navigationItem.setLeftBarButtonItems([self.navigationItem.backBarButtonItem!, .init(customView: titleView)], animated: true)
        inputView2.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        inputView2.chatStackView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(7)
            make.height.greaterThanOrEqualTo(44)
//            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-7)
            make.bottom.equalTo(self.view.keyboardLayoutGuide.snp.top).offset(-7)
        }
        let camera = UIAction(title: "카메라", handler: { [weak self] _ in
            guard let self = self else { return }
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
//                    DispatchQueue.main.async {
//                        
//                        self.presentAlert(title: "설정창에서 카메라 접근 권한을 허용해주세요", content: nil, okAction: {
//                            if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
//                                UIApplication.shared.open(appSettings)
//                            }
//                        }, cancleAction: {}, retryAction: nil)
//
//                    }
                }
            })
        })
        let photo = UIAction(title: "사진", handler: { [weak self] _ in
            guard let self = self else { return }
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 1
            configuration.filter = .images
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        })
        let buttonMenu = UIMenu(title: "", children: [camera, photo])
        photo.image = UIImage.init(systemName: "photo.fill")
        camera.image = UIImage.init(systemName: "camera.fill")
        inputView2.cameraButton.showsMenuAsPrimaryAction = true
        inputView2.cameraButton.menu = buttonMenu
        
//        inputView2.isUserInteractionEnabled = false
//        tableView.isUserInteractionEnabled = false
//        lastestChatView.isUserInteractionEnabled = false
//        self.scrollToBottomButton.isUserInteractionEnabled = false
//        autoAskingView.tableView.isUserInteractionEnabled = true
//
//        print()
        inputView2.textViewHightChanged
            .scan((height: 0,diff: 0), accumulator: { a, height in
                return (height:height ,diff: a.height - height)
            })
            .map({$0.diff})
            .distinctUntilChanged()
            .subscribe(onNext:{ [weak self] diff in
                guard let self else {return}
                print("<textView> , \(diff)")
                self.tableView.contentInset.top -= diff
                if diff < 0 {
                    self.tableView.contentOffset.y += diff
                }
            }).disposed(by: inputView2.disposeBag)
        tableView.keyboardDismissMode = .interactive
        tableView.register(UINib(nibName: "SentCell", bundle: nil), forCellReuseIdentifier: "SentCell")
        tableView.register(UINib(nibName: "RecivedCell", bundle: nil), forCellReuseIdentifier: "RecivedCell")
        tableView.register(UINib(nibName: "UnreadCell", bundle: nil), forCellReuseIdentifier: "UnreadCell")
       
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        tableView.contentInset.top = 92
        managerKeyboard()
    }
    func managerKeyboard(){
        var managerAdditionalHeight: CGFloat = 0.0
        var isDisappearing = true
        var maxKeyboardHeight: CGFloat = 0.0
        var lastKeyboardHeight: CGFloat = 0.0
        rx.viewWillDisappear
            .subscribe(onNext:{ _ in
                print("<inputView> viewWillDisappear")
                isDisappearing = true
            }).disposed(by: disposeBag)
        rx.viewDidAppear
            .subscribe(onNext:{ _ in
                print("<inputView> viewDidAppear")
                isDisappearing = false
            }).disposed(by: disposeBag)
        
        RxKeyboard.instance.isHidden
            .drive(onNext: {[weak self] isHidden in
                guard let self = self else {return}
                if isDisappearing{
                    return
                }
                let bottomInset = self.view.safeAreaInsets.bottom + managerAdditionalHeight
                var offsetY = self.tableView.contentOffset.y
                if isHidden{
                    //                    if offsetY < 0{
                    //                        return
                    //                    }
                    //                    else{
                    offsetY += (lastKeyboardHeight - bottomInset)
                    //                    }
                    self.tableView.contentOffset.y = offsetY
                    self.tableView.layoutIfNeeded()
                }
            }).disposed(by: disposeBag)
        
        RxKeyboard.instance.visibleHeight
            .distinctUntilChanged()
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let self = self,!isDisappearing,self.inputView2.textView.frame.height > 30  else { return }
                let bottomInset = self.view.safeAreaInsets.bottom
                let chatViewBottom = max((keyboardVisibleHeight - bottomInset),0) + 7.0
                var insetTop = chatViewBottom + bottomInset + self.inputView2.textView.frame.height + 7.0
                insetTop += managerAdditionalHeight
                if reactor?.currentState.mention != nil {
                    insetTop += 45
                }
                //                self.inputView2.chatStackView.snp.updateConstraints { make in
                //                    make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-chatViewBottom)
                //                }
                if maxKeyboardHeight > 200, keyboardVisibleHeight > maxKeyboardHeight{
                    self.tableView.contentOffset.y += maxKeyboardHeight - keyboardVisibleHeight
                    lastKeyboardHeight = keyboardVisibleHeight
                }
                self.tableView.contentInset.top = insetTop
                self.tableView.verticalScrollIndicatorInsets.top = insetTop
                //                self.view.setNeedsLayout()
                //                UIView.animate(withDuration: 0) {
                //                    self.view.layoutIfNeeded()
                //                }
            })
            .disposed(by: disposeBag)
        
        
        RxKeyboard.instance.willShowVisibleHeight
            .drive(onNext: {[weak self] height in
                guard let self = self else {return}
                if isDisappearing{
                    return
                }
                maxKeyboardHeight = height
                lastKeyboardHeight = maxKeyboardHeight
                if maxKeyboardHeight > 200 {
                    let bottomInset = self.view.safeAreaInsets.bottom
                    let offset = self.tableView.contentOffset.y - (height - bottomInset)
                    var inputViewHeight = self.inputView2.chatStackView.frame.height + 13
                    inputViewHeight += managerAdditionalHeight
                    if reactor?.currentState.mention != nil {
                        inputViewHeight += 45
                        //                        offset -= 45
                    }
                    self.tableView.setNeedsLayout()
                    self.tableView.contentOffset.y = max(offset, -(height + inputViewHeight))
                    UIView.performWithoutAnimation {
                        self.tableView.layoutIfNeeded()
                    }
                    //                    UIView.animate(withDuration: 0) {
                    //                    }
                }
                
            }).disposed(by: disposeBag)
    }
}

extension ChatView: PHPickerViewControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true,completion: { [weak self] in
            guard let self = self else {return}
//            self.reloadInputViews()
            if let result = results.first{
                result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, error in
                    //TODO:  - 에러처리 해야지
                    guard let data else {return}
                    if let image = UIImage(data: data){
                        DispatchQueue.main.async {
                            let resizer = ImageResizer()
                            resizer.imageResize(image: image)
                                .observe(on: MainScheduler.instance)
                                .subscribe(onNext:{ imageData in
                                    self.reactor?.action.onNext(.imageAdded(imageData))
                                }).disposed(by: self.disposeBag)
                        }
                    }
                }
            }
        })
    }
    
    
}
extension ChatView: UIImagePickerControllerDelegate & UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: { [weak self] in
            guard let self = self else { return }
//            self.reloadInputViews()
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                let resizer = ImageResizer()
                resizer.imageResize(image: image)
                    .subscribe(onNext:{ image in
                        self.reactor?.action.onNext(.imageAdded(image))
                    }).disposed(by: self.disposeBag)
            }
        })
    }
}
struct MessageMentionSetting{
    var firstLocation: CGPoint
    var movingLeftConstraint: CGFloat
    var isBibrate: Bool = false
    let generator = UIImpactFeedbackGenerator(style: .light)
    var movingMessageId: String
}

