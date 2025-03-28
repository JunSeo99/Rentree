import UIKit

#if canImport(Kingfisher)
import Kingfisher
#endif

#if canImport(SDWebImage)
import SDWebImage
#endif

class ImageViewerController:UIViewController,
UIGestureRecognizerDelegate {
    deinit {
        print("ImageViewerController Deinit")
        delegate = nil
        imageProvider = nil
    }
    var imageView: UIImageView = UIImageView(frame: .zero)
    var backgroundView:UIView? {
        guard let _parent = parent as? ImageCarouselViewController
            else { return nil}
        return _parent.backgroundView
    }
    
    var index:Int = 0
    var imageItem:ImageItem!
    weak var delegate:ImageViewerDelegate?
    weak var imageProvider: ImageProvider?
    var navBar:UINavigationBar? {
        guard let _parent = parent as? ImageCarouselViewController
            else { return nil}
        return _parent.navBar
    }
    
    // MARK: Layout Constraints
    private var top:NSLayoutConstraint!
    private var leading:NSLayoutConstraint!
    private var trailing:NSLayoutConstraint!
    private var bottom:NSLayoutConstraint!
    
    private var scrollView:UIScrollView!
    
    private var lastLocation:CGPoint = .zero
    private var isAnimating:Bool = false
    private var maxZoomScale:CGFloat = 1.0
    /// imageRatio height/width
    private var imageRatio:CGFloat = 1.0
//    var top
    init(
        index: Int,
        imageItem:ImageItem) {
        
        self.index = index
        self.imageItem = imageItem
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func loadView() {
        let view = UIView()
    
        view.backgroundColor = .clear
        self.view = view
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        view.addSubview(scrollView)
        scrollView.bindFrameToSuperview()
        scrollView.backgroundColor = .clear
        scrollView.addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        top = imageView.topAnchor.constraint(equalTo: scrollView.topAnchor)
        leading = imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
        trailing = scrollView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        bottom = scrollView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        top.isActive = true
        leading.isActive = true
        trailing.isActive = true
        bottom.isActive = true
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        switch imageItem {
        case .image(let img):
            imageView.image = img
            imageView.layoutIfNeeded()
        case .url(let url, let placeholder):
            imageView.image = placeholder
            if let imageProvider = imageProvider, !url.absoluteString.hasSuffix("gif"){
                imageProvider.setImage(url: url.absoluteString,
                                   imageView: imageView, ratio: {
                    [weak self] ratio in
                    DispatchQueue.main.async {
                        print(ratio)
                        self?.imageRatio = ratio
                        self?.imageView.layoutIfNeeded()
                        self?.layout()
                    }
                })
            }
            else{
                #if canImport(SDWebImage)
                imageView.sd_setImage(
                    with: url,
                    placeholderImage: placeholder,
                    options: [],
                    progress: nil) {[weak self] (img, err, type, url) in
                        DispatchQueue.main.async {
                            if let size = img?.size{
                                self?.imageRatio = size.height/size.width
                            }
                            self?.layout()
                            print("HIHI22")
                        }
                    }
                #endif
            }
        default:
            break
        }
        
        addGestureRecognizers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.refreshSourceView()
//        UIView.animate(withDuration: 0.4, delay: 0.2, options: .curveEaseIn, animations: {
//            self.navBar?.alpha = 1.0
//        }, completion: nil)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        self.navBar?.alpha = 1.0
    }
    
//    override func viewWillLayoutSubviews() {
//        super.viewWillLayoutSubviews()
//        DispatchQueue.main.async {[weak self] in
//            self?.layout()
//        }
//        
//    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
//        DispatchQueue.main.async {[weak self] in
            self.layout()
//        }

    }
    private func layout() {
        self.imageView.sizeToFit()
        updateConstraintsForSize(view.bounds.size)
        updateMinMaxZoomScaleForSize(view.bounds.size)
//        updateConstraintsForSize(view.bounds.size)
    }
    
    // MARK: Add Gesture Recognizers
    func addGestureRecognizers() {
        
        let panGesture = UIPanGestureRecognizer(
            target: self, action: #selector(didPan(_:)))
        panGesture.cancelsTouchesInView = false
        panGesture.delegate = self
        scrollView.addGestureRecognizer(panGesture)
        
        let pinchRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(didPinch(_:)))
        pinchRecognizer.numberOfTapsRequired = 1
        pinchRecognizer.numberOfTouchesRequired = 2
        scrollView.addGestureRecognizer(pinchRecognizer)
        
        let singleTapGesture = UITapGestureRecognizer(
            target: self, action: #selector(didSingleTap(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(singleTapGesture)
        
        let doubleTapRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(didDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(doubleTapRecognizer)
        
        singleTapGesture.require(toFail: doubleTapRecognizer)
    }
    
    @objc
    func didPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard
            isAnimating == false
            else { return }
        UIView.animate(withDuration: 0.235) {
            self.navBar?.alpha = 0
        }
        let container:UIView! = imageView
        if gestureRecognizer.state == .began {
            lastLocation = container.center
        }
        
        if gestureRecognizer.state != .cancelled {
            let translation: CGPoint = gestureRecognizer
                .translation(in: view)
            container.center = CGPoint(
                x: lastLocation.x + translation.x,
                y: lastLocation.y + translation.y)
        }
        let diffX = lastLocation.x - container.center.x
        let diffY = lastLocation.y - container.center.y
        backgroundView?.alpha = 1.0 - max(abs(diffY/lastLocation.y)*imageRatio,abs(diffX/lastLocation.x))
        if gestureRecognizer.state == .ended {
            if max(abs(diffY),abs(diffX)) > 120 {
                dismiss(animated: true)
            } else {
                executeCancelAnimation()
            }
        }
    }
    
    @objc
    func didPinch(_ recognizer: UITapGestureRecognizer) {
        print("pinch")
        UIView.animate(withDuration: 0.235) {
            self.navBar?.alpha = 0
        }
        var newZoomScale = scrollView.zoomScale / 1.5
        newZoomScale = max(newZoomScale, scrollView.minimumZoomScale)
        scrollView.setZoomScale(newZoomScale, animated: true)
    }
    
    @objc
    func didSingleTap(_ recognizer: UITapGestureRecognizer) {
        let currentNavAlpha = self.navBar?.alpha ?? 0.0
        UIView.animate(withDuration: 0.235) {
            self.navBar?.alpha = currentNavAlpha > 0.5 ? 0.0 : 1.0
        }
    }
    
    @objc
    func didDoubleTap(_ recognizer:UITapGestureRecognizer) {
        let pointInView = recognizer.location(in: imageView)
        zoomInOrOut(at: pointInView)
    }
    
    func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer) -> Bool {
            
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer
            else { return false }
            let velocity = panGesture.velocity(in: scrollView)
            let maxYContentOffset = scrollView.contentSize.height - view.frame.height
            //true 면 없어지는 pan 허용
            if abs(velocity.y) > abs(velocity.x){
                if velocity.y > 0{
                    return scrollView.contentOffset.y <= 0
                }
                else{
                    print(maxYContentOffset,imageView.image!.size.height)
                    return scrollView.contentOffset.y >= (maxYContentOffset - 1)
                }
            }
            else{
                return false
            }
        }
    
    
}

