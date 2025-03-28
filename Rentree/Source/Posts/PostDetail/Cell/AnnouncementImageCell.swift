//
//  AnnouncementImageCell.swift
//  OurSchool
//
//  Created by jun on 7/1/24.
//

import UIKit
import Kingfisher
import Reusable

class AnnouncementImageCell: UICollectionViewCell, NibReusable{
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageWidth: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func bindUI(imageName: String) {
        guard let imageURL = URL(string: imageName) else { return }
        imageView.kf.setImage(with: imageURL, options: [.transition(.fade(0.25))])
        backgroundImageView.kf.setImage(with: imageURL, options: [.transition(.fade(0.25))]) {[weak self] result in
            guard let self else { return }
            switch result{
            case .success(let data):
                let imageSize = data.image.size
                let imageRatio = imageSize.height/imageSize.width
                if CGFloat(260)/UIScreen.main.bounds.width > imageRatio {
                    self.imageWidth.constant = UIScreen.main.bounds.width
                    self.imageView.contentMode = .scaleAspectFit
                }
                else{
                    self.imageWidth.constant = (1/imageRatio) * 260.0
                    self.imageView.contentMode = .scaleAspectFill
                }
                self.contentView.layoutIfNeeded()
            case .failure(let error):
                print(error)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        imageView.gestureRecognizers?.forEach({
            imageView.removeGestureRecognizer($0)
        })
        
    }
}
