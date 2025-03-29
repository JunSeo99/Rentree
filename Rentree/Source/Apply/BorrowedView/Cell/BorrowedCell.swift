//
//  BorrowedCell.swift
//  Rentree
//
//  Created by jun on 3/28/25.
//

import UIKit
import Reusable
import RxSwift
import RxCocoa

class BorrowedCell: UITableViewCell, NibReusable {
    @IBOutlet weak var rentalInfoStackView: UIStackView!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var returnDateLabel: UILabel!
    @IBOutlet weak var contentImageView: UIImageView!
//    @IBOutlet weak var dateLabel: UILabel!
//    @IBOutlet weak var sharedLabel: UILabel!
//    @IBOutlet weak var likeLabel: UILabel!
//    @IBOutlet weak var goToPostButton: UIButton!
    @IBOutlet weak var contentLabel: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
//    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var priceView: UIView!
//    @IBOutlet weak var seperatorView: UIView!
//    @IBOutlet weak var viewCountLabel: UILabel!
//    @IBOutlet weak var openButton: UIButton!
    
    @IBOutlet weak var chatButton: UIButton!
//    @IBOutlet weak var rentalButton: UIButton!
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var longPeriodLabel: UILabel!
    @IBOutlet weak var longPeriodView: UIView!
    var goToChat: PublishSubject<Void> = .init()
    var rental: PublishSubject<Void> = .init()
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
        
        chatButton.layer.borderWidth = 1
        chatButton.layer.borderColor = UIColor.jiuScheduleDefaultBorder.cgColor
        chatButton.layer.cornerRadius = 12
        
    }
    
    func bindUI(post: Post) {
        guard let borrowerInfo = post.borrowerInfo.first(where: {$0.userId == user.id}) else { return }
        
        chatButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.goToChat.onNext(())
            }).disposed(by: disposeBag)
        
        
        
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
        
//        if borrowerInfo.state == 0 { // 채팅 & 빌렸어요 버튼 가능
//            rentalButton.isHidden = false
//            rentalButton.rx.tap
//                .subscribe(onNext: { [weak self] _ in
//                    self?.rental.onNext(())
//                }).disposed(by: disposeBag)
//            
//        }
        if borrowerInfo.state == 1 { //빌리는중
            if let startDateString = borrowerInfo.startDate, let endDateString = borrowerInfo.endDate {
                let inputFormatter = DateFormatter()
                inputFormatter.locale = Locale(identifier: "ko_KR")
                inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                if let startDate = inputFormatter.date(from: startDateString) {
                    let outputFormatter = DateFormatter()
                    outputFormatter.locale = Locale(identifier: "ko_KR")
                    outputFormatter.dateFormat = "yy.MM.dd"
                    let formattedStartDate = outputFormatter.string(from: startDate) + " 렌트"
                    startDateLabel.text = formattedStartDate
                }
                
                if let endDate = inputFormatter.date(from: endDateString) {
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.day], from: Date(), to: endDate)
                    let diffDays = components.day ?? 2
                    let formattedEndDate = "반납 \(diffDays + 1)일 전"
                    
                    returnDateLabel.text = formattedEndDate
                }
            }
        }
        else if borrowerInfo.state == 2 {
            if let startDateString = borrowerInfo.startDate {
                let inputFormatter = DateFormatter()
                inputFormatter.locale = Locale(identifier: "ko_KR")
                inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                if let startDate = inputFormatter.date(from: startDateString) {
                    let outputFormatter = DateFormatter()
                    outputFormatter.locale = Locale(identifier: "ko_KR")
                    outputFormatter.dateFormat = "yy.MM.dd"
                    let formattedStartDate = outputFormatter.string(from: startDate) + " 렌트"
                    startDateLabel.text = formattedStartDate
                }
                
                returnDateLabel.text = "반납 완료"
            }
        }
        else {
            rentalInfoStackView.isHidden = true
        }
//        else if borrowerInfo.state == 2 { //반납 가능
//            rentalButton.isHidden = true
//            
//        }
        
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
        
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentImageView.image = nil
        disposeBag = DisposeBag()
    }
}
