//
//  ImageViewerTransitionPresentationManager.swift
//  ImageViewer.swift
//
//  Created by Michael Henry Pantaleon on 2020/08/19.
//

import Foundation
import UIKit

protocol ImageViewerTransitionViewControllerConvertible {
    
    // The source view
    var sourceView: UIImageView? { get }
    
    // The final view
    var targetView: UIImageView? { get }
}

final class ImageViewerTransitionPresentationAnimator:NSObject {
    let isPresenting: Bool
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }
}

// MARK: - UIViewControllerAnimatedTransitioning
extension ImageViewerTransitionPresentationAnimator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?)
    -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key: UITransitionContextViewControllerKey = isPresenting ? .to : .from
        guard let controller = transitionContext.viewController(forKey: key),
              let rController = transitionContext.viewController(forKey: isPresenting ? .from : .to)
        else { return }
        
        let animationDuration = transitionDuration(using: transitionContext)
        
        if isPresenting {
//            rController.resignFirstResponder()
            presentAnimation(
                transitionView: transitionContext.containerView,
                controller: controller,
                duration: animationDuration) { finished in
                    transitionContext.completeTransition(finished)
                }
            
        } else {
//            rController.becomeFirstResponder()
            dismissAnimation(
                transitionView: transitionContext.containerView,
                controller: controller,
                duration: animationDuration) { finished in
                    transitionContext.completeTransition(finished)
                }
        }
    }
    
    private func createDummyImageView(frame: CGRect, image:UIImage? = nil)
    -> UIImageView {
        let dummyImageView:UIImageView = UIImageView(frame: frame)
        dummyImageView.clipsToBounds = true
        dummyImageView.contentMode = .scaleAspectFill
        dummyImageView.alpha = 1.0
        dummyImageView.image = image
        return dummyImageView
    }
    
    private func presentAnimation(
        transitionView:UIView,
        controller: UIViewController,
        duration: TimeInterval,
        completed: @escaping((Bool) -> Void)) {
            
            guard
                let transitionVC = controller as? ImageViewerTransitionViewControllerConvertible,
                let sourceView = transitionVC.sourceView
            else { return }
            
            sourceView.alpha = 0.0
            controller.view.alpha = 0.0
            transitionView.addSubview(controller.view)
            transitionVC.targetView?.alpha = 0.0
            if (sourceView.image?.size.height ?? 0)/(sourceView.image?.size.width ?? 1) >= 3{
                UIView.animate(withDuration: duration, animations: {
                    controller.view.alpha = 1.0
                    transitionVC.targetView?.alpha = 1.0
                }) { finished in
                    completed(finished)
                }
                return
            }
            
            let dummyImageView = createDummyImageView(
                frame: sourceView.frameRelativeToWindow(),
                image: sourceView.image)
            transitionView.addSubview(dummyImageView)
            var frame = UIScreen.main.bounds
            if let image = sourceView.image{
                let ratio = image.size.height/image.size.width
                if ratio >= 3{
                    frame.size.height = frame.size.width * ratio
                }
            }
            let navi = UINavigationBar()
            navi.sizeToFit()
            print("navi 높이",navi.frame.height)
            var naviHeight = navi.frame.height
            if #available(iOS 13.0, *) {
                naviHeight += (UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0)
            }
            if let size = sourceView.image?.size{
                let screenHeight = UIScreen.main.bounds.height
                let screenWitdh = UIScreen.main.bounds.width
                let imageRatio = size.height/size.width
                let imageWidth = screenHeight / imageRatio
                let imageHeight = screenWitdh * imageRatio
                let frame: CGRect =
                CGRect(x: max(screenWitdh - imageWidth, 0)/2,
                       y: max(screenHeight -  imageHeight, 0)/2,
                       width: min(screenWitdh, imageWidth),
                       height: min(screenHeight, imageHeight))
                UIView.animate(withDuration: duration, animations: {
                    dummyImageView.frame = frame
                    controller.view.alpha = 1.0
                }) { finished in
                    transitionVC.targetView?.alpha = 1.0
                    dummyImageView.removeFromSuperview()
                    completed(finished)
                }
            }
            else{
                dummyImageView.contentMode = .scaleAspectFit
                UIView.animate(withDuration: duration, animations: {
                    dummyImageView.frame = UIScreen.main.bounds
                    controller.view.alpha = 1.0
                }) { finished in
                    transitionVC.targetView?.alpha = 1.0
                    dummyImageView.removeFromSuperview()
                    completed(finished)
                }
            }
        }
    
    private func dismissAnimation(
        transitionView:UIView,
        controller: UIViewController,
        duration:TimeInterval,
        completed: @escaping((Bool) -> Void)) {
            
            guard
                let transitionVC = controller as? ImageViewerTransitionViewControllerConvertible
            else { return }
            
            let sourceView = transitionVC.sourceView
            let targetView = transitionVC.targetView
            
            let dummyImageView = createDummyImageView(
                frame: targetView?.frameRelativeToWindow() ?? UIScreen.main.bounds,
                image:  sourceView?.image)
            if let sourceView ,(sourceView.image?.size.height ?? 0)/(sourceView.image?.size.width ?? 1) >= 3{
                if dummyImageView.frame.origin.y < 0{
                    let diff = (dummyImageView.frame.size.height - dummyImageView.frame.size.width * 2)
                    dummyImageView.frame.origin.y += diff
                }
                dummyImageView.frame.size.height = dummyImageView.frame.size.width * 2
            }
            
            transitionView.addSubview(dummyImageView)
            targetView?.isHidden = true
            sourceView?.alpha = 0
            controller.view.alpha = 1.0
            
            
            UIView.animate(withDuration: duration, animations: {
                if let sourceView = sourceView {
                    // return to original position
                    dummyImageView.layer.cornerRadius = 7
                    dummyImageView.contentMode = sourceView.contentMode
                    dummyImageView.frame = sourceView.frameRelativeToWindow()
                } else {
                    // just disappear
                    dummyImageView.alpha = 0.0
                }
                controller.view.alpha = 0.0
            }) { finished in
                sourceView?.alpha = 1.0
//                sourceView?.isHidden = false
                controller.view.removeFromSuperview()
                completed(finished)
            }
        }
}

final class ImageViewerTransitionPresentationController: UIPresentationController {
    
    override var frameOfPresentedViewInContainerView: CGRect {
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController,
                          withParentContainerSize: containerView!.bounds.size)
        return frame
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}

final class ImageViewerTransitionPresentationManager: NSObject {
    
}

// MARK: - UIViewControllerTransitioningDelegate
extension ImageViewerTransitionPresentationManager: UIViewControllerTransitioningDelegate {
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let presentationController = ImageViewerTransitionPresentationController(
            presentedViewController: presented,
            presenting: presenting)
        return presentationController
    }
    
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        
        return ImageViewerTransitionPresentationAnimator(isPresenting: true)
    }
    
    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return ImageViewerTransitionPresentationAnimator(isPresenting: false)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ImageViewerTransitionPresentationManager: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        return .none
    }
    
    func presentationController(
        _ controller: UIPresentationController,
        viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle
    ) -> UIViewController? {
        return nil
    }
}
