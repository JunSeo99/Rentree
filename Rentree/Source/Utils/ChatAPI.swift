//
//  ChatAPI.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//

import Moya


let chatBase = "ec2-3-36-4-254.ap-northeast-2.compute.amazonaws.com"
//let chatBase = "ec2-3-36-4-254.ap-northeast-2.compute.amazonaws.com"
let chatBaseURL = "http://\(chatBase):8080"

enum ChatAPI{
    case getRoomListItem(userId: String,roomId: String)
    
    case getRoomTarget(userId: String, targetId: String)
    case getRoomInformation(userId: String,roomId: String)
    case getRoomList(userId: String)
    case findRooms(userId: String,query: String?,schoolId: String, districtId: String)
    case getMessageList(userId: String,roomId:String)
    case getMiddleMessage(userId: String,roomId:String, messageId: String)
    case getLastestMessageList(userId: String,roomId:String)
    case getRecentMessages(userId:String,roomId:String, recentId:String)
    case getRecentMessage(userId:String,roomId:String)
    case getOldMessages(userId: String,roomId:String,oldId:String)
    case getRoomParticipants(roomId:String)
    case getRandomProfileImage(roomId: String)
//    case makeRoom(content:String,description: String,userId: String,image: ChatSettingProfileReactor.ProfileImage)
//    case modifyRoom(content:String, description: String, userId: String, image: ChatSettingProfileReactor.ProfileImage?, roomId: String)
    case registerPush(userId: String,token: String,device: String = "ios")
    case getFriends(userId: String)
//    case register(userId: String,nickname:String,schoolName:String,profileImage: UserDto2.ProfileImage?)
    case participateRoom(userId:String, roomId: String,image: String)
    case participateLocalRoom(userId:String, roomId: String,image: String,notificationStatus: Bool)
    case getBageCount(userId: String)
    case getAlbaBageCount(userId: String)
    case readAll(userId: String,roomId: String)
    case notificationStatus(userId: String,roomId: String,isOn: Bool)
    case withdrawal(userId: String,roomId: String)
    case sendImage(roomId:String,userId:String,imageHeight:CGFloat,imageWidth:CGFloat,imageData:Data,uid:String)
    case sendMessages(roomId:String,userId:String,contents:[ChatAPI.MessagesSender.Message])
    case removeMessage(roomId: String,messageId: String)
    case blockUser(roomId:String,userId:String,targetId:String)
    case unblockUser(roomId:String,userId:String,targetId:String)
    
    
    case report(report: ReportSender)
    
    case getCategorizedRooms(userId: String, categoryId: String?)
    case forcingToWithdrawal(userId:String, targetId: String, roomId: String)
    case delegatingHost(userId:String, targetId: String, roomId: String)
    
}
extension ChatAPI: TargetType{
    var baseURL: URL {
        let url = URL(string: chatBaseURL)!
//        url.append(path: "")
        return url
    }
    
