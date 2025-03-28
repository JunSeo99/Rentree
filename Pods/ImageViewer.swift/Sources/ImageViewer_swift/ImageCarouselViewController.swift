import UIKit
public protocol ImageDataSource:AnyObject {
    func numberOfImages() -> Int
    func imageItem(at index:Int) -> ImageItem
}
public protocol ImageProvider:AnyObject {
    func setImage(url:String, imageView:UIImageView, ratio: @escaping (CGFloat) -> ())
}
public class ImageCarouselViewController:UIPageViewController, ImageViewerTransitionViewControllerConvertible, UINavigationBarDelegate,ImageViewerDelegate,ImageProvider {
    deinit {
//        initialSourceView?.alpha = 1.0
        print("ImageCarouselViewController Deinit")
    }
    
    public func setImage(url:String,imageView:UIImageView,ratio: @escaping (CGFloat) -> ()) {
        imageProvider?.setImage(url: url, imageView: imageView, ratio: ratio)
    }
    
    unowned var initialSourceView: UIImageView?
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    func refreshSourceView(){
        guard let vc = viewControllers?.first as? ImageViewerController else {
            return
        }
//        if initialIndex != vc.index {
            if let newSourceView = imageIndexDelegate?.getImageView(index: vc.index), initialSourceView != nil{
                newSourceView.alpha = 0
                initialSourceView?.alpha = 1
                initialSourceView = newSourceView
            }
            else{
                initialSourceView?.alpha = 1
            }
//        }
//        else{
//            initialSourceView?.alpha = 0
//        }
    }
    var sourceView: UIImageView? {
        guard let vc = viewControllers?.first as? ImageViewerController else {
            return nil
        }
        refreshSourceView()
        if let imageView = imageIndexDelegate?.getImageView(index: vc.index){
            return imageView
        }
        return initialIndex == vc.index ? initialSourceView : imageIndexDelegate?.getImageView(index: vc.index)
    }
    
    var targetView: UIImageView? {
        guard let vc = viewControllers?.first as? ImageViewerController else {
            return nil
        }
        return vc.imageView
    }
    
    weak var imageDatasource:ImageDataSource?
 
    var initialIndex = 0
    
    var theme:ImageViewerTheme = .light {
        didSet {
//            navItem.leftBarButtonItem?.tintColor = theme.tintColor
            backgroundView?.backgroundColor = theme.color
        }
    }
    
    var options:[ImageViewerOption] = []
    weak var imageIndexDelegate:ImageCarouselDelegate?
    weak var imageProvider: ImageProvider?
    private var onRightNavBarTapped:((Int,ImageCarouselViewController) -> Void)?
    
    private(set) lazy var navBar:UINavigationBar = {
        let _navBar = UINavigationBar(frame: .zero)
        _navBar.isTranslucent = false
        if #available(iOS 13.0, *) {
//            _navBar.setBackgroundImage(UIImage().withTintColor(.clear), for: .default)
//            _nav
        } else {
            // Fallback on earlier versions
        }
//        _navBar.setBackgroundImage(UIImage(), for: .default)
//        _navBar.shadowImage = UIImage()
//        _navBar.backgroundColor = .black
//        _navBar.tintColor = .black
        return _navBar
    }()
    
    private(set) lazy var backgroundView:UIView? = {
        let _v = UIView()
        _v.backgroundColor = theme.color
        _v.alpha = 1.0
        return _v
    }()
    
    private(set) lazy var navItem = UINavigationItem()
    
    private let imageViewerPresentationDelegate = ImageViewerTransitionPresentationManager()
    
    public init(
        sourceView:UIImageView,
        imageDataSource: ImageDataSource?,
        options:[ImageViewerOption] = [],
        initialIndex:Int = 0,
        imageProvider: ImageProvider?) {
        self.initialSourceView = sourceView
        self.initialIndex = initialIndex
        self.options = options
        self.imageDatasource = imageDataSource
        self.imageProvider = imageProvider
        let pageOptions = [UIPageViewController.OptionsKey.interPageSpacing: 20]
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: pageOptions)
        
        transitioningDelegate = imageViewerPresentationDelegate
        modalPresentationStyle = .custom
        modalPresentationCapturesStatusBarAppearance = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addNavBar() {
        // Add Navigation Bar
        let closeBarButton = UIBarButtonItem(
            title: "",
            style: .plain,
            target: self,
            action: #selector(dismiss(_:)))
        if #available(iOS 13.0, *) {
            closeBarButton.image =  UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration.init(weight: .semibold))?.withTintColor(.lightGray,renderingMode: .alwaysOriginal)
//            closeBarButton.tintColor = .gray
            closeBarButton.imageInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0 )
        } else {
            // Fallback on earlier versions
        }
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
            navBar.standardAppearance = appearance
            navBar.scrollEdgeAppearance = navBar.standardAppearance
        }
