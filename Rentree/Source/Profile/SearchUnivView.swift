//
//  SearchUnivView.swift
//  Rentree
//
//  Created by jun on 3/26/25.
//

import UIKit
import RxSwift
import RxCocoa
import Moya
import Reusable


class SearchUnivView: UIViewController {
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    var provider: MoyaProvider<API>?
    var univs = [Univ]()
    var disposeBag = DisposeBag()
    var selected = PublishSubject<Univ>()
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let provider else { return }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: SearchUnivCell.self)
//        textField.rx.text
//            .subscribe(onNext: {
//                print($0)
//            }).disposed(by: disposeBag)
        
        
        textField.rx.text
            .orEmpty
            .do(onNext: { text in
                print(text)
            })
            .distinctUntilChanged()
            .debounce(.milliseconds(200), scheduler: MainScheduler.instance)
            .flatMapLatest({
                return Observable.just($0)
            })
            .flatMap({ text -> Observable<[Univ]> in
                return provider.rx.request(.getUnivList(query: text))
                    .map([Univ].self)
                    .asObservable()
                    .do(onError: {
                        print($0)
                    })
                    .catchAndReturn([])
            })
            .subscribe(onNext: {[weak self] univs in
                guard let self else { return }
                self.univs = univs
                self.tableView.reloadData()
            }).disposed(by: disposeBag)
        
        dismissButton.rx.tap
            .subscribe(onNext: {[weak self] _ in
                self?.dismiss(animated: true)
            }).disposed(by: disposeBag)
        
    }
    

}
extension SearchUnivView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: SearchUnivCell.self)
        let univ = univs[indexPath.row]
        cell.schoolNameLabel.text = univ.schoolName
        cell.addressLabel.text = univ.address
        
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return univs.count
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected.onNext(univs[indexPath.row])
        self.dismiss(animated: true)
    }
}

struct Univ: Codable {
    var address: String
    var schoolName: String
}
