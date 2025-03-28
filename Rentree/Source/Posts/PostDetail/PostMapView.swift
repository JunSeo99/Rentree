//
//  PostMapView.swift
//  Rentree
//
//  Created by jun on 3/28/25.
//
import UIKit
import SnapKit
import MapKit
import Then
import RxSwift
import RxCocoa
class PostMapView:UIView{
    let mapView = MKMapView()
    let locationView = UIView().then { view in
        view.backgroundColor = .jiuBackground2
//        view.backgroundColor = .systemPink
//        view.layer.borderWidth = 1
//        view.layer.borderColor = UIColor.jiuButtonBorder.cgColor
//        view.layer.cornerRadius = 12
    }
    let titleLabel = UILabel().then { label in
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor.jiuFont8
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    let lineView = UIView().then { view in
        view.backgroundColor = .jiuBackground2
    }
    let subTitleLabel = UILabel().then { label in
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor.jiuFont8
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    let mapTouched = PublishSubject<Void>()
    var disposeBag = DisposeBag()
    let shapeLayer = CAShapeLayer()
    
//    var annotations = PublishSubject<[MKPointAnnotation]>()
    init(otherView:UIView? = nil){
        super.init(frame: .zero)
        
        self.clipsToBounds = true
        self.mapView.delegate = self
        self.mapView.register(PostAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
//        self.annotations.subscribe(onNext:{[weak self] annotations in
//            guard let self = self else {return}
//            annotations.forEach { annotation in
//                self.mapView.addAnnotation(annotation)
//            }
//            let annotation = annotations.first!
//            self.mapView.centerCoordinate = annotation.coordinate
//            let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
//            let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
//            self.mapView.setRegion(region, animated: true)
//        }).disposed(by: disposeBag)
        layer.cornerRadius = 12
//        mapView.layer.cornerRadius = 10
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isMultipleTouchEnabled = false
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.isUserInteractionEnabled = false
        addSubview(mapView)
        mapView.layer.zPosition = 1
        mapView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(134)
        }
//        addSubview(lineView)
//
       
//        lineView.snp.makeConstraints { make in
//            make.height.equalTo(1)
//            make.leading.trailing.equalToSuperview()
//            make.top.equalTo(mapView.snp.bottom)
//        }
        addSubview(locationView)
        locationView.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom)
            make.leading.bottom.trailing.equalToSuperview()
//            make.height.equalTo(59)
        }
        let stackView = UIStackView()
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subTitleLabel)
        stackView.spacing = 4
        locationView.addSubview(stackView)
        stackView.setContentCompressionResistancePriority(.init(996), for: .vertical)
        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20).priority(.init(995))
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
        let button = UIButton()
       
        button.rx.isHighlighted
            .subscribe(onNext:{ [weak self] isHighlighted in
                guard let self = self else {return}
                if isHighlighted{
                    UIView.animate(withDuration: 0.1) {
                        (otherView ?? self).transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                    }
                }
                else{
                    UIView.animate(withDuration: 0.3) {
                        (otherView ?? self).transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }
                }
            }).disposed(by: disposeBag)
        
        button.rx.tapGesture(configuration: { gesture, delegate in
            delegate.simultaneousRecognitionPolicy = .never
        })
        .asObservable()
        .map({_ in Void()})
        .bind(onNext: mapTouched.onNext(_:))
        .disposed(by: disposeBag)
        addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    func bindUI(geoInfo: GeoInfo2){
        if geoInfo.address == geoInfo.title{
            self.subTitleLabel.isHidden = true
        }
        else{
            self.subTitleLabel.isHidden = false
            self.subTitleLabel.text = geoInfo.address
        }
        self.titleLabel.isHidden = false
        self.titleLabel.text = geoInfo.title
        mapView.removeAnnotations(mapView.annotations)
        let annotation = PostPointAnnotation()
        annotation.viewType = .red
        annotation.coordinate = .init(latitude: geoInfo.point.coordinates[1], longitude: geoInfo.point.coordinates[0])
        annotation.title = geoInfo.title
        mapView.addAnnotation(annotation)
        mapView.centerCoordinate = annotation.coordinate
        let MAP_ZOOM_SCALE = 0.007
        let span = MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: MAP_ZOOM_SCALE)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
        let a = MKMapPoint(CLLocationCoordinate2DMake(
            region.center.latitude + region.span.latitudeDelta / 2,
            region.center.longitude - region.span.longitudeDelta / 2))
        let b = MKMapPoint(CLLocationCoordinate2DMake(
            region.center.latitude - region.span.latitudeDelta / 2,
            region.center.longitude + region.span.longitudeDelta / 2))
        let mapRect = MKMapRect(x: min(a.x,b.x), y: min(a.y,b.y), width: abs(a.x-b.x), height: abs(a.y-b.y))
        mapView.setVisibleMapRect(mapRect, edgePadding: .init(top: 0, left: -16, bottom: 0, right: -16), animated: false)
//        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath(roundedRect: locationView.bounds, byRoundingCorners: [.bottomLeft,.bottomRight], cornerRadii: CGSize(width: 12, height: 12))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        locationView.layer.mask = mask
        shapeLayer.frame = locationView.bounds
        shapeLayer.path = mask.path
        shapeLayer.lineWidth = 2
        shapeLayer.strokeColor = UIColor.jiuButtonBorder.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        if shapeLayer.superlayer == nil{
            locationView.layer.addSublayer(shapeLayer)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit{
        print("PostMapView Deinit")
    }
    
}
extension PostMapView: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation) as? PostAnnotationView
        view?.isHiddenTitle = true
        view?.clusteringIdentifier = "redAnnotation"
        return view
    }
}

extension Reactive where Base: UIButton {
    var isHighlighted: Observable<Bool> {
        let anyObservable = self.base.rx.methodInvoked(#selector(setter: self.base.isHighlighted))
        let boolObservable = anyObservable
            .flatMap { Observable.from(optional: $0.first as? Bool) }
            .startWith(self.base.isHighlighted)
            .distinctUntilChanged()
            .share()
        return boolObservable
    }
}
struct GeoInfo2: Codable,Equatable,Hashable{
    func coordinate() -> CLLocationCoordinate2D{
        return .init(latitude: point.coordinates[1], longitude: point.coordinates[0])
    }
    static func makeGeoInfo(title:String,address:String,coordinate:CLLocationCoordinate2D) -> GeoInfo2{
        return GeoInfo2(activated: true, title: title, address: address, point: .init(type: "Point", coordinates: [
            coordinate.longitude,coordinate.latitude
        ]))
    }
    let activated:Bool
    let title: String
    let address: String
    let point: GeoJson
    struct GeoJson: Codable,Equatable,Hashable{
        let type: String
        let coordinates: [Double]
    }
    
}
