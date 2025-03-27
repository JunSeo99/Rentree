//
//  ImageResizer.swift
//  Rentree
//
//  Created by jun on 3/26/25.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import PhotosUI
//import SDWebImage
enum ResizeError:Error{
    case cantConvert
}

class ImageResizer{
    var compressionRatio:CGFloat = 1.0
    var minPixel:CGFloat = 1440
    init(compressionRatio: CGFloat = 1.0) {
        self.compressionRatio = compressionRatio
    }
    func imageResize(image: UIImage) -> Observable<Data> {
        let height = image.size.height
        let width = image.size.width
        let max = max(height, width)
        let min = min(height, width)
       
        if max/min >= 2.5 && max >= 3600{
            if max >= 50000{
                if let data = resize(image: image, scale: 25000/max)?.jpegData(compressionQuality: 0.7){
                    return .just(data)
                }
            }
            else {
                if let data = resize(image: image,scale: 0.5)?.jpegData(compressionQuality: compressionRatio){
                    return .just(data)
                }
            }
        }
        else{
            if min <= 1440{
                if let data = image.jpegData(compressionQuality: compressionRatio){
                    return .just(data)
                }
            }
            else{
                if let data = resize(image: image, scale: 1440/min)?.jpegData(compressionQuality: compressionRatio){
                    return .just(data)
                }
            }
        }
        return .error(ResizeError.cantConvert)
    }
    func imageResize(results: [PHPickerResult]) -> Observable<Data> {
       return Observable.from(results)
            .debug()
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .concatMap({ result -> Observable<UIImage?> in
                return Observable<UIImage?>.create { emitter in
                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                        if let url = url, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                            emitter.onNext(image)
                            emitter.onCompleted()
                        }
                    }
                    return Disposables.create()
                }
            })
            .debug()
            .flatMap({ [weak self] image -> Observable<Data> in
                guard let image, let self else {return .empty()}
                return self.imageResize(image: image)
            })
            .observe(on: MainScheduler.asyncInstance)
            .debug()
    }
    private func resize(image: UIImage, scale: CGFloat) -> UIImage?{
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let size = image.size.applying(transform)
        let newSize = CGSize(width: round(size.width), height: round(size.height))
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resultImage
    }
}
