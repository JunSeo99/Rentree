//
//  RecivedCell.swift
//  ChatAppTest
//
//  Created by 송준서 on 2023/02/20.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher
import RxGesture
class RecivedCell: UITableViewCell, UIContextMenuInteractionDelegate, MentionAbleChatCell {
    var isRemoved: Bool = false
    
    @IBOutlet weak var mentionImageView: UIImageView!
    @IBOutlet weak var mentionContentLabel: UILabel!
    @IBOutlet weak var mentionNicknameLabel: UILabel!
    var defaultMentionConstraint: CGFloat = 16
    @IBOutlet weak var mentionView: UIView!
    @IBOutlet weak var mentionIconView: UIImageView!
    var mentionClicked: PublishSubject<Void> = .init()
    func setMentionState(gap: CGFloat) -> CGFloat {
       
        DispatchQueue.main.async { [weak self] in
            guard let self, gap != 0 else {return}
            let newConstant =  max(min(16 - gap, 16),-44)
            if self.leftConstraint.constant != newConstant {
                UIView.animate(withDuration: 0.05) {
                    self.leftConstraint.constant = newConstant
                    self.layoutIfNeeded()
                }
            }
            self.mentionIconView.alpha = gap/60
        }
        if gap == 0{
            return 16
        }
        else{
            return max(min(16 - gap, 16),-44)            
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
            return UIMenu(children: self?.menus ?? [])
        }
    }
        
