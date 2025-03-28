//
//  RoomCell.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//

import UIKit
import Reusable
import Kingfisher

class RoomCell: UITableViewCell, NibReusable {
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var unreadCountLabel: UILabel!
    @IBOutlet weak var unreadView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var noticeImageView: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        unreadView.layer.cornerRadius = 10
        profileImageView.layer.cornerRadius = 26
        // Initialization code
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil
        profileImageView.backgroundColor = .init(red: 243/255, green: 244/255, blue: 245/255, alpha: 1)
    }
    
    func bind(_ room: Room ) {
        
        
        if room.lastMessage.content.isEmpty {
            dateLabel.isHidden = true
        }
        else{
            dateLabel.isHidden = false
            dateLabel.text = DateConverter.dateToString(string: room.lastMessage.date)
            contentLabel.text = room.lastMessage.content
        }
        nicknameLabel.text = room.content
        unreadView.isHidden = room.unreadCount <= 0
        if room.unreadCount < 1000{
            unreadCountLabel.text = "\(room.unreadCount)"
        }
        else {
            unreadCountLabel.text = "999+"
        }
        if room.lastMessage.containMention {
            unreadCountLabel.text = "@ " + (unreadCountLabel.text ?? "1")
        }
        noticeImageView.image = room.notificationStatus ?  UIImage(named: "notification_on") : UIImage(named: "notification_off")
        if let imageStr = room.image {
            if let url = URL(string: imageStr) {
                profileImageView.kf.setImage(with: url)
            }
            else if let image = UIImage(named: imageStr) {
                profileImageView.image = image
            }
            else{
                profileImageView.image = UIImage(resource: .iconMan)
            }
        }
        else{
            profileImageView.image = UIImage(resource: .iconMan)
        }
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            guard let self = self else {return}
            self.transform = CGAffineTransform(scaleX: self.isHighlighted ? 0.95 : 1, y: self.isHighlighted ? 0.95 : 1)
        }, completion: nil)
    }
    
}
