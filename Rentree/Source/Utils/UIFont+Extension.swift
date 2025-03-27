//
//  UIFont+Extension.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//

import UIKit

extension UILabel {
    func addTrailing(with trailingText: String, moreText: String, moreTextFont: UIFont, moreTextColor: UIColor) {
        let readMoreText: String = trailingText + moreText
        let lengthForVisibleString: Int = self.vissibleTextLength
        let mutableString: String = self.text!
        let trimmedString: String? = (mutableString as NSString).replacingCharacters(in: NSRange(location: lengthForVisibleString, length: ((self.text?.count)! - lengthForVisibleString)), with: "")
        let readMoreLength: Int = (readMoreText.count)
        let trimmedForReadMore: String = (trimmedString! as NSString).replacingCharacters(in: NSRange(location: ((trimmedString?.count ?? 0) - readMoreLength), length: readMoreLength), with: "") + trailingText
        let answerAttributed = NSMutableAttributedString(string: trimmedForReadMore, attributes: [NSAttributedString.Key.font: self.font!])
        let readMoreAttributed = NSMutableAttributedString(string: moreText, attributes: [NSAttributedString.Key.font: moreTextFont, NSAttributedString.Key.foregroundColor: moreTextColor])
        answerAttributed.append(readMoreAttributed)
        self.attributedText = answerAttributed
    }
    
    var vissibleTextLength: Int {
        let font: UIFont = self.font
        let mode: NSLineBreakMode = self.lineBreakMode
        let labelWidth: CGFloat = self.frame.size.width
        let labelHeight: CGFloat = self.frame.size.height
        let sizeConstraint = CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude)
        
        let attributes: [AnyHashable: Any] = [NSAttributedString.Key.font: font]
        let attributedText = NSAttributedString(string: self.text!, attributes: attributes as? [NSAttributedString.Key : Any])
        let boundingRect: CGRect = attributedText.boundingRect(with: sizeConstraint, options: .usesLineFragmentOrigin, context: nil)
        
