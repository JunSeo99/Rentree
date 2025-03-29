//
//  PostListView.swift
//  Rentree
//
//  Created by jun on 3/25/25.
//

import UIKit
import RxSwift
import RxCocoa
import Moya
import Reusable

class PostListView: UIViewController {
    var provider = MoyaProvider<API>()
    var disposeBag = DisposeBag()
    var posts: [Post] = []
    lazy var handler = RefreshHandler(view: tableView)
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var searchBackgroundView: UIView!
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        

        handler.refresh
            .subscribe(onNext: {[weak self] _ in
                self?.refresh()
            })
            .disposed(by: disposeBag)
        
        
        searchBackgroundView.layer.cornerRadius = 10
        searchBackgroundView.layer.borderWidth = 1
        searchBackgroundView.layer.cornerRadius = 18
        tableView.register(cellType: PostListViewCell.self)
        searchBackgroundView.layer.borderColor = UIColor.jiuItem2.cgColor
        self.tableView.dataSource = self
        self.tableView.delegate = self
        refresh()
        
        self.tableView.keyboardDismissMode = .onDrag
        tableView.delaysContentTouches = false
        textField.rx.text
            .orEmpty
            .skip(1)
            .distinctUntilChanged()
            .debounce(.milliseconds(200), scheduler: MainScheduler.instance)
            .flatMapLatest({
                return Observable.just($0)
            })
            .subscribe(onNext: {[weak self] text in
                self?.refresh(query: text)
            }).disposed(by: disposeBag)
        
        
        
        
    }
    
    
    func refresh(query: String = "") {
        provider.rx.request(.getPosts(schoolCode: user.schoolCode, query: query))
            .do(onSuccess: {
                print(String(data: $0.data, encoding: .utf8)!)
            })
            .map([Post].self)
            .asObservable()
            .do(onError: {
                print($0)
            })
            .catchAndReturn(Post.sampleData())
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: {[weak self] posts in
                self?.posts = posts
                self?.tableView.reloadData()
                self?.handler.end()
            }, onError: {[weak self] _ in
                self?.handler.end()
            }).disposed(by: disposeBag)
        
    }
    
    func likeClicked(postId: String, state: Bool) {
        provider.rx.request(.like(postId: postId, userId: user.id, state: state))
            .subscribe(onSuccess: {[weak self] _ in
                guard let self else {return }
                self.refresh()
            })
            .disposed(by: disposeBag)
    }
    
}


extension PostListView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: PostListViewCell.self)
        let post = posts[indexPath.row]
        cell.bindUI(post: post)
        cell.likeButton.rx.tap
            .subscribe(onNext: {[weak self] _ in
            guard let self else { return }
            // like api 호출
                self.likeClicked(postId: post.id, state: post.likes.contains(where: {$0 == user.id}))
            
            
        }).disposed(by: cell.disposeBag)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var post = posts[indexPath.row]
        let vc = PostDetailView(nibName: "PostDetailView", bundle: nil)
        if let index = self.posts.firstIndex(of: post) {
            self.posts[index].viewCount += 1
            self.tableView.reloadData()
            post = self.posts[index]
        }
        vc.post = post
        vc.likeClicked
            .subscribe(onNext: {[weak self] id in
                guard let self else { return }
                self.likeClicked(postId: id, state: post.likes.contains(where: {$0 == user.id}))
            }).disposed(by: vc.disposeBag)
        
        provider.rx.request(.showPost(post.id))
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onSuccess: {[weak self] _ in
                guard let self else { return }
//                if let index = self.posts.firstIndex(of: post) {
//                    self.posts[index].viewCount += 1
//                    self.tableView.reloadData()
//                }
            }).disposed(by: disposeBag)
        self.navigationController?.navigationController?.pushViewController(vc, animated: true)
        
        
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let cell = tableView.cellForRow(at: indexPath) as? PostListViewCell else {
            return true
        }
        
        // tableView의 panGestureRecognizer에서 터치 좌표를 가져옴
        let touchPointInTableView = tableView.panGestureRecognizer.location(in: tableView)
        // 버튼의 좌표계로 터치 좌표 변환 (부모 뷰 계층을 자동으로 고려)
        let touchPointInButton = cell.likeButton.convert(touchPointInTableView, from: tableView)
        
        // 버튼의 bounds(좌표계 기준)와 비교
        if cell.likeButton.bounds.contains(touchPointInButton) {
            return false
        }
        
        return true
    }
}