    var path: String {
        switch self{
        case .getRoomListItem(userId: let userId, roomId: let roomId):
            return "v1/room/item/\(userId)/\(roomId)"
        case .getRoomInformation(userId: let userId, roomId: let roomId):
           return "v2/room/\(userId)/\(roomId)"
        case .getRoomList(userId: let userId):
            return "v2/room/\(userId)/"
        case .getMessageList(userId: let userId, roomId: let roomId):
            return "v1/message/\(userId)/\(roomId)"
        case .getMiddleMessage(userId: let userId, roomId: let roomId, messageId: let messageId):
            return "v1/message/middle/\(userId)/\(roomId)/\(messageId)"
        case .registerPush(userId: let userId, token: _, device: _):
            return "v1/user/push/\(userId)"
        case .getRecentMessages(userId: let userId,roomId: let roomId, recentId: let recentId):
            return "v1/message/recent/\(userId)/\(roomId)/\(recentId)"
        case .getOldMessages(userId: let userId,roomId: let roomId, oldId: let oldId):
            return "v1/message/old/\(userId)/\(roomId)/\(oldId)"
        case .getRoomParticipants(roomId: let roomId):
            return "v1/room/participants/\(roomId)"
        case .getLastestMessageList(userId:let userId,roomId: let roomId):
            return "v1/message/lastest/\(userId)/\(roomId)"
        case .getFriends(userId: let userId):
            return "v1/relation/\(userId)"
        case .findRooms(userId: let userId,query: _,schoolId: _,districtId: _):
            return "v1/room/search/\(userId)"
        case .participateRoom(userId: let userId, roomId: let roomId,image: _):
            return "v1/room/\(userId)/\(roomId)"
        case .participateLocalRoom(userId: let userId, roomId: let roomId, image: _, notificationStatus:_ ):
            return "v1/room/local/\(userId)/\(roomId)"
        case .readAll(userId: let userId, roomId: let roomId):
            return "v1/room/readAll/\(userId)/\(roomId)"
        case .notificationStatus(userId: let userId, roomId: let roomId, isOn: let isOn):
            return "v1/room/notification/\(userId)/\(roomId)/\(isOn)"
        case .withdrawal(userId: let userId, roomId: let roomId):
            return "v2/room/withdrawal/\(userId)/\(roomId)"
        case .sendImage:
            return "v1/message/image"
        case .sendMessages:
            return "v1/message"
        case .getRecentMessage(userId: let userId, roomId: let roomId):
            return "v1/message/show/\(userId)/\(roomId)"
        case .getBageCount(userId: let userId):
            return "v1/room/badgeCount/\(userId)"
        case .getRandomProfileImage(roomId: let roomId):
            return "v1/room/profileImage/\(roomId)"
        case .blockUser(roomId: let roomId, userId: let userId, targetId: let targetId):
            return "v1/user/block/\(userId)/\(targetId)/\(roomId)"
        case .unblockUser(roomId: let roomId, userId: let userId, targetId: let targetId):
            return "v1/user/unblock/\(userId)/\(targetId)/\(roomId)"
        case .report:
            return "v1/report"

        case .removeMessage(roomId: let roomId,messageId: let messageId):
            return "v1/message/\(roomId)/\(messageId)"
        case .getCategorizedRooms:
            return "v2/room/category"
        case .delegatingHost(userId: let userId, targetId: let targetId, roomId: let roomId):
            return "v1/room/host/delegate/\(userId)/\(targetId)/\(roomId)"
        case .forcingToWithdrawal(userId: let userId, targetId: let targetId, roomId: let roomId):
            return "v1/room/host/withdrawal/\(userId)/\(targetId)/\(roomId)"
        case .getAlbaBageCount(userId: let userId):
            return "v1/room/alba/badgeCount/\(userId)"
        case .getRoomTarget(userId: let userId, targetId: let targetId):
            return "v2/room/target/\(userId)/\(targetId)"
        }
    }
    
    var method: Moya.Method {
        switch self{
        case .getRoomList,.getMessageList:
            return .get
        case .getRoomInformation:
            return .get
        case .registerPush:
            return .post
        case .getRecentMessages:
            return .get
        case .getOldMessages:
            return .get
        case .getMiddleMessage:
            return .get
        case .getRoomParticipants:
            return .get
        case .getLastestMessageList:
            return .get
        case .getFriends:
            return .get
        case .findRooms:
            return .get
        case .participateRoom:
            return .put
        case .readAll:
            return .put
        case .notificationStatus:
            return .put
        case .withdrawal:
            return .delete
        case .sendImage:
            return .post
        case .sendMessages:
            return .post
        case .getRecentMessage:
            return .get
        case .getRoomListItem:
            return .get
        case .getBageCount:
            return .get
        case .blockUser:
            return .put
        case .unblockUser:
            return .put
        case .report:
            return .post
        case .getRandomProfileImage:
            return .get
        case .participateLocalRoom:
            return .put
        case .removeMessage:
            return .delete
        case .getCategorizedRooms:
            return .get
        case .forcingToWithdrawal:
            return .delete
        case .delegatingHost:
            return .put
        case .getAlbaBageCount:
            return .get
        case .getRoomTarget:
            return .get
        }
    }
    
