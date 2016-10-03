//
//  UserSetting.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/27/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import Foundation

import UIKit

var _userDeviceToken:String?
var _userSilentRoom:[String] = []

open class UserSetting {
    
    static let sharedInstance = UserSetting()
    
    class var userDeviceToken: String? {
        get {
            if _userDeviceToken != nil { return _userDeviceToken }
            if let token = UserDefaults.standard.object(forKey: Constant.UserDefaultKey.currentUserIDKey) as? String {
                _userDeviceToken = token
                return _userDeviceToken
            } else {
                return nil
            }
        }
        set(token) {
            _userDeviceToken = token
            UserDefaults.standard.set(_userDeviceToken, forKey: Constant.UserDefaultKey.deviceTokenKey)
            UserDefaults.standard.synchronize()
        }
    }
    
}