// MARK: Adjusting the dimensions
extension ImageViewerController {
    
    func updateMinMaxZoomScaleForSize(_ size: CGSize) {
        if #available(iOS 11.0, *) {
            let inset = (UIApplication.shared.windows.first?.safeAreaInsets ?? .zero)
            let targetSize = imageView.bounds.size
            print("test1:: 3\(targetSize)")
            if targetSize.width == 0 || targetSize.height == 0 {
                return
            }
            let minScale = min(
                size.width/targetSize.width,
                size.height/targetSize.height)
            if minScale == 0 {
                return
            }
            var maxScale = max(
                (size.width + 1.0) / targetSize.width,
                (size.height - inset.top*2 + 1.0) / targetSize.height)
            imageRatio = targetSize.height/targetSize.width
            if imageRatio >= 3{
                maxScale = max(
                    (size.width + 1.0) / targetSize.width,
                    ((size.height - inset.top - inset.bottom) + 1.0) / targetSize.height)
                scrollView.minimumZoomScale = maxScale
                scrollView.zoomScale = maxScale
                maxZoomScale = maxScale * 2
                scrollView.maximumZoomScale = maxZoomScale
                
            }
            else{
                scrollView.minimumZoomScale = minScale
                scrollView.zoomScale = minScale
                maxZoomScale = maxScale
                print("뭐냐?",minScale,size,targetSize)
                scrollView.maximumZoomScale = maxZoomScale * 2
            }
            scrollView.contentOffset.y = 0
        }
    }
    
    
    func zoomInOrOut(at point:CGPoint) {
        let newZoomScale = scrollView.zoomScale == scrollView.minimumZoomScale
            ? maxZoomScale : scrollView.minimumZoomScale
        let size = scrollView.bounds.size
        let w = size.width / newZoomScale
        let h = size.height / newZoomScale
        let x = point.x - (w * 0.5)
        let y = point.y - (h * 0.5)
        let rect = CGRect(x: x, y: y, width: w, height: h)
        scrollView.zoom(to: rect, animated: true)
    }
    
    func updateConstraintsForSize(_ size: CGSize) {
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else {return}
        print("현재 쓰레드:" , Thread.current)
            if #available(iOS 11.0, *) {
                let inset = (UIApplication.shared.windows.first?.safeAreaInsets ?? .zero)
                let yOffset = max(0, (size.height - self.imageView.frame.height) / 2)
                print("test1:: 2 ::\(self.imageRatio)")
                if self.imageRatio >= 3{
                    self.top.constant = yOffset + inset.top
                    self.scrollView.contentInset.bottom = inset.bottom
                }
                else{
                    
                    self.top.constant = yOffset
                    self.bottom.constant = yOffset
                }
                let xOffset = max(0, (size.width - self.imageView.frame.width) / 2)
                print("test 뭐야2 ?? \(xOffset)")
                self.leading.constant = xOffset
                self.trailing.constant = xOffset
                self.view.layoutIfNeeded()
            }
