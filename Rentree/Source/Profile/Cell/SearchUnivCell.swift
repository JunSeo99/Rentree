//
//  SearchUnivCell.swift
//  Rentree
//
//  Created by jun on 3/26/25.
//

import UIKit
import Reusable

class SearchUnivCell: UITableViewCell, NibReusable {

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var schoolNameLabel: UILabel!
    @IBOutlet weak var selectableImageView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        selectableImageView.layer.cornerRadius = 12
        selectableImageView.layer.borderWidth = 1
        selectableImageView.layer.borderColor = UIColor.jiuSchoolUnselected.cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected{
            selectableImageView.layer.borderColor = UIColor(red: 66/255, green: 132/255, blue: 244/255, alpha: 1).cgColor
            selectableImageView.backgroundColor = UIColor(red: 66/255, green: 132/255, blue: 244/255, alpha: 1)
        }
        else{
            selectableImageView.layer.borderColor = UIColor.jiuSchoolUnselected.cgColor
            selectableImageView.backgroundColor = .clear
        }
    }
    
}
