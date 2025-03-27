//
//  ProfileView.swift
//  Rentree
//
//  Created by jun on 3/25/25.
//

import UIKit
import RxSwift
import RxCocoa
import Moya
import Then
import SnapKit
import PhotosUI
import Kingfisher

class ProfileView: UIViewController {
    @IBOutlet weak var imageWidth: NSLayoutConstraint!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var blurEffectView: UIVisualEffectView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var schollName: UILabel!
    @IBOutlet weak var myItemButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var setUnivButton: UIButton!
    var navigationView: ProfileNavigationView?
    let provider: MoyaProvider<API> = .init()
    var disposeBag: DisposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.alwaysBounceVertical = true
        navigationController?.navigationController?.setNavigationBarHidden(true, animated: true)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        
        nicknameLabel.superview?.superview?.layer.cornerRadius = 18
        nicknameLabel.superview?.superview?.layer.borderWidth = 1
        nicknameLabel.superview?.superview?.layer.borderColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1).cgColor
        
        schollName.superview?.superview?.layer.cornerRadius = 18
        schollName.superview?.superview?.layer.borderWidth = 1
        schollName.superview?.superview?.layer.borderColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1).cgColor
        
        myItemButton.layer.cornerRadius = 18
        myItemButton.layer.borderWidth = 1
        myItemButton.layer.borderColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1).cgColor
        
        
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        
        
        setUnivButton.rx.tap
            .subscribe(
                onNext: { [weak self] _ in
                    guard let self else { return }
                    let vc = SearchUnivView(nibName: "SearchUnivView", bundle: nil)
                    vc.modalPresentationStyle = .overFullScreen
                    vc.modalTransitionStyle = .coverVertical
                    vc.provider = self.provider
                    self.present(vc, animated: true)
                    
                    vc.selected
                        .flatMap({ univ -> Observable<Univ> in
                            return self.provider.rx.request(.setUniv(userId: user.id, univName: univ.schoolName))
                                .asObservable()
                                .map({ _ in
                                    return univ
                                })
                        })
                        .subscribe(
                            onNext: { univ in
                                user.schoolCode = univ.schoolName
                                self.schollName.text = univ.schoolName
                            }).disposed(by: vc.disposeBag)
                    
                }).disposed(by: disposeBag)
        
        if let profileImage = user.profileImage, let url = URL(string: profileImage) {
            self.profileImageView.kf.setImage(with: url, options: [.transition(.fade(0.25))])
            self.backgroundImageView.kf.setImage(with: url, options: [.transition(.fade(0.25))])
        }
        
        
        var actions: [UIAction] = [UIAction]()
        let camera = UIAction(title: "카메라", handler: { [weak self] _ in
            guard let self = self else { return }
            AVCaptureDevice.requestAccess(for: .video, completionHandler: {(granted: Bool) in
                if granted {
                    DispatchQueue.main.async {
                        let camera = UIImagePickerController()
                        camera.sourceType = .camera
                        camera.allowsEditing = false
                        camera.cameraDevice = .rear
                        camera.cameraCaptureMode = .photo
                        camera.delegate = self
                        
                        self.present(camera, animated: true, completion: nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                            UIApplication.shared.open(appSettings)
                        }
                    }
                }
            })
        })
        
        actions.append(camera)
        let photo = UIAction(title: "사진", handler: { [weak self] _ in
            guard let self = self else { return }
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 1
            configuration.filter = .images
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        })
        actions.append(photo)
        
        let buttonMenu = UIMenu(title: "", children: actions)
        photo.image = UIImage.init(systemName: "photo.fill")
        camera.image = UIImage.init(systemName: "camera.fill")
        
        cameraButton.showsMenuAsPrimaryAction = true
        cameraButton.menu = buttonMenu
        
    }
    func uploadImage(data: Data) {
        provider.rx.request(.registerProfileImage(userId: user.id, profile: data))
            .filter(statusCode: 200)
            .mapString()
            .do(onError: {
                print($0)
            })
            .catchAndReturn("Error")
            .asObservable()
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { url in
                print(url)
                if let url = URL(string: url) {
                    self.profileImageView.kf.setImage(with: url, options: [.transition(.fade(0.25))])
                }
                
            }).disposed(by: disposeBag)
    }
    
    
}

