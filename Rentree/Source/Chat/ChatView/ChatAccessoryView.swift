//
//  ChatAccessoryView.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//

import UIKit
import SnapKit
import RxKeyboard
import RxCocoa
import RxSwift
import Then

class ChatAccessoryView: UIView{
//    var mentionChanged: BehaviorSubject<Chat.Mention?> = .init(value: nil)
    var textViewHightChanged: BehaviorSubject<CGFloat> = .init(value: 44)
    var disposeBag:DisposeBag = DisposeBag()
    let chatStackView: UIStackView = UIStackView()
    let cameraButton: UIButton = UIButton()
    let sendButton: UIButton = UIButton()
    let textView: UITextView = UITextView()
    let mentionView: UIView = UIView().then { view in
        view.backgroundColor = .jiuDefualt
    }
    let mentionImageView: UIImageView = UIImageView().then { imageView in
        imageView.backgroundColor = .jiuItem3
        imageView.contentMode = .scaleToFill
    }
    let mentionCancelButton: UIButton = UIButton().then { button in
        button.setTitle("취소", for: .normal)
        button.setTitleColor(.jiuFont11, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
    }
    let mentionContentLabel: UILabel = UILabel().then {  label in
        label.text = ""
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .jiuFont11
    }
    let mentionNicknameLabel: UILabel = UILabel().then {  label in
        label.text = ""
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .messageMentionPurple2
    }
    private let mentionLineView: UIView = UIView().then { view in
        view.backgroundColor = .jiuItem3
    }
    private let mentionLabel: UILabel = UILabel().then { label in
        label.text = "에게 답장"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        traitCollection.performAsCurrent {
            chatStackView.layer.borderColor = UIColor.jiuChatViewBoarder.cgColor
        }
    }
    
    
    var didAddView = PublishSubject<Void>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        self.alpha = 0
        self.backgroundColor = .clear
        self.autoresizingMask = UIView.AutoresizingMask.flexibleHeight
        chatStackView.layer.cornerRadius = 22
        chatStackView.layer.borderWidth = 1
        chatStackView.layer.borderColor = UIColor.jiuChatViewBoarder.cgColor
        textView.font = .systemFont(ofSize: 16, weight: .regular)
        textView.backgroundColor = .clear
        textView.textColor = .jiuFontMain
        chatStackView.axis = .horizontal
        chatStackView.spacing = 9
        chatStackView.alignment = .bottom
        chatStackView.distribution = .fill
        chatStackView.layoutMargins = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        chatStackView.isLayoutMarginsRelativeArrangement = true
        chatStackView.backgroundColor = .jiuDefualt
       
        textView.isScrollEnabled = false
        let emptyView = UIView()
        emptyView.backgroundColor = .jiuDefualt
        self.addSubview(emptyView)
        
        self.addSubview(mentionView)
        mentionView.isHidden = true
//        self.addSubview(autoAskingView)
        cameraButton.setImage(UIImage(named: "camera"), for: .normal)
        cameraButton.layer.cornerRadius = 17
        sendButton.setBackgroundImage(UIImage(named: "Icon_Sending")?.withTintColor(UIColor(red: 111/255, green: 111/255, blue: 255/255, alpha: 1), renderingMode: .alwaysTemplate), for: .normal)
        sendButton.tintColor = UIColor(red: 111/255, green: 111/255, blue: 255/255, alpha: 1)
        sendButton.layer.cornerRadius = 17
        cameraButton.tintColor = .jiuCameraTint
        cameraButton.backgroundColor = .jiuCameraBackground
        self.addSubview(chatStackView)
        let sendButtonWrappingView = UIView()
        let cameraButtonWrappingView = UIView()
        sendButtonWrappingView.addSubview(sendButton)
        cameraButtonWrappingView.addSubview(cameraButton)
        sendButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.width.equalTo(34)
        }
        cameraButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.width.equalTo(34)
        }
        chatStackView.addArrangedSubview(cameraButtonWrappingView)
        chatStackView.addArrangedSubview(textView)
        chatStackView.addArrangedSubview(sendButtonWrappingView)
        cameraButtonWrappingView.snp.makeConstraints { make in
            make.height.equalTo(39)
        }
        sendButtonWrappingView.snp.makeConstraints { make in
            make.height.equalTo(39)
        }
        let height = " ".height(constraintedWidth: 1000, font: textView.font!)
        let inset = (44 - height)/2
        textView.textContainerInset = .init(top: inset, left: 0, bottom: inset, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        chatStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(7)
            make.height.greaterThanOrEqualTo(44)
            make.bottom.equalToSuperview().offset(-6)
        }
        emptyView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(29)
        }
        
        mentionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(emptyView)
//            make.top.equalToSuperview()
            make.top.equalTo(chatStackView).offset(-46)
        }
        
       
        
        
        mentionView.addSubview(mentionCancelButton)
        
