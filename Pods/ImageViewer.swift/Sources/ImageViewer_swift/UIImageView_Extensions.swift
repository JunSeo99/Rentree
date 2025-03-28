import UIKit
extension UIWindow {
    
    public var visibleViewController: UIViewController? {
        return self.visibleViewControllerFrom(vc: self.rootViewController)
    }
    
    /**
     # visibleViewControllerFrom
     - Author: suni
     - Date:
     - Parameters:
        - vc: rootViewController 혹은 UITapViewController
     - Returns: UIViewController?
     - Note: vc내에서 가장 최상위에 있는 뷰컨트롤러 반환
    */
    public func visibleViewControllerFrom(vc: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nc = vc as? UINavigationController {
            return self.visibleViewControllerFrom(vc: nc.visibleViewController)
        } else if let tc = vc as? UITabBarController {
            return self.visibleViewControllerFrom(vc: tc.selectedViewController)
        } else {
            if let pvc = vc?.presentedViewController {
                return self.visibleViewControllerFrom(vc: pvc)
            } else {
                return vc
            }
        }
    }
}
extension UIImageView {
    
    // Data holder tap recognizer
    private class TapWithDataRecognizer:UITapGestureRecognizer {
        weak var from: UIViewController?
        weak var imageProvider: ImageProvider?
        var imageDatasource: ImageDataSource?
        var initialIndex: Int = 0
        var options: [ImageViewerOption] = []
        deinit{
            print("TapWithDataRecognizer Deinit")
        }
        override init(target: Any?, action: Selector?) {
            super.init(target: target, action: action)
            print("TapWithDataRecognizer Init")
        }
    }
    
    private var vc:UIViewController? {
        guard let rootVC = UIApplication.shared.keyWindow?.visibleViewController
            else { return nil }
        return rootVC.presentedViewController != nil ? rootVC.presentedViewController : rootVC
    }
    
//    public func setupImageViewer(
//        options:[ImageViewerOption] = [],
//        from:UIViewController? = nil,
//        imageProvider: ImageProvider? = nil) {
//        setup(
//            datasource: SimpleImageDatasource(imageItems: [.image(image)]),
//            options: options,
//            from: from, imageProvider: imageProvider)
//    }
    
    #if canImport(SDWebImage)
    public func setupImageViewer(
        url:URL,
        initialIndex:Int = 0,
        placeholder: UIImage? = nil,
        options:[ImageViewerOption] = [],
        from:UIViewController? = nil,
        imageProvider: ImageProvider?) {
        
        let datasource = SimpleImageDatasource(
            imageItems: [url].enumerated().compactMap {
                ImageItem.url($1, placeholder: $0 == initialIndex ? placeholder : nil)
        })
        setup(
            datasource: datasource,
            initialIndex: initialIndex,
            options: options,
            from: from, imageProvider: imageProvider)
    }
    #endif
    
    public func setupImageViewer(
        images:[UIImage],
        initialIndex:Int = 0,
        options:[ImageViewerOption] = [],
        from:UIViewController? = nil,
        imageProvider: ImageProvider? ) {
        
        let datasource = SimpleImageDatasource(
            imageItems: images.compactMap {
                ImageItem.image($0)
        })
        setup(
            datasource: datasource,
            initialIndex: initialIndex,
            options: options,
            from: from, imageProvider: imageProvider)
    }
    
    #if canImport(SDWebImage)
    public func setupImageViewer(
        urls:[URL],
        initialIndex:Int = 0,
        options:[ImageViewerOption] = [],
        placeholder: UIImage? = nil,
        from:UIViewController? = nil,
        imageProvider: ImageProvider? = nil) {
        
        let datasource = SimpleImageDatasource(
            imageItems: urls.enumerated().compactMap {
                ImageItem.url($1, placeholder: $0 == initialIndex ? placeholder : nil)
        })
        setup(
            datasource: datasource,
            initialIndex: initialIndex,
            options: options,
            from: from, imageProvider: imageProvider)
    }
    #endif
    
    public func setupImageViewer(
        datasource:ImageDataSource,
        initialIndex:Int = 0,
        options:[ImageViewerOption] = [],
        from:UIViewController? = nil,
        imageProvider: ImageProvider?) {
        
        setup(
            datasource: datasource,
            initialIndex: initialIndex,
            options: options,
            from: from, imageProvider: imageProvider)
    }
    
    private func setup(
        datasource:ImageDataSource?,
        initialIndex:Int = 0,
        options:[ImageViewerOption] = [],
        from: UIViewController? = nil,
        imageProvider: ImageProvider?) {
        
        var _tapRecognizer:TapWithDataRecognizer?
        gestureRecognizers?.forEach {
            if let _tr = $0 as? TapWithDataRecognizer {
                // if found, just use existing
                _tapRecognizer = _tr
            }
        }
        
        isUserInteractionEnabled = true
        contentMode = .scaleAspectFill
        clipsToBounds = true
        
        if _tapRecognizer == nil {
            _tapRecognizer = TapWithDataRecognizer(
                target: self, action: #selector(showImageViewer(_:)))
            _tapRecognizer!.numberOfTouchesRequired = 1
            _tapRecognizer!.numberOfTapsRequired = 1
        }
        // Pass the Data
        _tapRecognizer!.imageDatasource = datasource
        _tapRecognizer!.initialIndex = initialIndex
        _tapRecognizer!.options = options
        _tapRecognizer!.from = from
        _tapRecognizer!.imageProvider = imageProvider
        addGestureRecognizer(_tapRecognizer!)
    }
    
    @objc
    private func showImageViewer(_ sender:TapWithDataRecognizer) {
        guard let sourceView = sender.view as? UIImageView else { return }
        let imageCarousel = ImageCarouselViewController.init(
            sourceView: sourceView,
            imageDataSource: sender.imageDatasource,
            options: sender.options,
            initialIndex: sender.initialIndex, imageProvider: sender.imageProvider)
        if let delegate = sender.from as? ImageCarouselDelegate{
            imageCarousel.imageIndexDelegate = delegate
        }
        else if let delegate = (vc?.view.subviews.filter({$0 is UITableView}).first as? UITableView)?.tableHeaderView as? ImageCarouselDelegate{
            imageCarousel.imageIndexDelegate = delegate
        }
        let presentFromVC = sender.from ?? vc
        presentFromVC?.present(imageCarousel, animated: true)
    }
}
extension UIViewController {

    func setTabBarHidden(_ hidden: Bool, animated: Bool = true, duration: TimeInterval = 0.3) {
        if animated {
            if let frame = self.tabBarController?.tabBar.frame {
                let factor: CGFloat = hidden ? 1 : -1
                let y = frame.origin.y + (frame.size.height * factor)
                UIView.animate(withDuration: duration, animations: {
                    self.tabBarController?.tabBar.frame = CGRect(x: frame.origin.x, y: y, width: frame.width, height: frame.height)
                })
                return
            }
        }
        self.tabBarController?.tabBar.isHidden = hidden
    }

}