extension ProfileView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView is UICollectionView){
            return
        }
        
        let translate = CGAffineTransformMakeTranslation(0, scrollView.contentOffset.y/2.0)
        let orgHeight: CGFloat = 260
        let scaleFactor = (orgHeight - scrollView.contentOffset.y) / orgHeight
        
        
        
        let translateAndZoom = CGAffineTransformScale(translate, scaleFactor, scaleFactor)
        
        
        let navBarHeight = navigationController?.navigationBar.frame.height ?? 44
        let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20
        let totalHeight = navBarHeight + statusBarHeight
        if scrollView.contentOffset.y > 0 {
            backgroundImageView.transform = .identity
            blurEffectView.transform = .identity
            profileImageView.alpha = (orgHeight - scrollView.contentOffset.y)/orgHeight
        }
        else{
            
            backgroundImageView.transform = translateAndZoom
            blurEffectView.transform = translateAndZoom
        }
        let yOffset = scrollView.contentOffset.y
        
        if yOffset > 260 {
            // 네비게이션 바를 보이도록 설정
            
            if navigationView != nil {
            }
            else{
                navigationView = .init(name: nicknameLabel.text ?? "")
                view.addSubview(navigationView!)
                nicknameLabel.isHidden = true
                navigationView?.frame = .init(x: 0, y: 0, width: view.frame.width, height: totalHeight)
                navigationView?.alpha = 0
                navigationView?.label.frame.origin.x = (navigationView!.frame.width - navigationView!.label.intrinsicContentSize.width)/2
                
                UIView.animate(withDuration: 0.25) {[weak self] in
                    self?.navigationView?.alpha = 1
                }
            }
            
        } else {
            // 네비게이션 바를 숨기도록 설정
            if let _ = navigationView {
                nicknameLabel.isHidden = false
                UIView.animate(withDuration: 0.25, animations: { [weak self] in
                    self?.navigationView?.alpha = 0
                }) {[weak self] _ in
                    self?.navigationView?.removeFromSuperview()
                    self?.navigationView = nil
                }
            }
        }
    }
}
class ProfileNavigationView: UIView {
    let label = UILabel().then { label in
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
    }
    //    let navigationBarHeight: CGFloat = .zero
    convenience init(name: String) {
        self.init(frame: .zero)
        //        self.navigationBarHeight = navigationBarHeight
        //        self.frame.height = navigationBarHeight
        label.text = name
        label.sizeToFit()
        //        label.frame.origin.x = (frame.width - label.intrinsicContentSize.width)/2
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .jiuNavigationBackground
        addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension ProfileView: PHPickerViewControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true,completion: { [weak self] in
            guard let self = self else {return}
//            self.reloadInputViews()
            if let result = results.first{
                result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, error in
                    //TODO:  - 에러처리 해야지
                    guard let data else {return}
                    if let image = UIImage(data: data){
                        DispatchQueue.main.async {
                            let resizer = ImageResizer()
                            resizer.imageResize(image: image)
                                .observe(on: MainScheduler.instance)
                                .subscribe(onNext:{ imageData in
                                    self.profileImageView.kf.setImage(with: .provider(RawImageDataProvider(data: imageData, cacheKey: UUID().uuidString)), options: [.transition(.fade(0.25))])
                                    self.backgroundImageView.kf.setImage(with: .provider(RawImageDataProvider(data: imageData, cacheKey: UUID().uuidString)), options: [.transition(.fade(0.25))])
                                    
                                    
                                    let imageSize = image.size
                                    let imageRatio = imageSize.height/imageSize.width
                                    
                                    if CGFloat(270)/UIScreen.main.bounds.width > imageRatio {
                                        self.imageWidth.constant = UIScreen.main.bounds.width
                                        self.profileImageView.contentMode = .scaleAspectFit
                                    }
                                    else{
                                        self.imageWidth.constant = (1/imageRatio) * 270.0
                                        self.profileImageView.contentMode = .scaleAspectFill
                                    }
                                    self.uploadImage(data: imageData)
                                }).disposed(by: self.disposeBag)
                        }
                    }
                }
            }
        })
    }
    
    
}
extension ProfileView: UIImagePickerControllerDelegate & UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: { [weak self] in
            guard let self = self else { return }
//            self.reloadInputViews()
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                let resizer = ImageResizer()
                resizer.imageResize(image: image)
                    .observe(on: MainScheduler.instance)
                    .subscribe(onNext:{ imageData in
                        self.profileImageView.kf.setImage(with: .provider(RawImageDataProvider(data: imageData, cacheKey: UUID().uuidString)), options: [.transition(.fade(0.25))])
                        self.backgroundImageView.kf.setImage(with: .provider(RawImageDataProvider(data: imageData, cacheKey: UUID().uuidString)), options: [.transition(.fade(0.25))])
                        let imageSize = image.size
                        let imageRatio = imageSize.height/imageSize.width
                        
                        if CGFloat(270)/UIScreen.main.bounds.width > imageRatio {
                            self.imageWidth.constant = UIScreen.main.bounds.width
                            self.profileImageView.contentMode = .scaleAspectFit
                        }
                        else{
                            self.imageWidth.constant = (1/imageRatio) * 270.0
                            self.profileImageView.contentMode = .scaleAspectFill
                        }
                        self.uploadImage(data: imageData)
                    }).disposed(by: self.disposeBag)
            }
        })
    }
}