//        mentionView.addSubview(mentionContentLabel)
//        mentionView.addSubview(mentionNicknameLabel)
        mentionView.addSubview(mentionLineView)
        mentionCancelButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-1)
            make.top.equalToSuperview().offset(5)
            make.width.equalTo(50)
            make.height.equalTo(35)
        }
        let mentionNicknameStackView = UIStackView()
        mentionNicknameStackView.spacing = 2
        mentionNicknameStackView.alignment = .fill
        mentionNicknameStackView.distribution = .fill
        mentionNicknameStackView.axis = .horizontal
        
        
        mentionNicknameStackView.addArrangedSubview(mentionNicknameLabel)
        mentionNicknameStackView.addArrangedSubview(mentionLabel)
        
        
        let mentionVerticalStackView = UIStackView()
        mentionVerticalStackView.spacing = 2
        mentionVerticalStackView.alignment = .leading
        mentionVerticalStackView.distribution = .fill
        mentionVerticalStackView.axis = .vertical
        
        mentionVerticalStackView.addArrangedSubview(mentionNicknameStackView)
        mentionVerticalStackView.addArrangedSubview(mentionContentLabel)
        
        let mentionStackView = UIStackView()
        mentionStackView.spacing = 8
        mentionStackView.alignment = .center
        mentionStackView.distribution = .fill
        mentionStackView.axis = .horizontal
        
        mentionStackView.addArrangedSubview(mentionImageView)
        mentionStackView.addArrangedSubview(mentionVerticalStackView)
        mentionView.addSubview(mentionStackView)
        mentionStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.top.equalToSuperview().offset(8)
            make.trailing.lessThanOrEqualTo(mentionCancelButton.snp.leading).offset(5)
        }
        mentionImageView.isHidden = true
        mentionImageView.clipsToBounds = true
        mentionImageView.snp.makeConstraints { make in
            make.height.width.equalTo(32)
        }
//        mentionContentLabel.snp.makeConstraints { make in
//            make.top.equalTo(mentionNicknameLabel.snp.bottom).offset(2)
//            make.leading.equalToSuperview().offset(15)
//            make.trailing.lessThanOrEqualTo(mentionCancelButton.snp.leading).offset(5)
//        }
//        mentionLabel.snp.makeConstraints { make in
//            make.leading.equalTo(mentionNicknameLabel.snp.trailing).offset(2)
//            make.trailing.lessThanOrEqualTo(mentionCancelButton.snp.leading).offset(5)
//            make.centerY.equalTo(mentionNicknameLabel)
//        }
//        mentionNicknameLabel.snp.makeConstraints { make in
//            make.top.equalToSuperview().offset(8)
//            make.leading.equalToSuperview().offset(15)
//        }
        mentionLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        mentionContentLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        mentionContentLabel.snp.makeConstraints { make in
//            make.leading.equalTo(mentionNicknameLabel)
//            make.top.equalTo(mentionNicknameLabel.snp.bottom).offset(2)
//        }
        mentionLineView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(1)
            make.leading.trailing.equalToSuperview()
        }
        
        sendButton.alpha = 0
        let font = textView.font ?? .systemFont(ofSize: 16, weight: .regular)
        let lineHeight = font.lineHeight
        textView.rx.text
            .orEmpty
            .observe(on: MainScheduler.instance)
            .skip(1)
            .distinctUntilChanged()
            .subscribe(onNext: {[weak self] text in
                guard let self = self else {return}
                let isAble = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let maxLineWidth = self.textView.frame.width
                let textSize = CGSize(width: maxLineWidth, height: .infinity)
                self.textView.snp.removeConstraints()
                let textHeight = text != "\n\n\n\n" ? self.textView.sizeThatFits(textSize).height - self.textView.textContainerInset.top - self.textView.textContainerInset.bottom : lineHeight * 4
                
                let line = Int(round(textHeight / lineHeight))
                if line <= 2{
                    self.textView.textContainerInset = .init(top: inset, left: 0, bottom: inset, right: 0)
                    self.textView.snp.updateConstraints { make in
                        make.height.equalTo(max(textHeight + inset * 2,44))
                    }
                    self.textView.isScrollEnabled = false
                    
                }
                else if line < 4{
                    self.textView.textContainerInset = .init(top: inset/2, left: 0, bottom: inset/2, right: 0)
                    self.textView.snp.updateConstraints { make in
                        make.height.equalTo(textHeight + inset)
                    }
                    self.textView.isScrollEnabled = false
                }
                else{
                    self.textView.textContainerInset = .init(top: 0, left: 0, bottom: 0, right: 0)
                    self.textView.snp.updateConstraints { make in
                        make.height.equalTo((self.textView.font ?? .systemFont(ofSize: 16, weight: .regular)).lineHeight * 4 )
                    }
                    self.textView.isScrollEnabled = true
                }
                self.sendButton.isEnabled = isAble
                UIView.performWithoutAnimation {
                    self.layoutIfNeeded()
                }
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                    self.sendButton.alpha = isAble ? 1 : 0
                })
                self.textViewHightChanged.onNext(self.textView.frame.height)
            }).disposed(by: disposeBag)
    }
    var height:CGFloat = 0
    override var intrinsicContentSize: CGSize {
        return .zero
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        didAddView.onNext(Void())
    }
    deinit{
        print("<inputView> Deinit")
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let convertedPoint = self.convert(point, to: mentionView)
        
        if mentionView.isHidden || convertedPoint.y >= 50 || convertedPoint.y <= 0 {
            return super.hitTest(point, with: event)
        }
        
        
        if mentionCancelButton.frame.contains(convertedPoint) {
            return mentionCancelButton
        }
        
        // mentionView 내부에서의 터치 이벤트 처리
        return mentionView
    }
}
