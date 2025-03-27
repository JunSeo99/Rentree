//
//  Chat.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//
import Foundation
import RxDataSources

struct Chat: Codable,Equatable,IdentifiableType{
    var identity: String {
        return id
    }
    var isFirst: Bool?
    typealias Identity = String
    let id:String
    let userId: String
    var name: String
    let createdAt: String
    var content: String
    let type: String
    let roomId: String
    var image: Image?
    var unreadCount: Int
    var uid: String
    var profileImage: String?
    let block: Bool?
    var mention: Mention?
    var removed: Bool?
    var gender: Int?
    struct Image: Codable,Equatable{
        let url: String
        let height:CGFloat
        let width:CGFloat
        var data: Data?
    }
    struct Mention: Codable, Equatable{
        var content: String
        var messageId: String
        var name: String
        var userId: String
        var image: String?
    }
}
struct RemoveChat: Codable, Equatable {
    let type: String
    let roomId: String
    let removedId: String
}
struct ForcingToWithdrawal: Codable, Equatable  {
    let type: String
    let roomId: String
    let targetId: String
    let uid: String
}
struct BrokenRoom: Codable, Equatable  {
    let type: String
    let roomId: String
    let uid: String
}
struct ModifiedRoom: Codable, Equatable {
    let type: String
    let roomId: String
    let content: String
    let description: String
    let image: String?
    let imageURL: String?
}
struct Show: Codable,Equatable{
    let type: String
    let roomId: String
    let oldLastId: String?
    let showedId:String?
    let content:String?
    let unreadCount: Int?
}

struct ChatSeperated:Codable,Equatable{
    let old: [Chat]
    let new: [Chat]
}
enum ChatType: Equatable,IdentifiableType{
    var identity: String {
        switch self {
        case .sent(let chat):
            return chat.id
        case .received(let chat):
            return chat.id
        case .notice(let chat):
            return chat.id
        case .loading(let chat,fail: _):
            return chat.id
        case .unread:
            return "1"
        case .date(let date):
            return date
        }
    }
    
    typealias Identity = String
    
    case sent(Chat)
    case received(Chat)
    case date(String)
    case notice(Chat)
    case loading(Chat,fail: Bool)
    case unread
    func getChat() -> Chat?{
        switch self{
        case .loading(let chat, fail: _):
            return chat
        case .sent(let chat):
            return chat
        case .received(let chat):
            return chat
        case .notice(let notice):
            return notice
        default:
            return nil
        }
    }
}
struct MySectionModel{
    var header: String = ""
    var items: [Item]
}
extension MySectionModel: AnimatableSectionModelType ,Equatable{
    typealias Item = ChatType
    var identity: String {
        return header
    }
    init(original: MySectionModel, items: [ChatType]) {
        self = original
        self.items = items
    }
}
