//
//  UnreadCell.swift
//  ChatAppTest
//
//  Created by 송준서 on 2023/02/28.
//

import UIKit

class UnreadCell: UITableViewCell {

    
    @IBOutlet weak var contentLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        self.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
