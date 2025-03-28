//
//  PostDetailView.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//

import UIKit
import SnapKit
import MapKit
import Then
import RxSwift
import RxCocoa
import Kingfisher
import Reusable
import ImageViewer_swift
import Moya

class PostDetailView: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var mapWrapperView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var sharedLabel: UILabel!
    @IBOutlet weak var likeLabel: UILabel!
    //    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var priceView: UIView!
    @IBOutlet weak var viewCountLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var longPeriodLabel: UILabel!
    @IBOutlet weak var longPeriodView: UIView!
    
    @IBOutlet weak var likeImageView: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    
    @IBOutlet weak var borrowButton: UIButton!
    
    var likeClicked: PublishSubject<String> = .init()
    
    
    var disposeBag = DisposeBag()
    
    var post: Post?
    
    var provider = MoyaProvider<API>()
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var schoolLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let post else { return }
        setUI(post: post)
    }
    
    func setUI(post: Post) {
        
        profileImageView.backgroundColor = .jiuItem3
        profileImageView.layer.cornerRadius = 28
        nameLabel.text = post.name
        schoolLabel.text = post.schoolCode
        
        
        
        borrowButton.layer.cornerRadius = 12
        borrowButton.layer.borderWidth = 1
        borrowButton.layer.applySketchShadow(color: .black.withAlphaComponent(0.16), alpha: 1, x: 0, y: 3, blur: 6, spread: 0)
        borrowButton.backgroundColor = UIColor(red: 198/255, green: 218/255, blue: 252/255, alpha: 1)
        borrowButton.layer.borderColor = UIColor(red: 57/255, green: 119/255, blue: 224/255, alpha: 1).cgColor
        borrowButton.setTitleColor( UIColor(red: 57/255, green: 119/255, blue: 224/255, alpha: 1), for: .normal)
        
        
        longPeriodView.layer.cornerRadius = 5
        priceView.layer.cornerRadius = 5
        
        self.edgesForExtendedLayout = .all
        self.extendedLayoutIncludesOpaqueBars = true
        scrollView.alwaysBounceVertical = true
//        navigationControllerReference = navigationController
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        
        guard let navigation = navigationController as? MainNavigationViewController else {return }
        navigation.settingBarColor(type: .clear)
        
        borrowButton.rx.tap
            .flatMap({[weak self] _  -> Observable<[String:JSONData]> in
                guard let self else {return .empty()}
                return self.provider.rx.request(.borrowing(postId: post.id, userId: user.id))
                    .map([String:JSONData].self)
                    .asObservable()
            })
            .subscribe(onNext: {[weak self] result in
                guard let self else {return }
                if case let .string(roomId) = result["roomId"] {
                    print("성공", roomId)
                }
            }).disposed(by: disposeBag)
        
        let mapView = PostMapView()
        mapView.bindUI(geoInfo: .init(activated: true, title: post.schoolCode, address: "" , point: .init(type: "Point", coordinates: post.geoInfo.coordinates)))
        
        mapWrapperView.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        self.titleLabel.text = post.title
        self.contentLabel.text = post.content
        self.dateLabel.text = DateConverter.dateToString(string: post.createdAt)
        
        viewCountLabel.text = "\(post.viewCount)"
        likeLabel.text = "\(post.likes.count)"
        sharedLabel.text = "\(post.borrowerInfo.count)"
        
        if post.rentalType == "무료" {
            priceLabel.text = "무료 대여"
            longPeriodLabel.text = post.priceByPeriod
        }
        else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            
            priceLabel.text = "\(formatter.string(from: NSNumber(value: post.price)) ?? "\(post.price)")원/\(post.priceByPeriod)"
            longPeriodLabel.text = post.rentalType
        }
//        likeButton.layer.zPosition = 10
        likeButton.rx.tap
            .subscribe(onNext: { _ in
                print("ㅜ머야")
            }).disposed(by: disposeBag)
        
        likeButton.rx.tap
            .subscribe(onNext: {[weak self] _ in
                self?.likeClicked.onNext(post.id)
            }).disposed(by: disposeBag)
        
        if post.likes.contains(where: {$0 == user.id}) {
            likeImageView.tintColor = #colorLiteral(red: 0.8980392157, green: 0.2745098039, blue: 0.2745098039, alpha: 1)
            likeLabel.textColor = #colorLiteral(red: 0.8980392157, green: 0.2745098039, blue: 0.2745098039, alpha: 1)
        }
        else {
            likeImageView.tintColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.5960784314, alpha: 1)
            likeLabel.textColor = #colorLiteral(red: 0.5960784314, green: 0.5960784314, blue: 0.5960784314, alpha: 1)
            
        }
        
        if post.photos.isEmpty {
            pageControl.isHidden = true
        }
        pageControl.numberOfPages = post.photos.count
        pageControl.currentPage = 0
        
        collectionView.register(cellType: AnnouncementImageCell.self)
        collectionView.isHidden = false
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}



extension PostDetailView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, ImageCarouselDelegate  {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let post else {return UICollectionViewCell() }
        let cell = collectionView.dequeueReusableCell(for: indexPath, cellType: AnnouncementImageCell.self)
        
        let images: [String] = post.photos
       
        
        
        
        let url = images[indexPath.row]
        cell.bindUI(imageName: url)
        cell.imageView.setImage(urlString: url, initialIndex: indexPath.item, imageURLs: images, completion: {[weak cell] image in
            guard let image else { return }
            let imageSize = image.size
            let imageRatio = imageSize.height/imageSize.width
            if CGFloat(260)/UIScreen.main.bounds.width > imageRatio {
                cell?.imageWidth.constant = UIScreen.main.bounds.width
                cell?.imageView.contentMode = .scaleAspectFit
            }
            else{
                cell?.imageWidth.constant = (1/imageRatio) * 260.0
                cell?.imageView.contentMode = .scaleAspectFill
            }
            cell?.contentView.layoutIfNeeded()
        }, vc: self)
        cell.backgroundImageView.kf.setImage(with: URL(string: url)!, options: [.transition(.fade(0.25))])
//        cell.cellSizeFix(count: images.count)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let post else {return 0}
        return post.photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: 260)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if collectionView.isHidden == true {
            return
        }
        let pageIndex = round(scrollView.contentOffset.x / scrollView.frame.width)
        pageControl.currentPage = Int(pageIndex)
        
        
        let translate = CGAffineTransformMakeTranslation(0, scrollView.contentOffset.y/2.0)
        let orgHeight: CGFloat = 260
        let scaleFactor = (orgHeight - scrollView.contentOffset.y) / orgHeight
        
        
        
        let translateAndZoom = CGAffineTransformScale(translate, scaleFactor, scaleFactor)
        
        
        let navBarHeight = navigationController?.navigationBar.frame.height ?? 44
        let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20
        let totalHeight = navBarHeight + statusBarHeight
        if scrollView.contentOffset.y > 0 {
            collectionView.transform = .identity
//            profileImageView.alpha = (orgHeight - scrollView.contentOffset.y)/orgHeight
        }
        else{
            collectionView.transform = translateAndZoom
        }
    }
    func getImageView(index: Int) -> UIImageView? {
        if let collectionView = collectionView {
            collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
            if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? AnnouncementImageCell{
                return cell.imageView
            }
        }
        return nil
    }
}
