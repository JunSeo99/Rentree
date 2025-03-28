import UIKit

public enum ImageViewerOption {
    case theme(ImageViewerTheme)
    case closeIcon(UIImage)
    case rightNavItemTitle(String, onTap: ((Int,ImageCarouselViewController) -> Void)?)
    case rightNavItemIcon(UIImage, onTap: ((Int,ImageCarouselViewController) -> Void)?)
}