//        }
        
    }
    
}

// MARK: Animation Related stuff
extension ImageViewerController {
    
    private func executeCancelAnimation() {
        self.isAnimating = true
        if imageRatio < 3{
            UIView.animate(
                withDuration: 0.237,
                animations: {
                    self.navBar?.alpha = 1.0
                    self.imageView.center = self.lastLocation
                    self.backgroundView?.alpha = 1.0
                }) {[weak self] _ in
                    self?.isAnimating = false
                }
        }
        else{
            UIView.animate(
                withDuration: 0.237,
                animations: {
                    self.navBar?.alpha = 1.0
                    self.imageView.center = self.lastLocation
                    self.backgroundView?.alpha = 1.0
                }) {[weak self] _ in
                    self?.isAnimating = false
                }
        }
    }
}

extension ImageViewerController:UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.navBar?.alpha == 1{
            UIView.animate(withDuration: 0.235) {
                self.navBar?.alpha = 0
            }
        }
//        updateConstraintsForSize(view.bounds.size)
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
//        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
//        print("didZoom",offsetX,offsetY)
//        scrollView.contentInset = UIEdgeInsets(top: 0, left: offsetX, bottom: 0, right: 0)
        updateConstraintsForSize(view.bounds.size)
    }
}

protocol ImageViewerDelegate: AnyObject{
    func refreshSourceView()
   
}
