//
//  BorrowedView.swift
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


class BorrowedView: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var provider = MoyaProvider<API>()
    var chatProvider = MoyaProvider<ChatAPI>()
    var disposeBag = DisposeBag()
    var posts: [Post] = []
    lazy var handler = RefreshHandler(view: tableView)
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(cellType: BorrowedCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        handler.refresh
            .subscribe(onNext: {[weak self] _ in
                self?.refresh()
            })
            .disposed(by: disposeBag)
        refresh()
        // Do any additional setup after loading the view.
    }
    
    func refresh() {
        provider.rx.request(.getBorrowedPost(userId: user.id))
            .map([Post].self)
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] posts in
                guard let self = self else { return }
                self.handler.end()
                self.posts = posts
                self.tableView.reloadData()
            }, onFailure: { [weak self] e in
                self?.handler.end()
                print(e)
            }).disposed(by: disposeBag)
    }
    
    

}

extension BorrowedView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: BorrowedCell.self)
        let post = posts[indexPath.row]
        
        cell.bindUI(post: post)
        cell.goToChat
            .flatMap({ [weak self] _ -> Observable<Room> in
                guard let self else { return .empty()}
                return self.chatProvider.rx.request(.getRoomTarget(userId: user.id, targetId: post.writerId))
                    .map(Room.self)
                    .asObservable()
                    .catch({ e in
                        print("error: ", e)
                        return .empty()
                    })
                
            })
            .subscribe(onNext: { room in
                MainNotification.default.onNext(.moveToRoom(room))
            }).disposed(by: cell.disposeBag)
        
        cell.rental
            .flatMap({ [weak self] _ -> Observable<Void> in
            guard let self else { return .empty()}
                return self.provider.rx.request(.allowBorrowing(postId: post.id, userId: user.id))
                .map(Room.self)
                .map({ _ in
                    return Void()
                })
                .asObservable()
                .catch({ e in
                    print("error: ", e)
                    return .empty()
                })
            
        })
        .subscribe(onNext: {[weak self] _ in
            self?.refresh()
        }).disposed(by: cell.disposeBag)
    
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        MainNotification.default.onNext(.moveToPost(post))
    }
    
}
