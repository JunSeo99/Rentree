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
    var schoolCode: String
    var photos: [String]
    var likes: [String]
    var tags: [String]
    var geoInfo: GeoInfo
    var price: Int
    var availableDates: [Int]
    var borrowerInfo: [BorrowerInfo]
    var rentalType: String
    var itemType: String
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id" // 이미 toString 처리됨
//        case writerId, createdAt, title, content, schoolCode, photos, likes, tags, geoInfo, price, availableDates, borrowerInfo, rentalType, itemType
//    }
    
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
    var state: Int
    var createdAt: String
    var startDate: String
    var endDate: String

//    enum CodingKeys: String, CodingKey {
//        case userId, state, createdAt, startDate, endDate
//    }
}
