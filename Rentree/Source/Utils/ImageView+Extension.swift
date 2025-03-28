//
//  ImageView+Extension.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//
import Foundation
import UIKit
import Alamofire
import RxCocoa
import RxSwift
import ReactorKit
import LinkPresentation
import ImageViewer_swift
import Photos
import Kingfisher
import RxDataSources
import Reusable

extension UIImageView: ImageProvider {
    public func setImage(url:String,imageView:UIImageView,ratio: @escaping (CGFloat) -> ()) {
        if let url = URL(string: url) {
            imageView.kf.setImage(with: url,options: [
                .transition(.fade(0.2)),
                .cacheMemoryOnly
            ]) { result in
                switch result{
                case .success(let data):
                    print("이미지 불러옴!")
                    ratio(data.image.size.height/data.image.size.width)
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    func setImage(urlString:String,
                  initialIndex:Int,
                  imageURLs:[String],
                  imageViewSize:CGSize? = nil,
                  completion:((UIImage?) -> Void)? = nil,
                  vc: UIViewController? = nil,
                  datasource:ImageDataSource? = nil,
                  downloadAble: Bool = true
    ){
        guard let url = URL(string: urlString) else {return}
        var options:[KingfisherOptionsInfoItem] = []
        if url.absoluteString.hasSuffix(".gif"){
            options.append(.onlyLoadFirstFrame)
        }
        if let size = imageViewSize{
            let scale = UIScreen.main.scale
            let sizeFromScale = CGSize(width: size.width * scale, height: size.height * scale)
            options.append(contentsOf:[
                .processor(DownsamplingImageProcessor(size: sizeFromScale))
            ])
        }
        else{
            options.append(.cacheOriginalImage)
        }
        options.append(contentsOf: [
            .backgroundDecode,
            .transition(.fade(0.1)),
        ])
        
        
        let images = imageURLs.compactMap({ string in
            return URL(string: string)
        })
        var option = [ImageViewerOption]()
        if downloadAble {
            option = [.theme(.dark),self.getImageDownloadOption(urls: images)]
        }
        else {
            option = [.theme(.dark)]
        }
        
        self.kf.setImage(
            with: url,
            options: options) { [weak self] result in
                guard let self = self else {return}
                switch result{
                case .success(let imageResult):
                    
                    
                    if let datasource{
                        self.setupImageViewer(datasource: datasource, initialIndex: initialIndex, options: option, from: vc, imageProvider: self)
                    }
                    else{
                        self.setupImageViewer(urls: images,initialIndex: initialIndex,options: option, placeholder: imageResult.image,from: vc, imageProvider: self)
                    }
                    
                    completion?(imageResult.image)
                case .failure(let error):
                    print(error)
                    completion?(nil)
                }
            }
        if let datasource{
            setupImageViewer(datasource: datasource, initialIndex: initialIndex, options: option, from: vc, imageProvider: self)
        }
        else{
            setupImageViewer(urls: images, initialIndex: initialIndex, options: option, from: vc, imageProvider: self)
        }
        
    }
    func setImage(data:Data){
        guard let image = UIImage(data: data) else {return}
        self.image = UIImage(data: data)
        setupImageViewer(images: [image],options: [.theme(.dark)], imageProvider: nil)
    }
    func getImageDownloadOption(urls: [URL]) -> ImageViewerOption{
        return ImageViewerOption.rightNavItemIcon(UIImage(systemName: "square.and.arrow.down", withConfiguration: UIImage.SymbolConfiguration.init(weight: .semibold))!.withTintColor(.lightGray,renderingMode: .alwaysOriginal)) { index,vc in
            PHPhotoLibrary.requestAuthorization(for: .addOnly){ authorizationStatus in
                switch authorizationStatus{
                case .limited,.authorized:
                    DispatchQueue.main.async {
                        let progressView = progressLoadingView(frame: CGRect(x: vc.view.frame.midX - 30, y: vc.view.frame.midY - 35, width: 60, height: 70))
                        vc.view.addSubview(progressView)
                        
                        AF.download(urls[index])
                        .downloadProgress {
                                progress in
                                progressView.setProgressWithAnimation(duration: 0.1, value: Float(progress.fractionCompleted))
                            }
                            .responseData { response in
                                if let data = response.value {
                                    if urls[index].absoluteString.hasSuffix(".gif"){
                                        PHPhotoLibrary.shared().performChanges ({
                                            let creationRequest = PHAssetCreationRequest.forAsset()
                                                       creationRequest.addResource(with: .photo, data: data, options: nil)
                                        }) { saved, error in
                                            if saved {
                                                DispatchQueue.main.async {
                                                    progressView.setProgressWithAnimation(duration: 0.1, value: 1)
                                                }
                                            }
                                        }
                                        
                                    }
                                    else{
                                        if let image = UIImage.sd_image(with: data){
                                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                                        }
                                    }
                                }
                            }
                    }
                default:
                    break
                }
            }
        }
    }
}


class progressLoadingView: UIView {
    fileprivate var progressLayer = CAShapeLayer()
    fileprivate var tracklayer = CAShapeLayer()
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    let progressLabel:UILabel = UILabel().then { label in
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .white
        label.text = "로드중.."

    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .black.withAlphaComponent(0.6)
        createCircularPath()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var progressColor:UIColor = UIColor.white.withAlphaComponent(1) {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
        }
    }
    
    var trackColor:UIColor = UIColor.white.withAlphaComponent(0.3) {
        didSet {
            tracklayer.strokeColor = trackColor.cgColor
        }
    }
    fileprivate func createCircularPath() {
//        self.backgroundColor = UIColor.clear
        self.addSubview(progressLabel)
        progressLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-3)
        }
        self.layer.cornerRadius = 6
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0 , y: (frame.size.height - 10.0) / 2.0),
                                      radius: (frame.size.width - 1.5)/2 - 10, startAngle: CGFloat(-0.5 * Double.pi),
                                      endAngle: CGFloat(1.5 * Double.pi), clockwise: true)
        
        tracklayer.path = circlePath.cgPath
        tracklayer.fillColor = UIColor.clear.cgColor
        tracklayer.strokeColor = trackColor.cgColor
        tracklayer.lineWidth = 3.0
        tracklayer.strokeEnd = 1.0
        layer.addSublayer(tracklayer)
        
        progressLayer.path = circlePath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = 3.0
        progressLayer.strokeEnd = 0.0
        layer.addSublayer(progressLayer)
    }
    var fromValue:Float = 0
    func setProgressWithAnimation(duration: TimeInterval, value: Float) {
        if progressLabel.text == "로드중.."{
            self.progressLabel.text = "\(Int(value*100))%"
        }
        else{
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: { [weak self] in
                self?.progressLabel.text = "\(Int(value*100))%"
            })
        }
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        // Animate from 0 (no circle) to 1 (full circle)
        animation.fromValue = fromValue
        animation.toValue = value
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        progressLayer.strokeEnd = CGFloat(value)
        progressLayer.add(animation, forKey: "animateCircle")
        fromValue = value
        if value == 1{
            UIView.animate(withDuration: 0.3, delay: duration, options: .curveEaseIn, animations: { [weak self] in
                self?.alpha = 0
            }, completion: { [weak self] _ in
                self?.isHidden = true
            })
        }
    }
    
}
