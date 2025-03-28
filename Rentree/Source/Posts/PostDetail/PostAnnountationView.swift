//
//  PostAnnountationView.swift
//  Rentree
//
//  Created by jun on 3/28/25.
//


import Foundation
import UIKit
import MapKit
import RxSwift


final class PostPointAnnotation: MKPointAnnotation{
    var clusterIdentify:String = ""
    var viewType:ViewType = .blue
    enum ViewType{
        case red
        case blue
        case fillRedWithNumber
    }
//    override var hash: Int {
//        var hasher = Hasher()
//        hasher.combine(post?.id)
//        hasher.combine(clusterIdentify)
//        return hasher.finalize()
//    }
}
final class PostAnnotationView: MKAnnotationView {
    let titleLabel = UILabel()
    var disposeBag = DisposeBag()
    var isHiddenTitle = false
    internal override var annotation: MKAnnotation? {
        didSet {
            annotation.flatMap(configure(with:))
        }
    }
    func getMainAnnotation(annotation: MKAnnotation?) -> PostPointAnnotation?{
        if let annotation = annotation as? PostPointAnnotation {
            return annotation
        }
        else if let annotation = annotation as? MKClusterAnnotation{
            guard let postAnnotation = (annotation.memberAnnotations.first as? PostPointAnnotation) else{
                return nil
            }
            return postAnnotation
        }
        return nil
    }
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        let postAnnotation = getMainAnnotation(annotation: annotation)
        if postAnnotation?.viewType == .red || postAnnotation?.viewType == .fillRedWithNumber{
            displayPriority = .required
        }
        else{
            displayPriority = .defaultHigh
        }
        frame = CGRect(x: 0, y: 0, width: 26, height: 54)
        clipsToBounds = false
        
        self.layer.applySketchShadow(color: .black, alpha: 0.16, x: 0, y: 3, blur: 6, spread: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
private extension PostAnnotationView {
    func configure(with annotation: MKAnnotation) {
        self.subviews.forEach { view in
            if view is UILabel {
                view.removeFromSuperview()
            }
        }
        
        let annotationCount:Int = {
            guard let annotation = annotation as? MKClusterAnnotation else { return  1 }
            var result = true
            for index in 1..<annotation.memberAnnotations.count{
                if annotation.memberAnnotations[index].title != annotation.memberAnnotations[index - 1].title {
                    result = false
                    break
                }
            }
            if result{
               return 1
            }
            return annotation.memberAnnotations.count
        }()
        let realAnnotationCount:Int = {
            guard let annotation = annotation as? MKClusterAnnotation else { return  1 }
            return annotation.memberAnnotations.count
        }()
        var color =  UIColor(red: 229/255, green: 70/255, blue: 70/255, alpha: 1)
        let postAnnotation = getMainAnnotation(annotation: annotation)
        let width:CGFloat = 26
        if postAnnotation?.viewType == .red{
            displayPriority = .required
            color =  UIColor(red: 229/255, green: 70/255, blue: 70/255, alpha: 1)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: 54))
                image = renderer.image { _ in
                    if let image = UIImage(named: "icon_map")?.withTintColor(color) {
                        image.draw(in: .init(origin: .init(x: width/2 - 13, y: 0), size: .init(width: 26, height: 34)))
                    }
                }
        }
        else if postAnnotation?.viewType == .blue && postAnnotation?.clusterIdentify != "red"{
            displayPriority = .defaultHigh
            color = UIColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 1)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: 54))
                let count = realAnnotationCount
                image = renderer.image { _ in
                    if let image = UIImage(named: "icon_map_filled")?.withTintColor(color) {
                        image.draw(in: .init(origin: .init(x: width/2 - 13, y: 0), size: .init(width: 26, height: 34)))
                    }
                    let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .semibold)]
                    let text = "\(count)"
                    let size = text.size(withAttributes: attributes)
                    let rect = CGRect(x: (width - size.width) / 2, y: 5, width: size.width, height: size.height)
                    text.draw(in: rect, withAttributes: attributes)
                }
        }
        else{
            displayPriority = .required
            color =  UIColor(red: 229/255, green: 70/255, blue: 70/255, alpha: 1)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: 54))
            let count = realAnnotationCount
                image = renderer.image { _ in
                    if let image = UIImage(named: "icon_map_filled")?.withTintColor(color) {
                        image.draw(in: .init(origin: .init(x: width/2 - 13, y: 0), size: .init(width: 26, height: 34)))
                    }
                    let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .semibold)]
                    let text = "\(count)"
                    let size = text.size(withAttributes: attributes)
                    let rect = CGRect(x: (width - size.width) / 2, y: 5, width: size.width, height: size.height)
                    text.draw(in: rect, withAttributes: attributes)
                }
        }
        if annotationCount == 1 && !isHiddenTitle{
            let label = StrokeLabel()
            let attributes2: [NSAttributedString.Key : Any] = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                NSAttributedString.Key.foregroundColor: color,
            ]
            label.strokeSize = 3
            label.strokeColor = .white
            let attributeString = NSAttributedString(string: " \(postAnnotation?.title ?? "") ")
            let size2 = " \(postAnnotation?.title ?? "") ".size(withAttributes: attributes2)
            label.frame.origin.y = 39
            label.frame.origin.x = (width - size2.width)/2
            label.attributedText = attributeString.addingAttributes(attributes2)
            label.sizeToFit()
            label.frame.size.width += 4
            label.frame.size.height += 4
            self.addSubview(label)
        }
    }
}


class StrokeLabel: UILabel {
    var strokeSize: CGFloat = 0
    var strokeColor: UIColor = .clear
  
    override func drawText(in rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let textColor = self.textColor
        context?.setLineWidth(self.strokeSize)
        context?.setLineJoin(CGLineJoin.round)
        context?.setTextDrawingMode(CGTextDrawingMode.stroke)
        self.textColor = self.strokeColor
        super.drawText(in: rect)
        context?.setTextDrawingMode(.fill)
        self.textColor = textColor
        super.drawText(in: rect)
    }
}
public extension NSAttributedString {

    func addingAttributes(_ attributes: [NSAttributedString.Key : Any]) -> NSAttributedString {
        let copy = self.mutableCopy() as! NSMutableAttributedString
        copy.addAttributes(attributes)

        return copy.copy() as! NSAttributedString
    }
}
public extension NSMutableAttributedString {
    func addAttributes(_ attributes: [NSAttributedString.Key : Any]) {
        self.addAttributes(attributes, range: NSRange(location: 0, length: self.length))
    }

}
