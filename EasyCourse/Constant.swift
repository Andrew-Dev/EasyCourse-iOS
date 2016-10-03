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
        static let deviceTokenKey = "deviceTokenKey"
        static let silentRoomKey = "deviceTokenKey"
        
    }
    
    
    enum imageUploadType:String {
        case message
        case avatar
    }
    
    static let baseURL = "https://zengjintaotest.com/api"
//    static let baseURL = "http://localhost:3000/api"
}