//            // Fallback on earlier versions
//        }
       
        navItem.leftBarButtonItem = closeBarButton
//        navItem.leftBarButtonItem!.tintColor = .black
        navBar.delegate = self
        navBar.barTintColor = .white.withAlphaComponent(0.3)
//
        navBar.items = [navItem]
        navBar.insert(to: view)
        navBar.alpha = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: { [weak self] in
                self?.navBar.alpha = 1.0
            })
        })
        
    }
    
    private func addBackgroundView() {
        guard let backgroundView = backgroundView else { return }
        view.addSubview(backgroundView)
        backgroundView.bindFrameToSuperview()
        view.sendSubviewToBack(backgroundView)
    }
    
    private func applyOptions() {
        
        options.forEach {
            switch $0 {
                case .theme(let theme):
                    self.theme = theme
                case .closeIcon(let icon):
                    navItem.leftBarButtonItem?.image = icon
                case .rightNavItemTitle(let title, let onTap):
                    navItem.rightBarButtonItem = UIBarButtonItem(
                        title: title,
                        style: .plain,
                        target: self,
                        action: #selector(diTapRightNavBarItem(_:)))
                    onRightNavBarTapped = onTap
                case .rightNavItemIcon(let icon, let onTap):
                    navItem.rightBarButtonItem = UIBarButtonItem(
                        image: icon,
                        style: .plain,
                        target: self,
                        action: #selector(diTapRightNavBarItem(_:)))
                    onRightNavBarTapped = onTap
            }
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
//        self.resignFirstResponder()
        addBackgroundView()
        addNavBar()
        applyOptions()
//        (imageIndexDelegate as? UIViewController)?.setTabBarHidden(true,animated: true)
        dataSource = self

        if let imageDatasource = imageDatasource {
            let initialVC:ImageViewerController = .init(
                index: initialIndex,
                imageItem: imageDatasource.imageItem(at: initialIndex))
            initialVC.delegate = self
            initialVC.imageProvider = imageProvider
            setViewControllers([initialVC], direction: .forward, animated: true)
        }
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    @objc
    private func dismiss(_ sender:UIBarButtonItem) {
        dismissMe(completion: nil)
//        (imageIndexDelegate as? UIViewController)?.setTabBarHidden(false,animated: true)
    }
    
    public func dismissMe(completion: (() -> Void)? = nil) {
        sourceView?.alpha = 1.0
        
        UIView.animate(withDuration: 0.235, animations: {
            self.view.alpha = 0.0
        }) { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }
    
    
    @objc
    func diTapRightNavBarItem(_ sender:UIBarButtonItem) {

        guard let onTap = onRightNavBarTapped,
            let _firstVC = viewControllers?.first as? ImageViewerController
            else { return }
        onTap(_firstVC.index,self)
//        let url = _firstVC
//        let config = URLSessionConfiguration.default
//        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
//        session.downloadTask(with: url).resume()
    }
    
//    override public var preferredStatusBarStyle: UIStatusBarStyle {
//        if theme == .dark {
//            if #available(iOS 13.0, *) {
//                return .darkContent
//            } else {
//                // Fallback on earlier versions
//            }
//        }
//        return .default
//    }
}

extension ImageCarouselViewController:UIPageViewControllerDataSource {
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let vc = viewController as? ImageViewerController else { return nil }
        guard let imageDatasource = imageDatasource else { return nil }
        guard vc.index > 0 else { return nil }
 
        let newIndex = vc.index - 1
        let imageViewer = ImageViewerController.init(
            index: newIndex,
            imageItem: imageDatasource.imageItem(at: newIndex))
            imageViewer.delegate = self
            imageViewer.imageProvider = imageProvider
        return imageViewer
    }
    
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? ImageViewerController else { return nil }
        guard let imageDatasource = imageDatasource else { return nil }
        guard vc.index <= (imageDatasource.numberOfImages() - 2) else { return nil }
        let newIndex = vc.index + 1
        let imageViewer = ImageViewerController.init(
                index: newIndex,
                imageItem: imageDatasource.imageItem(at: newIndex))
        imageViewer.delegate = self
        imageViewer.imageProvider = imageProvider
        return imageViewer
    }
}
public protocol ImageCarouselDelegate: AnyObject{
    func getImageView(index:Int) -> UIImageView?
//    func getImage(url:String,imageView: UIImageView,ratio: @escaping (CGFloat) -> ())
}
