//
//  RefreshHandler.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//
import UIKit
import RxSwift
import RxCocoa

class RefreshHandler: NSObject {
    let refresh = PublishSubject<Void>()
    let refreshControl = UIRefreshControl()

    init(view: UIScrollView) {
        super.init()
        refreshControl.addTarget(self, action: #selector(refreshControlValueDidChanged(_:)), for: .valueChanged)
        view.refreshControl = refreshControl
//        let imageView = UIImageView(image: .init(named: "levelDefaultImage"))
//        imageView.sizeToFit()
//        refreshControl.addSubview(imageView)
//        imageView.snp.makeConstraints { make in
//            make.center.equalToSuperview()
//        }
        refreshControl.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        refreshControl.layer.zPosition = -1
        
//        refreshControl.tintColor = .
        
    }
    // MARK: - Action
    @objc func refreshControlDidRefresh(_ control: UIRefreshControl) {
        
    }
    @objc func refreshControlValueDidChanged(_ control: UIRefreshControl) {
        refresh.onNext(())
    }
    func end() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
}