    var task: Moya.Task {
        switch self{
        case .getRoomList(userId: _):
           
            return .requestPlain
//            return .requestParameters(parameters: ["userId":userId], encoding: URLEncoding.default)
        case .getMessageList,.getRecentMessages,.getOldMessages:
            return .requestPlain
//            return .requestParameters(parameters: ["userId":userId,"roomId":roomId], encoding: URLEncoding.default)
        case .getRoomInformation:
            return .requestPlain
//            return .requestParameters(parameters: ["userId":userId,"roomId":roomId], encoding: URLEncoding.default)
        case .registerPush(userId: _, token: let token,device: let device):
            let doc = ["token": token, "device": device]
            let encoder = JSONEncoder()
            let data = try! encoder.encode(doc)
            return .requestCompositeData(bodyData: data, urlParameters: [:])
        case .getRoomParticipants:
            return .requestPlain
        case .getLastestMessageList:
            return .requestPlain
        case .getFriends:
            return .requestPlain
        case .participateRoom(userId: _, roomId: _, image: let image):
            return .requestCompositeParameters(bodyParameters: ["image": image], bodyEncoding: JSONEncoding.default, urlParameters: [:])
//            return .requestParameters(parameters: ["image": image], encoding: URLEncoding.default)
        case .readAll:
            return .requestPlain
        case .notificationStatus:
            return .requestPlain
        case .withdrawal:
            return .requestPlain
        case .sendImage(roomId: let roomId, userId: let userId, imageHeight: let imageHeight, imageWidth: let imageWidth, imageData: let imageData, uid: let uid):
            let roomId:MultipartFormData = .init(provider: .data(roomId.data(using: .utf8)!), name: "roomId")
            let userId:MultipartFormData = .init(provider: .data(userId.data(using: .utf8)!), name: "userId")
            let uid:MultipartFormData = .init(provider: .data(uid.data(using: .utf8)!), name: "uid")
            let imageHeight:MultipartFormData = .init(provider: .data("\(imageHeight)".data(using: .utf8)!), name: "imageHeight")
            let imageWidth:MultipartFormData = .init(provider: .data("\(imageWidth)".data(using: .utf8)!), name: "imageWidth")
            let imageData:MultipartFormData = .init(provider: .data(imageData), name: "imageData",mimeType: "image/jpeg")
            return .uploadMultipart([roomId,userId,imageHeight,imageWidth,imageData,uid])
        case .sendMessages(roomId: let roomId, userId: let userId, contents: let contents):
            let sender = MessagesSender(roomId: roomId, userId: userId, contents: contents)
            return .requestJSONEncodable(sender)
//            return .uploadMultipart([roomId,userId,contents,uid])
        case .getRecentMessage:
            return .requestPlain
        case .getRoomListItem:
            return .requestPlain
        case .getBageCount:
            return .requestPlain
        case .blockUser:
            return .requestPlain
        case .unblockUser:
            return .requestPlain
        case .report(report: let report):
            return .requestJSONEncodable(report)
        case .getRandomProfileImage:
            return .requestPlain
        case .getMiddleMessage:
            return .requestPlain
        case .participateLocalRoom(userId: _, roomId: _, image: let image, notificationStatus: let notificationStatus):
            return .requestCompositeParameters(bodyParameters: ["image": image,"notificationStatus": notificationStatus], bodyEncoding: JSONEncoding.default, urlParameters: [:])
        case .removeMessage:
            return .requestPlain
        case .getCategorizedRooms(userId: let userId, categoryId: let categoryId):
            if let categoryId {
                return .requestParameters(parameters: ["userId": userId, "categoryId": categoryId], encoding: URLEncoding.default)
            }
            else{
                return .requestParameters(parameters: ["userId": userId], encoding: URLEncoding.default)
            }
            
        case .forcingToWithdrawal:
            return .requestPlain
        case .delegatingHost:
            return .requestPlain
        case .getAlbaBageCount:
            return .requestPlain
        case .findRooms(userId: let userId, query: let query, schoolId: let schoolId, districtId: let districtId):
            return .requestPlain
        case .getRoomTarget:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        return [:]
    }
    struct ReportSender: Codable{
        var userId: String
        var targetUserId: String
        var messageId: String
        var score: Int
        var shouldCheck: Bool
        var reason: String
    }
    struct RoomSender: Codable{
        let content: String
        let description: String
        let participants: [String]
        let userId: String
        let image: Data?
    }
    struct MessagesSender: Codable {
        var roomId: String
        var userId: String
        var contents: [MessagesSender.Message]
        struct Message: Codable{
            var content: String
            var uid: String
        }
    }
    
}

