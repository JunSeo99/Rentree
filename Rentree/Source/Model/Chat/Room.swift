//
//  Room.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//
import RxDataSources

protocol RoomType: Codable, Equatable {
    var id: String { get set }
    var unreadCount: Int { get set }
    var notificationStatus: Bool { get set }
    var type: String { get set }
}

struct RoomListItem: RoomType {
    var id: String
    var participantCount: Int
    var unreadCount: Int
    var description: String
    var content: String
    var lastMessage: LastMessage?
    var notificationStatus: Bool
    var profileImage: String
    var image: String
    var imageURL: String?
    var type: String
    var hostId: String?
    var forcedWithdrawal: Bool?
    var brokenRoom: Bool?
    var postInformation: String
    struct LastMessage: Codable,Equatable  {
        var content: String
        let date: String
        let messageId: String?
        var containMention: Bool
    }
}

struct Room: RoomType {
    var id: String
    var type: String
    var unreadCount: Int
    var notificationStatus: Bool
    var content: String
    var gender: Int?
    var lastMessage: RoomListItem.LastMessage
    var isBlock: Bool
    var image: String?
    var postInformation: String
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.unreadCount = try container.decode(Int.self, forKey: .unreadCount)
        self.notificationStatus = try container.decode(Bool.self, forKey: .notificationStatus)
        self.content = try container.decode(String.self, forKey: .content)
        self.lastMessage = try container.decode(RoomListItem.LastMessage.self, forKey: .lastMessage)
        self.id = try container.decode(String.self, forKey: .id)
        self.image = try container.decode(String.self, forKey: .image)
        self.isBlock = (try? container.decode(Bool?.self, forKey: .isBlock)) ?? false
        self.gender = try container.decodeIfPresent(Int.self, forKey: .gender)
        self.type = (try container.decodeIfPresent(String.self, forKey: .type)) ?? ""
        self.postInformation = try container.decode(String.self, forKey: .postInformation)
    }
    init(id: String, type: String,image: String?, unreadCount: Int, notificationStatus: Bool, content: String, lastMessage: RoomListItem.LastMessage, partnerOut: Bool, isBlock: Bool, postInformation: String) {
        self.id = id
        self.type = type
        self.unreadCount = unreadCount
        self.notificationStatus = notificationStatus
        self.content = content
        self.lastMessage = lastMessage
        self.isBlock = isBlock
        self.image = image
        self.postInformation = postInformation
    }
}

struct RoomListModelType{
    var items: [Item]
}
extension RoomListModelType: SectionModelType ,Equatable{
    typealias Item = Room
    init(original: RoomListModelType, items: [Room]) {
        self = original
        self.items = items
    }
}
