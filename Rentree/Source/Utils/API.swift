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
    case borrowing(postId: String, userId: String)
    case allowBorrowing(postId: String, userId: String)
    case getMyPost(userId: String)
    case getBorrowedPost(userId: String)
    case login(userId: String)
    
    case returnBack(postId: String, borrowerId: String, image: Data)
    case showPost(String)
    case getPost(postId: String)
}
extension API:TargetType{
    var headers: [String : String]? {
        return nil
    }
    
    var baseURL: URL {
//        return URL(string: "http://localhost:8080")!
        return URL(string: "http://ec2-52-79-229-101.ap-northeast-2.compute.amazonaws.com:8080")!
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
        case .borrowing:
            return "/post/request"
        case .allowBorrowing:
            return "/post/allow"
        case .getMyPost:
            return "/post/lent"
        case .getBorrowedPost:
            return "/post/borrow"
        case .returnBack:
            return "/post/return"
        case .login:
            return "/user/login"
        case .showPost:
            return "/user/show"
        case .getPost:
            return "/post"
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
        case .borrowing:
            return .post
        case .allowBorrowing:
            return .put
        case .getMyPost(userId: let userId):
            return .get
        case .getBorrowedPost(userId: let userId):
            return .get
        case .returnBack:
            return .post
        case .login:
            return .get
        case .showPost(_):
            return .get
        case .getPost(postId: let postId):
            return .get
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
            
        case .borrowing(postId: let postId, userId: let userId):
            return .requestParameters(parameters: ["postId": postId, "borrowerId": userId], encoding: URLEncoding.queryString)
        case .allowBorrowing(postId: let postId, userId: let userId):
            return .requestParameters(parameters: ["postId": postId, "borrowerId": userId], encoding: URLEncoding.queryString)
        case .getMyPost(userId: let userId):
            return .requestParameters(parameters: ["userId": userId], encoding: URLEncoding.queryString)
        case .getBorrowedPost(userId: let userId):
            return .requestParameters(parameters: ["userId": userId], encoding: URLEncoding.queryString)
        case .returnBack(postId: let postId, borrowerId: let borrowerId, image: let image):
            var multipartFormDatas: [MultipartFormData] = []
            multipartFormDatas.append(.init(provider: .data(postId.data(using: .utf8)!), name: "postId"))
            multipartFormDatas.append(.init(provider: .data(borrowerId.data(using: .utf8)!), name: "borrowerId"))
            multipartFormDatas.append(.init(provider: .data(image), name: "returnImage",fileName: "\(borrowerId)\(Date.timeIntervalSinceReferenceDate).jpeg" ,mimeType: "image/jpeg"))
            return .uploadMultipart(multipartFormDatas)
//            return .requestParameters(parameters: ["userId": userId, "borrowerId": borrowerId], encoding: URLEncoding.queryString)
            
        case .login(userId: let userId):
            return .requestParameters(parameters: ["userId": userId], encoding: URLEncoding.queryString)
        case .showPost(let postId):
            return .requestParameters(parameters: ["postId": postId], encoding: URLEncoding.queryString)
        case .getPost(postId: let postId):
            return .requestParameters(parameters: ["postId": postId], encoding: URLEncoding.queryString)
        }
    }
}
