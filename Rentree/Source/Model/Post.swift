//
//  Post.swift
//  Rentree
//
//  Created by jun on 3/26/25.

import Foundation

// Post 모델 (클래스)
class Post: Codable {
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
    var priceType: String // 3일
    var availableDates: [Int] // 잉여 데이터
    var borrowerInfo: [BorrowerInfo]
    var rentalType: String // ex)
    var itemType: String // 테블릿 or 전동 드라이버
    
    static func sampleData() -> [Post] {
        return [
            
        ]
    }
}

// GeoInfo 모델
struct GeoInfo: Codable {
    var type: String
    var coordinates: [Double]
}

// BorrowerInfo 모델
struct BorrowerInfo: Codable {
    var userId: String
    var state: Int // 0 아무도 안빌림, 1 빌려달라고 요청이 옴, 2 빌려주는중
    var createdAt: String
    var startDate: String // 빌려주기 시작한 일자 yyyyMMdd
    var endDate: String // 반납을 해야하는 일자 yyyyMMdd
}
