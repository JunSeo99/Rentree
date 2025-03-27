//
//  API.swift
//  Rentree
//
//  Created by jun on 3/25/25.
//

import Moya

enum API{
    case getPosts(schoolCode: String, query: String)
    case getUnivList(query: String)
    case setUniv(userId: String, univName: String)
    case registerProfileImage(userId: String, profile: Data?)
    case like(postId: String, userId: String, state: Bool)
        
}
extension API:TargetType{
    var headers: [String : String]? {
        return nil
    }
    
    var baseURL: URL {
//        return URL(string: "http://localhost:8080")!
        return URL(string: "http://ec2-13-124-253-46.ap-northeast-2.compute.amazonaws.com:8080")!
    }
    
    var path: String {
        switch self{
        case .getPosts:
            return "/post/index"
        case .getUnivList:
            return "/user/univ/list"
        case .setUniv:
            return "/user/univ"
        case .registerProfileImage:
            return "/user/profile"
        case .like:
            return "/post/sendPostLikeSwitch"
        }
    }
    
    var method: Method {
        switch self {
        case .getPosts:
            return .get
        case .getUnivList:
            return .get
        case .setUniv:
            return .post
        case .registerProfileImage:
            return .post
        case .like:
            return .post
        }
    }
    
    var task: Task {
        switch self{
        case .getPosts(schoolCode: let schoolCode, query: let query):
            return .requestParameters(parameters: ["schoolCode": schoolCode, "query": query], encoding: URLEncoding.queryString)
        case .getUnivList(query: let query):
            return .requestParameters(parameters: ["query": query], encoding: URLEncoding.queryString)
        case .setUniv(userId: let userId, univName: let univName):
            return .requestParameters(parameters: ["schoolName": univName, "userId": userId], encoding: URLEncoding.queryString)
        case .registerProfileImage(userId: let userId, profile: let image):
            var multipartFormDatas: [MultipartFormData] = []
            multipartFormDatas.append(.init(provider: .data(userId.data(using: .utf8)!), name: "userId"))
            if let image {
                multipartFormDatas.append(.init(provider: .data(image), name: "profile",fileName: "\(userId)\(Date.timeIntervalSinceReferenceDate).jpeg" ,mimeType: "image/jpeg"))
            }
            return .uploadMultipart(multipartFormDatas)
            
        case .like(postId: let postId, userId: let userId, state: let state):
            return .requestParameters(parameters: ["postId": postId, "userId": userId, "state": state], encoding: URLEncoding.queryString)
            
        }
    }
}
