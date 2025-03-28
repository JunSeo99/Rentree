//
//  SentCell.swift
//  ChatAppTest
//
//  Created by 송준서 on 2023/02/20.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
let displayWidth = UIScreen.main.bounds.width

class SentCell: UITableViewCell, UIContextMenuInteractionDelegate,MentionAbleChatCell {
    var isRemoved: Bool = false
    
    @IBOutlet weak var mentionView: UIView!
    //    var defaultMentionConstraint: CGFloat = 12
    @IBOutlet weak var mentionContentLabel: UILabel!
    @IBOutlet weak var mentionImageView: UIImageView!
    var id: String?
    @IBOutlet weak var mentionIconView: UIImageView!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var mentionNicknameLabel: UILabel!
    var removeClicked: PublishSubject<Void> = .init()
    var mentionClicked: PublishSubject<Void> = .init()
    func setMentionState(gap: CGFloat) -> CGFloat {
       
        DispatchQueue.main.async { [weak self] in
            guard let self,gap != 0 else {return}
            let newConstant = max(min(12 + gap, 72), 12)
            if self.leftConstraint.constant != newConstant {
                UIView.animate(withDuration: 0.05) {
                    self.leftConstraint.constant = newConstant
                    self.layoutIfNeeded()
                }
            }
            self.mentionIconView.alpha = gap / 60
        }
        if gap == 0{
            return 12
        }else{
            return max(min(12 + gap, 72),12)
        }
    }
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configuration: UIContextMenuConfiguration, highlightPreviewForItemWithIdentifier identifier: NSCopying) -> UITargetedPreview? {
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        parameters.shadowPath = .init()
        parameters.visiblePath = UIBezierPath(rect: chatStackView.bounds)
        return UITargetedPreview(view: chatStackView, parameters: parameters)
    }
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configuration: UIContextMenuConfiguration, dismissalPreviewForItemWithIdentifier identifier: NSCopying) -> UITargetedPreview? {
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        parameters.shadowPath = .init()
        parameters.visiblePath = UIBezierPath(rect: chatStackView.bounds)
        return UITargetedPreview(view: chatStackView, parameters: parameters)
    }
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: { () -> UIViewController? in
           return nil
        }) {[weak self] _ -> UIMenu? in
            return self?.menu
        }
    }
    
    
    @IBOutlet weak var chatStackView: UIStackView!
    @IBOutlet weak var menuButton: UIButton!
    static func calculatingCellHeight(_ chat:Chat) -> CGFloat{
        var defualt:CGFloat = 0
        if chat.isFirst == true{
           defualt = 6
        }
        var chat = chat
        if chat.removed == true {
            chat.content = "삭제된 메시지입니다."
            chat.mention = nil
            chat.image = nil
        }
        if chat.mention != nil {
            defualt += 50
        }
        if let image = chat.image{
            let imageMaxHeight = displayWidth - 125 - 12
            if image.height/image.width < 1{
                return imageMaxHeight * max(image.height/image.width , 4/5) + defualt + 6
            }
            return imageMaxHeight + defualt + 6
        }
        if chat.content.containsOnlyEmoji && chat.content.count < 4 && chat.mention == nil{
            if chat.content.count == 1{
                return 86 + defualt
            }else {
                return 66 + defualt
            }
        }
        let height = chat.content.height(withConstrainedWidth: displayWidth - 125 - 24 - 12, font: .systemFont(ofSize: 16, weight: .regular)) + 16 + 6 + defualt
        return height
    }
    var disposeBag = DisposeBag()
    @IBOutlet weak var resentButtonOption: UIButton!
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var failOptionStackView: UIStackView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var emojiStackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var emojiStackView: UIStackView!
    @IBOutlet weak var chatTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var unreadCountLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var chatView: UIView!
    @IBOutlet weak var chatLabel: UITextView!
    override func prepareForReuse() {
        super.prepareForReuse()
        emojiStackView.interactions.forEach{ interaction in
            emojiStackView.removeInteraction(interaction)
        }
        contentImageView.gestureRecognizers?.forEach({ gesture in
            contentImageView.removeGestureRecognizer(gesture)
        })
        chatStackView.interactions.forEach({ interaction in
            contentImageView.removeInteraction(interaction)
        })
        menu = nil
        contentImageView.image = nil
        emojiStackView.isHidden = true
        contentImageView.isHidden = true
        failOptionStackView.isHidden = true
        mentionView.isHidden = true
        disposeBag = DisposeBag()
        updateLayout()
        id = nil
    }
    func updateLayout(){
        setNeedsLayout()
        layoutIfNeeded()
    }

    var menu: UIMenu?
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        contentImageView.layer.cornerRadius = 13
        chatView.layer.cornerRadius = 13
        self.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        indicatorView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        failOptionStackView.layer.cornerRadius = 10
        emojiStackView.isHidden = true
        contentImageView.isHidden = true
        failOptionStackView.isHidden = true
        chatLabel.textContainer.lineBreakMode = .byWordWrapping
        chatLabel.textContainer.lineFragmentPadding = .zero
        chatLabel.textContainerInset = .init(top: 8, left: 12, bottom: 8, right: 12)
        chatLabel.linkTextAttributes = [
            .foregroundColor: UIColor.black
        ]
    }
    func bindUI(_ chat: Chat,dateConverter:ChatDateConverter,fail: Bool?,isHR: Bool = false,hiddenUnreadCount: Bool){
        id = chat.id
        isRemoved = chat.removed ?? false
        var chat = chat
        if chat.removed == true {
            chat.content = "삭제된 메시지입니다."
            chat.mention = nil
            chat.image = nil
            chatLabel.alpha = 0.3
        }
        else if chat.image == nil{
            chatLabel.alpha = 1
            let interaction = UIContextMenuInteraction(delegate: self)
            let paste = UIAction(title: "복사", handler: { _ in
                UIPasteboard.general.string = chat.content
            })
            paste.image = UIImage(systemName: "clipboard.fill")
            
            let remove = UIAction(title: "삭제", handler: {[weak self] _ in
                self?.removeClicked.onNext(Void())

            })
            
            let mention = UIAction(title: "답장", handler: {[weak self] _ in
                self?.mentionClicked.onNext(Void())
            })
            mention.image = UIImage(systemName: "arrowshape.turn.up.right.circle.fill")
            
            remove.image =  UIImage(systemName: "trash.fill")
            if isHR{
                let buttonMenu = UIMenu(title: "", children: [paste])
                menu = buttonMenu
            }
            else{
                let buttonMenu = UIMenu(title: "", children: [paste,remove,mention])
                menu = buttonMenu
            }
            if chat.content == "⚽️" {
//                chatStackView.addInteraction(interaction)
                //            menuButton.addInteraction(interaction)
                menuButton.isUserInteractionEnabled = true
            }
            else{
                chatStackView.addInteraction(interaction)
                //            menuButton.addInteraction(interaction)
                menuButton.isUserInteractionEnabled = false
            }
        }
        else if !isHR{
            chatLabel.alpha = 1
            let interaction = UIContextMenuInteraction(delegate: self)
            let remove = UIAction(title: "삭제", handler: {[weak self] _ in
                self?.removeClicked.onNext(Void())
//                UIPasteboard.general.string = chat.content
            })
            remove.image =  UIImage(systemName: "trash.fill")
           
            let buttonMenu = UIMenu(title: "", children: [remove])
            menu = buttonMenu
            contentImageView.addInteraction(interaction)
            
            if chat.content != "⚽️" {
                menuButton.isUserInteractionEnabled = false
            }
        }
        if let mention = chat.mention {
            mentionView.isHidden = false
            mentionContentLabel.text = mention.content
            if mention.userId == user.id {
                mentionNicknameLabel.text = "나"
            }
            else{
                mentionNicknameLabel.text = mention.name
            }
            
            if let image = mention.image {
                mentionImageView.isHidden = false
                mentionImageView.kf.setImage(with: URL(string: image))
            }
            else{
                mentionImageView.isHidden = true
            }
        }
        else{
            mentionView.isHidden = true
        }
        if let image = chat.image{
            self.contentImageView.snp.removeConstraints()
            self.contentImageView.isHidden = false
            self.chatView.isHidden = true
            emojiStackView.isHidden = true
            let imageMaxHeight = displayWidth - 125 - 12
            var height = imageMaxHeight
            var witdh = imageMaxHeight
            if image.height/image.width < 1{
                height = imageMaxHeight * max(image.height/image.width,4/5)
            }
            else{
                witdh = imageMaxHeight * max(image.width/image.height,4/5)
            }
            self.contentImageView.snp.makeConstraints { make in
                make.height.equalTo(height)
                make.width.equalTo(witdh)
            }
            if let data = image.data, let uiImage = UIImage(data: data){
                if !image.url.isEmpty, let _ = URL(string: image.url) {
                    contentImageView.image = uiImage
                    contentImageView.setImage(urlString: image.url, initialIndex: 0, imageURLs: [image.url])
                }
                else{
                    contentImageView.image = uiImage
                }
            }
            else{
                contentImageView.setImage(urlString: image.url, initialIndex: 0, imageURLs: [image.url])
            }
        }
        else if chat.content.containsOnlyEmoji && chat.content.count < 4 && chat.mention == nil{
            let imogeCount = (chat.content.count)
            contentImageView.isHidden = true
            emojiStackView.isHidden = false
            chatView.isHidden = true
            if imogeCount == 1 {
                emojiStackView.arrangedSubviews[0].isHidden = false
                emojiStackView.arrangedSubviews[1].isHidden = true
                emojiStackView.arrangedSubviews[2].isHidden = true
                emojiStackViewHeight.constant = 80
            }
            else if imogeCount == 2{
                emojiStackView.arrangedSubviews[0].isHidden = false
                emojiStackView.arrangedSubviews[1].isHidden = false
                emojiStackView.arrangedSubviews[2].isHidden = true
                emojiStackViewHeight.constant = 60
            }
            else{
                emojiStackView.arrangedSubviews[0].isHidden = false
                emojiStackView.arrangedSubviews[1].isHidden = false
                emojiStackView.arrangedSubviews[2].isHidden = false
                emojiStackViewHeight.constant = 60
            }
            for i in 0...(imogeCount - 1){
                if let label = emojiStackView.arrangedSubviews[i] as? UILabel{
                    label.text = chat.content.emojis[i].description
//                    label.sizeToFit()
                    label.baselineAdjustment = .alignCenters
                }
            }
            
        }
        else{
            contentImageView.isHidden = true
            emojiStackView.isHidden = true
            chatView.isHidden = false
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = NSLineBreakMode.byCharWrapping
            let i = NSMutableAttributedString(string: chat.content,
                                              attributes: [
                                                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                                                .foregroundColor: UIColor.black,
                                                .paragraphStyle: paragraphStyle
                                              ])
            if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
                let matches = detector.matches(in: chat.content, options: [], range: NSRange(location: 0, length: chat.content.utf16.count))
                matches.forEach { match in
                    guard let url = match.url else {return}
                    i.addAttributes([
                        NSAttributedString.Key.link: url,
                        NSAttributedString.Key.foregroundColor: UIColor.black,
                        NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
                            
                    ], range: match.range)
                }
                
            }
            chatLabel.attributedText = i
        }
        if let fail{
            if fail{
                dateLabel.isHidden = true
                failOptionStackView.isHidden = false
                indicatorView.isHidden = true
                indicatorView.stopAnimating()
            }
            else{
                dateLabel.isHidden = false
                indicatorView.isHidden = false
                indicatorView.startAnimating()
                failOptionStackView.isHidden = true
            }
            
        }
        else{
            dateLabel.isHidden = false
            failOptionStackView.isHidden = true
            indicatorView.isHidden = true
            indicatorView.stopAnimating()
        }
        if isHR{
            if chat.unreadCount > 0 {
                unreadCountLabel.isHidden = false
                unreadCountLabel.text = "안읽음"
            }
            else {
                unreadCountLabel.isHidden = true
            }
        }
        else if hiddenUnreadCount{
            unreadCountLabel.isHidden = true
        }
        else{
            unreadCountLabel.isHidden = chat.unreadCount <= 0
            unreadCountLabel.text = "\(chat.unreadCount)"
        }
        
        dateLabel.text = dateConverter.getDatePretty(formattedString: chat.createdAt, formatType: .shorts)
        if let isFirst = chat.isFirst,isFirst{
            chatTopConstraint.constant = 6
        }
        else{
            chatTopConstraint.constant = 0
        }
        updateLayout()
    }

}
