//
//  SocketManager.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//
import Starscream
import RxCocoa
import RxSwift
import Network
let socketURL:String = "ws://\(chatBase):8080/v1/message"
//let socketURL: String = "ws://192.168.1.22:8080/v1/message"
class SocketManager: WebSocketDelegate{
    deinit {
        socket.delegate = nil
        socket.disconnect()
        print("socket : <SocketManager> deinit")
    }
    var isConnect = false
    var heartbeat: Double = Date().timeIntervalSince1970
    let networkMonitor = NetworkMonitor()
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected:
            heartbeat = Date().timeIntervalSince1970
            isConnect = true
            didConnect.onNext(client)
        case .disconnected:
            isConnect = false
            didDisconnect.onNext(client)
        case .text(let string):
            DispatchQueue.main.async { [weak self] in
                self?.didReceiveMessage.onNext((client,string))
            }
        case .pong:
            isConnect = true
            heartbeat = Date().timeIntervalSince1970
        case .error:
            isConnect = false
            DispatchQueue.main.async { [weak self] in
                self?.didDisconnect.onNext(client)
            }
        case .viabilityChanged:
            break
        case .reconnectSuggested:
            break
        case .cancelled:
            isConnect = false
        default : break
        }
    }
    let didConnect = PublishSubject<WebSocketClient>()
    let didReceiveData = PublishSubject<(WebSocketClient,Data)>()
    let didReceiveMessage = PublishSubject<(WebSocketClient,String)>()
    let didDisconnect = PublishSubject<WebSocketClient>()
    let connectSender = PublishSubject<Void>()
    var socket: WebSocket
    let queue = DispatchQueue.global()
//    let monitor = NWPathMonitor()
    var disposeBag = DisposeBag()
    var disposeBag2 = DisposeBag()
    var userId = user.id
    init() {
        
        let url = URL(string: socketURL + "/\(user.id)")!
        let request = URLRequest(url: url)
        let pinner = FoundationSecurity(allowSelfSigned: true)
        socket = WebSocket(request: request,certPinner: pinner)
        socket.delegate = self
        socket.callbackQueue = queue
        socket.request.timeoutInterval = 10
        
        
        connectSender
            .throttle(.seconds(1), scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: {[weak self] _ in
                guard let self = self else {return}
                if !self.isConnect{
                    print("socket : <Connecting> 다시 연결중")
                    self.socket.connect()
                }
        }).disposed(by: disposeBag2)
        
        UIApplication.rx.didEnterBackground
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onNext: {[weak self] _ in
                self?.disconnect()
            }).disposed(by: disposeBag2)
        
        UIApplication.rx.didBecomeActive
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onNext: {[weak self] _ in
                guard let self = self else {return}
                if !self.isConnect{
                    self.connect()
                }
            }).disposed(by: disposeBag2)
        connect()
    }
    func connect(){
        networkMonitor.startMonitoring()
        disposeBag = DisposeBag()
        didDisconnect.debounce(.seconds(1), scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext:{[weak self] ws in
                guard let self else {return}
                if !self.isConnect{
                    self.connectSender.onNext(Void())
                }
            }).disposed(by: disposeBag)
        if networkMonitor.networkConnectAble{
            socket.connect()
        }
        Observable<Int>.interval(.seconds(10), scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
            .subscribe(onNext:{[weak self] _ in
                guard let self else {return}
//                print("socket : <Ping> 보냄",Date().timeIntervalSince1970 - self.heartbeat)
//                if
                if self.heartbeat != 0 && Date().timeIntervalSince1970 - self.heartbeat > 15{
                    self.isConnect = false
//                    let url = URL(string: socketURL + "/\(self.userId)")!
//                    let request = URLRequest(url: url)
                    self.socket.forceDisconnect()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        self.didDisconnect.onNext(self.socket)
                    })
                    return
                }
                self.socket.write(ping: Data())
            }).disposed(by: disposeBag)
        
        networkMonitor.networkStatusChanged
            .debounce(.seconds(1), scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
            .subscribe(onNext:{ [weak self] connectAble in
                guard let self else {return}
                if connectAble{
                    if !self.isConnect{
                        self.connectSender.onNext(Void())
                    }
                }
                else{
                    self.socket.disconnect()
                }
            }).disposed(by: disposeBag)
    }
    func disconnect(){
        disposeBag = DisposeBag()
        if self.isConnect{
            socket.disconnect()
        }
        networkMonitor.stopMonitoring()
    }
}
