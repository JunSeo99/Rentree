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
}


var user = User(id: "67e40cde413f36b08590b2bc", name: "호엥엥ㅇ에에엥", schoolCode: "단국대학교", age: 25, geoInfo: .init(type: "Point", coordinates: [
    32.12314, 132.1304
]), mannerValue: 10)
