//
//  PostListViewCell.swift
//  Rentree
//
//  Created by jun on 3/26/25.
//

import UIKit
import RxSwift
import RxCocoa
import Reusable
import Kingfisher

class PostListViewCell: UITableViewCell, NibReusable {

//    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var sharedLabel: UILabel!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var contentLabel: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
//    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var priceView: UIView!
    @IBOutlet weak var viewCountLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var longPeriodLabel: UILabel!
    @IBOutlet weak var longPeriodView: UIView!
    
    @IBOutlet weak var likeImageView: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    var likeClicked: PublishSubject<String> = .init()
    var disposeBag = DisposeBag()
    override func awakeFromNib() {
        super.awakeFromNib()
        contentImageView.layer.cornerRadius = 6
        contentLabel.textContainerInset = .zero
        contentLabel.textContainer.lineFragmentPadding = 0
        contentLabel.textContainer.lineBreakMode = .byTruncatingTail
        
        
        longPeriodView.layer.cornerRadius = 5
        priceView.layer.cornerRadius = 5
        
        
        self.selectionStyle = .none
    }
    
    func bindUI(post: Post) {
//        self.nameLabel.text = post.name
        self.titleLabel.text = post.title
        self.contentLabel.text = post.content
        self.dateLabel.text = DateConverter.dateToString(string: post.createdAt)
        if let image = post.photos.first,
           let imageURL = URL(string: image){
            contentImageView.kf.setImage(with: imageURL, options: [.transition(.fade(0.25))])
        }
        else {
            contentImageView.isHidden = true
        }
        
        viewCountLabel.text = "\(Int.random(in: 1...10))"
        likeLabel.text = "\(post.likes.count)"
        
        sharedLabel.text = "\(post.borrowerInfo.count)"
        
        likeClicked.onNext(post.id)
        priceLabel.text = "\(post.price)"
        longPeriodLabel.text = post.rentalType
        
        likeButton.rx.tap
            .subscribe(onNext: {[weak self] _ in
                self?.likeClicked.onNext(post.id)
            }).disposed(by: disposeBag)
        
        if post.likes.contains(where: {$0 == user.id}) {
            likeImageView.tintColor = #colorLiteral(red: 0.8980392157, green: 0.2745098039, blue: 0.2745098039, alpha: 1)
            likeLabel.textColor = #colorLiteral(red: 0.8980392157, green: 0.2745098039, blue: 0.2745098039, alpha: 1)
        }
        else {
            likeImageView.tintColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.5960784314, alpha: 1)
            likeLabel.textColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.5960784314, alpha: 1)
            
        }
        
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentImageView.image = nil
        disposeBag = DisposeBag()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 먼저, 버튼의 좌표계로 변환하여 터치 위치가 버튼 내부에 있는지 확인
        let pointForTarget = likeButton.convert(point, from: self)
        if likeButton.bounds.contains(pointForTarget) {
            return likeButton.hitTest(pointForTarget, with: event)
        }
        // 그렇지 않으면 기본 동작 수행
        return super.hitTest(point, with: event)
    }
    
}
