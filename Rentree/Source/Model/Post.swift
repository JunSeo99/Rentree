//
//  Post.swift
//  Rentree
//
//  Created by jun on 3/26/25.

import Foundation
import UIKit
// Post 모델 (클래스)
struct Post: Codable, Equatable {
    var id: String
    var name: String
    var writerId: String
    var createdAt: String
    var title: String
    var content: String
    var schoolCode: String // 대학교 이름 '단국대학교'
    var photos: [String]
    var likes: [String]
    var tags: [String]
    var geoInfo: GeoInfo
    var price: Int // Price Type 당 얼마
    var priceByPeriod: String // 3일
    var availableDates: [Int] // 잉여 데이터
    var borrowerInfo: [BorrowerInfo]
    var rentalType: String // ex)
    var itemType: String // 테블릿 or 전동 드라이버
    var viewCount: Int
    
    static func sampleData() -> [Post] {
        return [
            
        ]
    }
}

// GeoInfo 모델
struct GeoInfo: Codable, Equatable {
    var type: String
    var coordinates: [Double]
}

// BorrowerInfo 모델
struct BorrowerInfo: Codable, Equatable {
    var userId: String
    var state: Int // 0 아무도 안빌림, 1 빌려달라고 요청이 옴, 2 빌려주는중
    var createdAt: String
    var startDate: String? // 빌려주기 시작한 일자 yyyyMMdd
    var endDate: String? // 반납을 해야하는 일자 yyyyMMdd
    var name: String?
    var profileImage: String?
    var mannerValue: Int?
    var returnImage: String?
    var schoolCode: String?
}


extension UIImageView {
    func setTreeImage(mannerValue: Int) {
        if mannerValue <= 1 {
            self.image = UIImage(resource: .iconTreeStage1)
        }
        else if mannerValue == 2 {
            self.image = UIImage(resource: .iconTreeStage2)
        }
        else if mannerValue == 3 {
            self.image = UIImage(resource: .iconTreeStage3)
        }
        else if mannerValue == 4 {
            self.image = UIImage(resource: .iconTreeStage4)
        }
        else if mannerValue >= 5 {
            self.image = UIImage(resource: .iconTreeStage5)
        }
        
    }
}
