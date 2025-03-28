//
//  MainNotification.swift
//  Rentree
//
//  Created by jun on 3/28/25.
//
import RxSwift
import RxCocoa

class MainNotification {
    static var `default` = ReplaySubject<MoveAction?>.create(bufferSize: 1)
//    static var state = ReplaySubject<StateChange?>.create(bufferSize: 1)
    enum MoveAction {
        case moveToRoom(Room)
//        case managerToRoomNotificationWithId(id: String)
//        case managerToApplicant(userId: String,announcementId: String)
//        case managerToPropose(userId: String,announcementId: String)
//        case refreshPropose
//        case refreshApplicants
//        case addAnnouncement
//        case updateAnnouncement
//        case managerToMyAnnouncement(announcements: [BaseAnnouncement]?)
//        case certificatedBusinessInformation
//        case movePost(type: Int,postId: String,commentId: String?, replyId: String?)
//        case performVerification(requestId: String)
//        
//        case announcementUnlimitedStatusChanged
//        case announcementUnlimitedStatusChagedWithDate(announcementId: String, date: String)
//        case keyOverview
//        case key
        
    }
//    enum StateChange {
//        case changedKeyCount(keyCount: Int, freeKeyCount: Int)
//        case badgeChanged(applicant: Bool?, propose: Bool?, chat: Bool?, careerVerification: Bool?)
//        case proposed(targetUserId: String)
//    }
}
