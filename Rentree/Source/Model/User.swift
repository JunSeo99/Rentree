//
//  User.swift
//  Rentree
//
//  Created by jun on 3/25/25.
//



struct User: Codable {
    let id: String
    let name: String
    var schoolCode: String
    var age: Int
    var geoInfo: GeoJsonPoint
    var mannerValue: Int
    var profileImage: String?
    var monthTransactionValue: Int
    var monthTransactionCount: Int
}


//var user = User(id: "6600a1234bcf123456789099", name: "강하늘", schoolCode: "단국대학교", age: 25, geoInfo: .init(type: "Point", coordinates: [
//    32.12314, 132.1304
//]), mannerValue: 3, monthValue: 20000, monthCount: 2)

var user = User(id: "6600a1234bcf123456789100", name: "송준서", schoolCode: "단국대학교", age: 25, geoInfo: .init(type: "Point", coordinates: [
    32.12314, 132.1304
]), mannerValue: 2, monthTransactionValue: 45000, monthTransactionCount: 3)