    @IBOutlet weak var chatStackView: UIStackView!
    var disposeBag = DisposeBag()
    var blockClicked = PublishSubject<String>()
    var reportClicked = PublishSubject<Chat>()
    var id: String?
    static func calculatingCellHeight(_ chat: Chat) -> CGFloat {
        var nicknameHeight:CGFloat = 0
        if chat.isFirst == true{
            nicknameHeight = 22 + 6
        }
        var chat = chat
        if chat.removed == true {
            chat.content = "삭제된 메시지입니다."
            chat.mention = nil
            chat.image = nil
        }
        if chat.mention != nil {
            nicknameHeight += 50
        }
        if let image = chat.image{
            let imageMaxHeight = displayWidth - 66 - 58
            if image.height/image.width < 1{
                return imageMaxHeight * max(image.height/image.width,4/5)  + nicknameHeight + 6
            }
            return imageMaxHeight + nicknameHeight + 6
        }
        else if chat.content.containsOnlyEmoji && chat.content.count < 4 && chat.mention == nil {
            if chat.content.count == 1{
                return 86 + nicknameHeight
            }else {
                return 66 + nicknameHeight
            }
        }
        return chat.content.height(withConstrainedWidth: displayWidth - 66 - 58 - 24, font: .systemFont(ofSize: 16, weight: .regular)) + 16 + nicknameHeight + 6
    }
    func updateLayout(){
        setNeedsLayout()
        layoutIfNeeded()
    }
    @IBOutlet weak var stackViewTop: NSLayoutConstraint!
    @IBOutlet weak var chatTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var emojiStackView: UIStackView!
    @IBOutlet weak var EmojiStackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
//    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var unreadCountLabel: UILabel!
    @IBOutlet weak var chatView: UIView!
    @IBOutlet weak var chatLabel: UITextView!
   
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        
        emojiStackView.isHidden = true
        contentImageView.isHidden = true
        chatStackView.layer.cornerRadius = 13
//        chatStackView.clipsToBounds = true
        contentImageView.layer.cornerRadius = 13
        chatView.layer.cornerRadius = 13
        chatView.layer.borderColor = UIColor.jiuChatViewBoarder.cgColor
        chatView.layer.borderWidth = 1
        profileImageView.layer.cornerRadius = 16
        chatLabel.textContainer.lineBreakMode = .byCharWrapping
        chatLabel.textContainer.lineFragmentPadding = .zero
        chatLabel.textContainerInset = .init(top: 8, left: 12, bottom: 8, right: 12)
        chatLabel.dataDetectorTypes = .link
        chatLabel.linkTextAttributes = [
            .foregroundColor: UIColor.jiuFontMain
        ]
        
//        chatLabel.text
//        chatLabel.lineBreakMode = .byCharWrapping
//        chatStackView.layer.shadowColor = UIColor.clear.cgColor
//        chatStackView.layer.shadowOpacity = 0
        self.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        // Initialization code
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        traitCollection.performAsCurrent {
            chatView.layer.borderColor = UIColor.jiuChatViewBoarder.cgColor
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        id = nil
        emojiStackView.interactions.forEach{ interaction in
            emojiStackView.removeInteraction(interaction)
        }
        chatView.gestureRecognizers?.forEach{ interaction in
            chatView.removeGestureRecognizer(interaction)
        }
        chatStackView.interactions.forEach { interaction in
            chatStackView.removeInteraction(interaction)
        }
        contentImageView.interactions.forEach { interaction in
            contentImageView.removeInteraction(interaction)
        }
        contentImageView.gestureRecognizers?.forEach({ gesture in
            contentImageView.removeGestureRecognizer(gesture)
        })
        leftConstraint.constant = 16
        contentView.layoutIfNeeded()
        mentionIconView.alpha = 0
        contentImageView.image = nil
        profileImageView.image = nil
        menuButton.menu = nil
        profileImageView.backgroundColor = UIColor(red: 127/255, green: 127/255, blue: 127/255, alpha: 1)
        emojiStackView.isHidden = true
        contentImageView.isHidden = true
        mentionView.isHidden = true
//        updateLayout()
        disposeBag = DisposeBag()
        
    }
    var menus:[UIMenuElement] = []
    func setMenuButton(_ chat: Chat,isHost: Bool){
        menus = []
        if chat.image == nil{
            let paste = UIAction(title: "복사",image: UIImage(systemName: "clipboard.fill"), handler: { _ in
                UIPasteboard.general.string = chat.content
            })
            menus.append(paste)
        }
        let report = UIAction(title: "신고",image: UIImage(systemName: "light.beacon.max.fill"), handler: {
            [weak self] _ in
            self?.reportClicked.onNext(chat)
        })
        menus.append(report)
        let block = UIAction(title: isHost ? "강제 퇴장" : "차단",image: UIImage(systemName: "person.fill.xmark"),
                             handler: {[weak self] _ in
            self?.blockClicked.onNext(chat.userId)
        })
        menus.append(block)
        let mention = UIAction(title: "답장", handler: {[weak self] _ in
            self?.mentionClicked.onNext(Void())
        })
        mention.image = UIImage(systemName: "arrowshape.turn.up.right.circle.fill")
        menus.append(mention)
        if chat.image == nil{
            if chat.content == "⚽️" {
                menuButton.isUserInteractionEnabled = true
            }
            else{
                let interaction = UIContextMenuInteraction(delegate: self)
                //            let buttonMenu = UIMenu(title: "", children: menus)
                //            menuButton.menu = buttonMenu
                chatView.addInteraction(interaction)
                menuButton.isUserInteractionEnabled = false
            }
//            chatLabel.addInteraction(interaction)
//            chatStackView.addInteraction(interaction)
           
        }
        else{
            let interaction = UIContextMenuInteraction(delegate: self)
            contentImageView.addInteraction(interaction)
            contentImageView.isUserInteractionEnabled = true
            menuButton.isUserInteractionEnabled = false
        }
        
        

        
    }
    func bindUI(_ chat: Chat,dateConverter:ChatDateConverter,skipMenu: Bool = false,managerName: String? = nil,hiddenUnreadCount: Bool,hiddenSchool: Bool, roomHost: Bool = false){
        var chat = chat
        if chat.removed == true {
            chat.content = "삭제된 메시지입니다."
            chat.mention = nil
            chat.image = nil
            chatLabel.alpha = 0.3
            menus = []
        }
        else{
            chatLabel.alpha = 1
        }
        if !skipMenu && chat.removed != true{
            setMenuButton(chat,isHost: roomHost)
        }
        else if chat.image != nil{
            contentImageView.isUserInteractionEnabled = true
            menuButton.isUserInteractionEnabled = false
        }
        id = chat.id
        isRemoved = chat.removed ?? false
        if let mention = chat.mention {
            mentionView.isHidden = false
            mentionContentLabel.text = mention.content
          
            
            mentionNicknameLabel.text = mention.name
            
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
            let imageMaxHeight = displayWidth - 66 - 58
            var height = imageMaxHeight
            var witdh = imageMaxHeight
            if image.height/image.width < 1{
                height = imageMaxHeight * max(image.height/image.width,4/5)
            }
            else{
                witdh = imageMaxHeight *  max(image.width/image.height,4/5)
            }
            self.contentImageView.snp.makeConstraints { make in
                make.height.equalTo(height)
                make.width.equalTo(witdh)
            }
            contentImageView.setImage(urlString: image.url, initialIndex: 0, imageURLs: [image.url])
        }
        else if chat.content.containsOnlyEmoji && chat.content.count < 4 && chat.mention == nil{
            let imogeCount = (chat.content.count)
            emojiStackView.isHidden = false
            chatView.isHidden = true
            self.contentImageView.isHidden = true
            if imogeCount == 1 {
                emojiStackView.arrangedSubviews[0].isHidden = false
                emojiStackView.arrangedSubviews[1].isHidden = true
                emojiStackView.arrangedSubviews[2].isHidden = true
                EmojiStackViewHeight.constant = 80
            }
            else if imogeCount == 2{
                emojiStackView.arrangedSubviews[0].isHidden = false
                emojiStackView.arrangedSubviews[1].isHidden = false
                emojiStackView.arrangedSubviews[2].isHidden = true
                EmojiStackViewHeight.constant = 60
            }
            else{
                emojiStackView.arrangedSubviews[0].isHidden = false
                emojiStackView.arrangedSubviews[1].isHidden = false
                emojiStackView.arrangedSubviews[2].isHidden = false
                EmojiStackViewHeight.constant = 60
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
            self.contentImageView.isHidden = true
            emojiStackView.isHidden = true
            chatView.isHidden = false
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = NSLineBreakMode.byCharWrapping
            let i = NSMutableAttributedString(string: chat.content,attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .regular),.foregroundColor: UIColor.jiuFontMain,.paragraphStyle: paragraphStyle])
            if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
                let matches = detector.matches(in: chat.content, options: [], range: NSRange(location: 0, length: chat.content.utf16.count))
                matches.forEach { match in
                    guard let url = match.url else {return}
                    i.addAttributes([
                        NSAttributedString.Key.link: url,
                        NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
                    ], range: match.range)
                }
                
            }
            chatLabel.attributedText = i
//            chatLabel.text = chat.content
        }
        dateLabel.text = dateConverter.getDatePretty(formattedString: chat.createdAt, formatType: .shorts)
        if skipMenu {
            unreadCountLabel.isHidden = true
        }
        else if hiddenUnreadCount{
            unreadCountLabel.isHidden = true
        }
        else{
            unreadCountLabel.isHidden = chat.unreadCount <= 0
            unreadCountLabel.text = "\(chat.unreadCount)"
        }
        
        if let isFirst = chat.isFirst, isFirst{
            if let profile = chat.profileImage {
                profileImageView.kf.setImage(with: URL(string: profile)!)
                if let image = UIImage(named: profile){
                    profileImageView
                }
            }
            else{
                let image = chat.gender == 0 ? UIImage(resource: .iconWoman) : UIImage(resource: .iconMan)
                profileImageView.image = image.withRenderingMode(.alwaysTemplate)
                profileImageView.tintColor = .black
                profileImageView.backgroundColor = UIColor(red: 219/255, green: 219/255, blue: 219/255, alpha: 1)
            }
            nicknameLabel.isHidden = false
//            if hrUser != nil{
//                nicknameLabel.text = chat.nickname
//            }
            nicknameLabel.text = chat.name
            
            chatTopConstraint.constant = 6
            profileImageView.isHidden = false
            if stackViewTop.constant != 28{
                stackViewTop.constant = 28
                contentView.layoutIfNeeded()
//                updateLayout()
            }
        }
        else{
            nicknameLabel.isHidden = true
            chatTopConstraint.constant = 0
            profileImageView.isHidden = true
            profileImageView.image = nil
            if stackViewTop.constant != 0 {
                stackViewTop.constant = 0
                contentView.layoutIfNeeded()
            }
        }
//        UIView.performWithoutAnimation {
//            updateLayout()
//        }
    }
    func hasOnlyEmoji(string: String) -> Bool {
        
        for scalar in string.unicodeScalars {
            if !scalar.properties.isEmoji{
                return false
            }
        }
        return true
    }
    
}

