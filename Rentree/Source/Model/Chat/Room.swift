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
    var names: [String]
    var gender: Int?
    var lastMessage: RoomListItem.LastMessage
    var partnerOut: Bool
    var isBlock: Bool
    var image: String?
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.unreadCount = try container.decode(Int.self, forKey: .unreadCount)
        self.notificationStatus = try container.decode(Bool.self, forKey: .notificationStatus)
        self.names = try container.decode([String?].self, forKey: .names).compactMap({$0})
        self.lastMessage = try container.decode(RoomListItem.LastMessage.self, forKey: .lastMessage)
        self.id = try container.decode(String.self, forKey: .id)
        self.isBlock = (try? container.decode(Bool?.self, forKey: .isBlock)) ?? false
//        self.type = (try? container.decode(String?.self, forKey: .type)) ?? "HR"
        self.partnerOut = try container.decode(Bool.self, forKey: .partnerOut)
        self.image = try container.decodeIfPresent(String.self, forKey: .image)
        self.gender = try container.decodeIfPresent(Int.self, forKey: .gender)
    }
    init(id: String, type: String, unreadCount: Int, notificationStatus: Bool, names: [String], lastMessage: RoomListItem.LastMessage, partnerOut: Bool, isBlock: Bool) {
        self.id = id
        self.type = type
        self.unreadCount = unreadCount
        self.notificationStatus = notificationStatus
        self.names = names
        self.lastMessage = lastMessage
        self.partnerOut = partnerOut
        self.isBlock = isBlock
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
