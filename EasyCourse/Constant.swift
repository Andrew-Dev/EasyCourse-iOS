//
//  Constant.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/6/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class Constant: NSObject {
    
    struct NotificationKey {
        static let GetMessage = NSNotification.Name(rawValue: "GetMessage")
        static let SyncUser = NSNotification.Name(rawValue: "SyncUser")
        static let UserDidLogin = NSNotification.Name(rawValue: "UserDidLogin")
        static let UserDidLogout = NSNotification.Name(rawValue: "UserDidLogout")
        static let RoomDelete = NSNotification.Name(rawValue: "roomDeleted")
        
    }
    
    struct UserDefaultKey {
        static let currentUserIDKey = "kCurrentUserIDKey"
        static let currentUserLangKey = "kCurrentUserLangKey"
        static let currentUserTokenKey = "kCurrentUserTokenKey"
        static let shouldAskPushNotif = "shouldAskPushNotif"
        static let deviceTokenKey = "deviceTokenKey"
        static let silentRoomKey = "deviceTokenKey"
        static let updateShowDateKey = "updateShowDateKey"
        static func userMsgLastUpdateKey(id: String) -> String {
            return "userMsgLastUpdateKey\(id)"
        }
    }
    
    
    enum imageUploadType:String {
        case message
        case avatar
    }
    
    enum searchStatus {
        case notSearching
        case isSearching
        case receivedEmptyResult
        case receivedError
        case receivedResult
    }
    
//    static let baseURL = "https://www.easycourseserver.com/api"
    
//    static let baseURL = "https://zengjintaotest.com/api"
    static let baseURL = "http://localhost:3000/api"
    
}