        if boundingRect.size.height > labelHeight {
            var index: Int = 0
            var prev: Int = 0
            let characterSet = CharacterSet.whitespacesAndNewlines
            repeat {
                prev = index
                if mode == NSLineBreakMode.byCharWrapping {
                    index += 1
                } else {
                    index = (self.text! as NSString).rangeOfCharacter(from: characterSet, options: [], range: NSRange(location: index + 1, length: self.text!.count - index - 1)).location
                }
            } while index != NSNotFound && index < self.text!.count && (self.text! as NSString).substring(to: index).boundingRect(with: sizeConstraint, options: .usesLineFragmentOrigin, attributes: attributes as? [NSAttributedString.Key : Any], context: nil).size.height <= labelHeight
            return prev
        }
        return self.text!.count
    }
}
extension UIViewController{
    func presentAlert(title:String,content:String?,okAction:(()->())?,cancleAction:(()->())?,retryAction:(()->())? = nil){
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: content, preferredStyle: .alert)
            if okAction != nil{
                alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in //do what you want
                    okAction!()
                }))
            }
            if cancleAction != nil{
                alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { _ in //do what you want
                    cancleAction!()
                }))
            }
            if retryAction != nil{
                alert.addAction(UIAlertAction(title: "재시도", style: .default, handler: { _ in //do what you want
                    retryAction?()
                }))
            }
            self.present(alert, animated: true)
        }
    }
    
    func presentAlert(code:APIError,content:String? = nil,action1:(()->())? = nil,action2:(()->())? = nil,action3: (()-> ())? = nil){
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        switch code {
        case .failConnect,
                .failLogin,
                .failLoadPost,
                .failLoadCamera,
                .failLoadComment,
                .failLoadReply,
                .laterCertified,
                .successCertified,
                .blockReply,
                .blockComment,
                .scheduleLoadFail,
                .emptyContent,
                .shortOfVoteOption,
                .failFindUser,
                .successCertification,
                .hrAlreadyEndApplicant,
                .notCertification,
                .waitingCertification,
                .fullRoom,
                .roomForcedWithdrawal,
                .roomBroken,
                .alreadyForceWithdrawal,
                .waitingManagerChat:
                
            let alert = UIAlertController(title: code.rawValue, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            self.present(alert, animated: true)
        case .logoutAskAgain:
            let alert = UIAlertController(title: code.rawValue, message: nil, preferredStyle: isPhone ? .actionSheet : .alert)
//            alert.view.tintColor = .black
            alert.addAction(UIAlertAction(title: "로그아웃", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler:{ (UIAlertAction)in
                print("취소")
                action2?()
            }))
            self.present(alert, animated: true)
        case .removeAskAgain,
                .removeScheduleAsk,
                .changePassword,
                .loadScheduleAsk,
                .hrReportAskAgain,
                .hrBlockAskAgain:
            let alert = UIAlertController(title: code.rawValue, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)
        case .failSignUp:
            let alert = UIAlertController(title: code.rawValue, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "로그인하기", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            self.present(alert, animated: true)
        case .withdrawalAskAgain:
            let alert = UIAlertController(title: code.rawValue, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "회원 탈퇴", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "취소", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)
        case .none:
            return
        case .userLocationFail:
            let alert = UIAlertController(title: code.rawValue, message: "위치서비스를 사용할 수 없습니다.\n”설정 > 지금알바 > 위치”에서\n위치 서비스를 켜주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "설정에서 켜기", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)
        case .hrRegisterAlbaInfo:
            let alert = UIAlertController(title: "본인인증을 해주세요", message: "본인인증을 완료한 후 이용할 수 있어요", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            self.present(alert, animated: true)
        case .userLocationReducedAccuracy:
            let alert = UIAlertController(title: "지금알바에서 위치 설정 사용", message: "정확한 위치를 파악할 수 없습니다.\n”설정 > 지금알바 > 위치”에서\n정확한 위치 옵션을 켜주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "설정에서 켜기", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)
        case .failCertification2,
                .failCertification3,
                .failCertification4:
            let alert = UIAlertController(title: code.rawValue, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "인증하러 가기", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)
        case .sendFail:
            let alert = UIAlertController(title: code.rawValue, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "삭제", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "재전송", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)
        case .roomWithdrawalAskAgain:
            let alert = UIAlertController(title: "채팅방을 나가기", message: code.rawValue, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)
        case .gameOver:
            let alert = UIAlertController(title: code.rawValue, message: content ?? "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "계속하기", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "종료", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)
        case .hrTampAnnouncement:
            let alert = UIAlertController(title: "임시저장된 공고", message: code.rawValue, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "새로운 글쓰기", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "이어쓰기", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)
        case .hrManagerWithdrawal:
            let alert = UIAlertController(title: "회원 탈퇴", message: code.rawValue, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "취소", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)

        case .hrManagerLogout:
            let alert = UIAlertController(title: code.rawValue, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "취소", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)
            
        case .hrRemoveAnnouncement:
            let alert = UIAlertController(title: "공고를 삭제하시겠어요?", message: code.rawValue, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "취소", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)
            
        case .hrEndAnnouncement:
            let alert = UIAlertController(title: "공고를 마감하시겠어요?", message: code.rawValue, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            self.present(alert, animated: true)
        case .hrManagerOut:
            let alert = UIAlertController(title: "사장님이 채팅방에서 나갔습니다", message: code.rawValue, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "완료", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            self.present(alert, animated: true)
        case .hrUserOut:
            let alert = UIAlertController(title: "알바생이 채팅방에서 나갔습니다", message: code.rawValue, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "완료", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            self.present(alert, animated: true)
        case .hrManagerOutAskagain:
            let alert = UIAlertController(title: "채팅방 나가기", message: code.rawValue, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "취소", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)
        case .hrUserOutAskagain:
            let alert = UIAlertController(title: "채팅방 나가기", message: code.rawValue, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "취소", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)
        case .hrDeletedAnnouncement:
            let alert = UIAlertController(title: "삭제된 공고입니다", message: code.rawValue, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            self.present(alert, animated: true)
        case .roomHostWithdrawal:
            let alert = UIAlertController(title: code.rawValue, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "방장 넘기고 나가기", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "그냥 나갈게요", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { _ in //do what you want
                action3?()
            }))
            self.present(alert, animated: true)
            
        case .hrToDeleteCompany:
            let alert = UIAlertController(title: "가게 삭제", message: code.rawValue, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in //do what you want
                action1?()
            }))
            alert.addAction(UIAlertAction(title: "취소", style: .default, handler: { _ in //do what you want
                action2?()
            }))
            self.present(alert, animated: true)
        }
    }
    
}
enum APIError: String {
    case userLocationFail = "지금알바에서 위치 설정 사용"
    case userLocationReducedAccuracy = "지금알바에서 위치 설정 사용 "
    case shortOfVoteOption = "두 개 이상의 항목을 입력해주세요\n🥺"
    case failConnect = "인터넷 연결에 실패했어요\n😭" // 확인
    case failLogin = "전화번호와 비밀번호를 확인해주세요\n🥺"
    case failLoadPost = "게시물이 사라졌어요\n🤔"
    case failLoadComment = "댓글이 사라졌어요\n🤔"
    case failLoadReply = "답글이 사라졌어요\n🤔"
    case failLoadCamera = "카메라를 불러올 수 없어요\n😭"
    case emptyContent = "본문을 작성해주세요\n😤"
    case logoutAskAgain = "로그아웃 하실건가요?"
    case removeAskAgain = "삭제하시겠어요?\n😢"
    case failSignUp = "이미 지금알바 회원이네요! 😂\n로그인 후 이용해주세요."
//    case withdrawalAskAgain = "정말 탈퇴 하실건가요?\n😢"
    
    case roomForcedWithdrawal = "방에서 퇴장되었습니다. \n더 이상 이 채팅방을 이용하실 수 없습니다."
    case roomBroken = "비활성화된 채팅방입니다. \n더 이상 이 채팅방을 이용하실 수 없습니다."
    
    case failFindUser = "가입된 회원이 아니네요😂 \n 회원가입을 먼저 진행해 주세요. "
    case removeScheduleAsk = "마지막 교시의 시간표가 남아있어요!\n정말 삭제하시겠어요?"
    case loadScheduleAsk = "새로운 시간표를 불러오면 기존 시간표가 없어져요.\n변경하시겠어요?"
    case scheduleLoadFail = "시간표를 불러올 수 없어요.😢\n다른 기간을 선택해주세요!"
    case blockComment = "댓글을 게시할 수 없어요\n😢"
    case fullRoom = "채팅방 정원이 가득 찼어요\n😭"
    case blockReply = "답글을 게시할 수 없어요\n😢"
    case laterCertified = "나중에 꼭 해주실거죠?\n😢"
    case successCertified = "등록되었어요\n 재빨리 검토 후 알려드릴게요!😃"
    case changePassword = "사용자의 익명성을 위해 정보를 암호화 처리하고 있어요 \n 사용자 정보 재설정을 위해서는 본인인증이 다시 필요해요 😉"
    case withdrawalAskAgain = "정말 탈퇴 하실건가요? 😢 \n 우린 항상 함께할거라 생각했는데... \n 14일이내에 돌아오시면 다시 사용 가능해요."
    case successCertification = "인증이 완료되었어요!\n🎉🥳🎉"
    case failCertification2 = "학생증 사진이 아닌 것 같아요 😂"
    case failCertification3 = "학생증 사진이 명확하지 않아요 😢"
    case failCertification4 = "필요한 정보가 기재되어 있지 않아요 😢"
    
    case sendFail = "전송에 실패하였습니다."
    case roomWithdrawalAskAgain = "채팅방을 나가면 대화내용이 모두 삭제되고 목록에서도 삭제됩니다."
    case roomHostWithdrawal = "방장이 방을 나갈 경우 방이 비활성화 됩니다."
    case none = ""
    case gameOver = "게임 종료"
    //HR
  
    case hrTampAnnouncement = "이전에 작성중인 공고가 있습니다.\n이어쓰시겠어요?"
    case hrManagerWithdrawal = "정말 탈퇴하시겠어요?\n탈퇴하면 작성하신 공고들이 모두 삭제됩니다."
    case hrManagerLogout = "로그아웃하시겠어요?"
    case hrRemoveAnnouncement = "삭제하시면 더 이상\n이 공고가 노출되지 않습니다."
    case hrEndAnnouncement = "공고를 마감하시면\n새로운 지원을 받을 수 없습니다"
    case hrManagerOut = "지원 절차가 종료되었습니다\n새로운 공고에 지원해주세요"
    case hrUserOut = "채용 절차가 종료되었습니다"
    case hrManagerOutAskagain = "채팅방에서 나가면 해당 지원자의\n채용 절차가 종료됩니다"
    case hrUserOutAskagain = "채팅방에서 나가면 해당 공고의\n지원 절차가 종료됩니다"
    
    case hrDeletedAnnouncement = "이 공고를 더이상\n확인하실 수 없습니다."
    case hrReportAskAgain = "해당 공고를 신고하시겠습니까?"
    case hrBlockAskAgain = "차단하시겠습니까?"
    case hrAlreadyEndApplicant = "이미 종료된 채용입니다"
    case notCertification = "학교를 인증하고\n참여해봐요! 😉"
    case waitingCertification = "학생증이 확인되면 이용할 수 있어요\n조금만 더 기다려주세요 😉"
    case hrToDeleteCompany = "가게를 삭제하시겠습니까?"
    case alreadyForceWithdrawal = "이미 내보낸 사용자 입니다."
    
    case waitingManagerChat = "잠시만요!\n아직 사장님이 채팅을 시작하지 않았네요\n조금만 기다려주세요"
    
    case hrRegisterAlbaInfo = "본인인증을 완료한 후 이용할 수 있어요"
}
