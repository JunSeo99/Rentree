//
//  MyPostUserCell.swift
//  Rentree
//
//  Created by jun on 3/28/25.
//

import UIKit
import Reusable
import Kingfisher

import RxSwift
import RxCocoa
import SnapKit

class MyPostUserCell: UITableViewCell, NibReusable {
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var questionMarkButton: UIButton!
    @IBOutlet weak var notiView: UIView!
//    @IBOutlet weak var progressMultiple: NSLayoutConstraint!
    @IBOutlet weak var treeImageView: UIImageView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressBackgroundView: UIView!
    static func calculateHeight(_ model: BorrowerInfo) -> CGFloat {
        var height: CGFloat = 16.0 + 15.0 + 10.0
        + 54.0
        + 48.0 + 16.0
        + 42.0 // 채팅 바로가기 까지
        + 12.0 // bottom inset
        // 기본 높이
        if model.state == 0 {
            
        }
        else if model.state == 1 {
            height += 46.0
        }
        else if model.state == 2 {
            height += 15.0 + UIScreen.main.bounds.width - 32.0
        }
        
        return height
    }
    
    
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var returnDateLabel: UILabel!
    @IBOutlet weak var rentInfoStackView: UIStackView!
    @IBOutlet weak var returnImageView: UIImageView!
    @IBOutlet weak var chatButton: UIButton!

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var schoolLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var returnedButton: UIButton!
    
//    @IBOutlet weak var indexLabel: UILabel!
    var goToChat: PublishSubject<Void> = .init()
    var returnBack: PublishSubject<Void> = .init()
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        returnImageView.layer.cornerRadius = 12
        profileImageView.layer.cornerRadius = 23
        chatButton.layer.borderWidth = 1
        chatButton.layer.borderColor = UIColor.jiuScheduleDefaultBorder.cgColor
        chatButton.layer.cornerRadius = 12
        returnedButton.layer.borderWidth = 1
        returnedButton.layer.cornerRadius = 12
        returnedButton.layer.borderColor = UIColor(resource: .jiuBlue).cgColor
        
        progressView.layer.cornerRadius = 4.5
        progressBackgroundView.layer.cornerRadius = 4.5
        
        notiView.layer.cornerRadius = 12
        notiView.layer.borderWidth = 1
        notiView.layer.borderColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1).cgColor
        notiView.layer.applySketchShadow(color: .init(red: 12/255, green: 12/255, blue: 13/255, alpha: 1), alpha: 0.1, x: 0, y: 4, blur: 8, spread: 0)
        notiView.alpha = 0
        
        
    }
    
    func bindUI(borrower: BorrowerInfo, indexText: String) {
        
        
        questionMarkButton.rx.tap
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                UIView.animate(withDuration: 0.23, delay: 0,options: .curveEaseInOut, animations: {
                    self.notiView.alpha = self.notiView.alpha == 1 ? 0 : 1
                    self.questionMarkButton.transform = self.notiView.alpha == 0 ? .identity : CGAffineTransform(scaleX: 0.8, y: 0.8)
                })
            }).disposed(by: disposeBag)
        
//        indexLabel.text = indexText
        
        if let name = borrower.name,
           let schoolCode = borrower.schoolCode,
           let mannerValue = borrower.mannerValue {
            nameLabel.text = name
            schoolLabel.text = schoolCode
            treeImageView.setTreeImage(mannerValue: mannerValue)
//            progressMultiple.isActive = false
            progressView.snp.makeConstraints { make in
                make.width.equalTo(progressBackgroundView.snp.width).multipliedBy(CGFloat(mannerValue) / 10)
            }
            progressBackgroundView.layoutIfNeeded()
        }
        if let image = borrower.profileImage, let url =  URL(string: image) {
            profileImageView.kf.setImage(with: url, options: [.transition(.fade(0.25))])
        }
        
        if let startDateString = borrower.startDate, let endDateString = borrower.endDate {
            rentInfoStackView.isHidden = false
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
//            else {
//                print("error: ???? date")
//            }
            
            if let endDate = inputFormatter.date(from: endDateString) {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.day], from: Date(), to: endDate)
                let diffDays = components.day ?? 2
                let formattedEndDate = "반납 \(diffDays + 1)일 전"
                
                returnDateLabel.text = formattedEndDate
            }
//            else {
//                print("error: ???? date")
//                rentInfoStackView.isHidden = true
//            }
        }
        else {
            rentInfoStackView.isHidden = true
        }
        
        chatButton.rx.tap
            .subscribe(onNext: {[weak self] _ in
                guard let self else { return }
                self.goToChat.onNext(())
            }).disposed(by: disposeBag)
        
        
        if borrower.state == 0 { // 채팅만 가능한 상태
            returnImageView.isHidden = true
            returnedButton.isHidden = true
            returnDateLabel.superview?.isHidden = true
            
        }
        else if borrower.state == 1 { // 렌트중인 상태
            returnImageView.isHidden = true
            returnedButton.isHidden = false
            returnDateLabel.superview?.isHidden = false
            
            returnedButton.rx.tap
                .subscribe(onNext: {[weak self] _ in
                    guard let self else { return }
                    self.returnBack.onNext(())
                }).disposed(by: disposeBag)
        }
        else if borrower.state == 2 { // 렌트가 종료된 상태
            returnDateLabel.superview?.isHidden = false
//            startDateLabel.isHidden = false
            returnImageView.isHidden = false
            returnedButton.isHidden = true
            if let image = borrower.returnImage?.first, let url =  URL(string: image) {
                returnImageView.kf.setImage(with: url, options: [.transition(.fade(0.25))])
            }
        }
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        returnImageView.image = nil
        profileImageView.image = nil
        self.notiView.alpha = 0
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
