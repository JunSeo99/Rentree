//
//  MentionAbleChat.swift
//  OurSchool
//
//  Created by jun on 2023/06/19.
//

import UIKit

protocol MentionAbleChatCell: UITableViewCell {
    var id: String? { get set }
    var isRemoved: Bool { get set }
    var mentionIconView: UIImageView! { get set }
    var leftConstraint: NSLayoutConstraint! { get set }
    func setMentionState(gap: CGFloat) -> CGFloat
}
