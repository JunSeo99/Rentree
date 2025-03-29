//
//  MyPostCell.swift
//  Rentree
//
//  Created by jun on 3/28/25.
//

import UIKit
import RxSwift
import RxCocoa
import Reusable
import Kingfisher

class MyPostCell: UITableViewCell, NibReusable {
    @IBOutlet weak var openStackView: UIStackView!
    
    @IBOutlet weak var chatCountLabel: UILabel!
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var contentImageView: UIImageView!
//    @IBOutlet weak var dateLabel: UILabel!
//    @IBOutlet weak var sharedLabel: UILabel!
//    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var goToPostButton: UIButton!
    @IBOutlet weak var contentLabel: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
//    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var priceView: UIView!
    @IBOutlet weak var seperatorView: UIView!
//    @IBOutlet weak var viewCountLabel: UILabel!
    
    @IBOutlet weak var openButton: UIButton!
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var longPeriodLabel: UILabel!
    @IBOutlet weak var longPeriodView: UIView!
    
    var openClicked: PublishSubject<Void> = .init()
    var goToPostClicked: PublishSubject<Void> = .init()
    
    var disposeBag = DisposeBag()
    override func awakeFromNib() {
        super.awakeFromNib()
        contentImageView.layer.cornerRadius = 6
        contentLabel.textContainerInset = .zero
        contentLabel.textContainer.lineFragmentPadding = 0
        contentLabel.textContainer.lineBreakMode = .byTruncatingTail
        
        
        longPeriodView.layer.cornerRadius = 5
        priceView.layer.cornerRadius = 5
        contentLabel.textContainer.maximumNumberOfLines = 3
        
        self.selectionStyle = .none
        self.arrowImageView.transform = .init(rotationAngle: .pi)
    }
    
    func bindUI(post: Post) {
        chatCountLabel.text = "채팅 \(post.borrowerInfo.count)건"
        openButton.rx.tap
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                if self?.arrowImageView.transform == .identity {
                    self?.arrowImageView.transform = .init(rotationAngle: .pi)
                }
                else {
                    self?.arrowImageView.transform = .identity
                }
                self?.openClicked.onNext(())
            }).disposed(by: disposeBag)
        goToPostButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.goToPostClicked.onNext(())
            }).disposed(by: disposeBag)
//        self.nameLabel.text = post.name
        
        if post.borrowerInfo.isEmpty {
            openStackView.isHidden = true
        }
        else {
            openStackView.isHidden = false
        }
        self.titleLabel.text = post.title
        self.contentLabel.text = post.content
//        self.dateLabel.text = DateConverter.dateToString(string: post.createdAt)
        if let image = post.photos.first,
           let imageURL = URL(string: image){
            contentImageView.kf.setImage(with: imageURL, options: [.transition(.fade(0.25))])
        }
        else {
            contentImageView.isHidden = true
        }
        
//        viewCountLabel.text = "\(Int.random(in: 1...10))"
//        likeLabel.text = "\(post.likes.count)"
//        
//        sharedLabel.text = "\(post.borrowerInfo.count)"
        
        if post.rentalType == "무료" {
            priceLabel.text = "무료 대여"
            longPeriodLabel.text = post.priceByPeriod
        }
        else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            
            priceLabel.text = "\(formatter.string(from: NSNumber(value: post.price)) ?? "\(post.price)")원/\(post.priceByPeriod)"
            longPeriodLabel.text = post.rentalType
        }
        
        
//        likeButton.rx.tap
//            .subscribe(onNext: {[weak self] _ in
//                self?.likeClicked.onNext(post.id)
//            }).disposed(by: disposeBag)
//        
//        if post.likes.contains(where: {$0 == user.id}) {
//            likeImageView.tintColor = #colorLiteral(red: 0.8980392157, green: 0.2745098039, blue: 0.2745098039, alpha: 1)
//            likeLabel.textColor = #colorLiteral(red: 0.8980392157, green: 0.2745098039, blue: 0.2745098039, alpha: 1)
//        }
//        else {
//            likeImageView.tintColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.5960784314, alpha: 1)
//            likeLabel.textColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.5960784314, alpha: 1)
//            
//        }
        
    }
    
    func selected(_ selected: Bool, animated: Bool) {
        print("cellSelected::",selected,"animated: ",animated)
        if selected {
//            let contentHeight = applicants.reduce(0.0, {$0 + ApplicantCell.calculateHeight($1)})
            self.arrowImageView.transform = .identity
//            self.tableView.reloadData()
//            self.tableViewHeight.constant = contentHeight
//            if animated {
////                UIView.animate(withDuration: 0.3, delay: 0,options: .curveEaseIn , animations: {[weak self] in
////                    guard let self else { return }
//                    self.contentView.layoutIfNeeded()
//                    self.layoutUpdate.onNext(())
////                })
//            }
//            else{
//                self.contentView.layoutIfNeeded()
//                layoutUpdate.onNext(Void())
//            }
        }
        else{
            self.arrowImageView.transform = .init(rotationAngle: .pi)
//            self.tableViewHeight.constant = 0
//            self.contentView.layoutIfNeeded()
//            if animated {
////                UIView.animate(withDuration: 0.3, delay: 0,options: .curveEaseIn , animations: {[weak self] in
////                    guard let self else { return }
//                    self.contentView.layoutIfNeeded()
//                    self.layoutUpdate.onNext(())
////                })
//            }
//            else{
//                self.contentView.layoutIfNeeded()
//                layoutUpdate.onNext(())
//            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentImageView.image = nil
        disposeBag = DisposeBag()
        
    }
}
