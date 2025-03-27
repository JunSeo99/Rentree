//
//  NetworkMonitor.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//

import Network
import RxSwift

class NetworkMonitor {
    var monitor: NWPathMonitor!
    var networkConnectAble: Bool = true
    let networkStatusChanged = PublishSubject<Bool>()
    let queue = DispatchQueue(label: "networkmonitor", qos: .background)
    init(){
//        monitor = NWPathMonitor()
    }
    func startMonitoring() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = {[weak self] path in
            guard let self = self else {return}
            if path.status == .satisfied {
                self.networkConnectAble = true
                self.networkStatusChanged.onNext(true)
                // 인터넷 연결이 되어 있는 경우
                // 다시 소켓 연결을 시도할 수 있습니다.
                // ...
            } else {
                self.networkConnectAble = false
                self.networkStatusChanged.onNext(false)
                // 인터넷 연결이 되어 있지 않은 경우
                // 소켓 연결을 시도하지 않습니다.
                // ...
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        if monitor == nil{
            return
        }
        monitor.cancel()
        monitor.pathUpdateHandler = nil
    }
}
