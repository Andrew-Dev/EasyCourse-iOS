//
//  User.swift
//  EasyCourse
//
//  Created by ZengJintao on 8/31/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift
import KeychainSwift
//import Cache
import Alamofire
import AlamofireImage

var _currentUser:User?
var _userLang:[Int] = []

class User: Object {
    
    dynamic var id:String? = nil
    dynamic var username:String? = nil
    dynamic var profilePicture: Data? = nil
    dynamic var profilePictureUrl:String? = nil
    dynamic var email:String? = nil
    dynamic var universityID:String? = nil
    
    //Related to user
    // 0 means other is on user's friend pending list.(others can send message to user, but push notification only sent at the first message)
    // 1 means user regards other as friend.(others can sent message to user)
    // 2 means user blocks other. (others cannot sent message to user)
    dynamic var userFriendStatus = 0
    
    // 0 means user is on other's friend pending list.(user can send message to other, but push notification only sent at the first message)
    // 1 means other regards user as friend.(user can sent message to other)
    // 2 means other blocks user. (user cannot sent message to other)
    dynamic var otherFriendStatus = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    class var currentUser: User? {
        get {
            if _currentUser != nil { return _currentUser }
            if let id = UserDefaults.standard.object(forKey: Constant.UserDefaultKey.currentUserIDKey) as? String {
                let realm = try! Realm()
                _currentUser = realm.object(ofType: User.self, forPrimaryKey: id)
                return _currentUser
            } else {
                return nil
            }
        }
        set(user) {
            _currentUser = user
            if user != nil {
                let realm = try! Realm()
                try! realm.write({
                    realm.add(user!, update: true)
                })
                UserDefaults.standard.set(user!.id, forKey: Constant.UserDefaultKey.currentUserIDKey)
            } else {
                RealmTools.setDefaultRealmForUser(nil)
                UserDefaults.standard.set(nil, forKey: Constant.UserDefaultKey.currentUserIDKey)
            }
            UserDefaults.standard.synchronize()
        }
    }
    
    class var userLang: [Int] {
        get {
            if let lang  = UserDefaults.standard.object(forKey: Constant.UserDefaultKey.currentUserLangKey) as? [Int] {
                _userLang = lang
            }
            return _userLang
        }
        set(langArr) {
            _userLang = langArr
            UserDefaults.standard.set(_userLang, forKey: Constant.UserDefaultKey.currentUserLangKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var token:String? {
        get {
            let keychain = KeychainSwift()
            let token = keychain.get(Constant.UserDefaultKey.currentUserTokenKey)
            if token == nil || (token?.isEmpty)! { return nil } else { return token }
        }
        set(token) {
            let keychain = KeychainSwift()
            if token == nil {
                keychain.set("", forKey: Constant.UserDefaultKey.currentUserTokenKey)
            } else {
                keychain.set(token!, forKey: Constant.UserDefaultKey.currentUserTokenKey)
            }
        }
    }
    
    func initUserFromServerWithData(_ data:NSDictionary) -> User {
        if self.id == nil {
            self.id = data["_id"] as? String
        }
        self.username = data["displayName"] as? String
        self.email = data["email"] as? String
        self.profilePictureUrl = data["avatarUrl"] as? String
        self.universityID = data["university"] as? String
        self.otherFriendStatus = data["status"] as? Int ?? 0
        return self
    }
    
    func initCurrentUserWithData(_ data:NSDictionary) -> User {
        self.id = data["_id"] as? String
        self.username = data["displayName"] as? String
        self.email = data["email"] as? String
        self.universityID = data["university"] as? String
        self.profilePictureUrl = data["avatarUrl"] as? String
        if self.profilePictureUrl != nil {
            ServerHelper.sharedInstance.getNetworkImage(profilePictureUrl!, completion: { (data, error) in
                if data != nil {
                    try! Realm().write({
                        User.currentUser?.profilePicture = data
                    })
                }
            })
        }
        
        if let courseArray = data["joinedCourse"] as? [NSDictionary] {
            var courses:[Course] = []
            for courseData in courseArray {
                courses.append(Course.initCourse(courseData)!)
            }
            Course.syncCourse(courses)
        }
        
        var rooms:[Room] = []
        if let roomArray = data["joinedRoom"] as? [NSDictionary] {
            for roomData in roomArray {
                if let room = Room.createOrUpdateRoomWithData(data: roomData, isToUser: false) {
                    rooms.append(room)
                }
            }
        }
        
        if let contactsArray = data["contacts"] as? [NSDictionary] {
            for contactData in contactsArray {
                if let room = Room.createOrUpdateRoomWithData(data: contactData, isToUser: true) {
                    rooms.append(room)
                }
                let user = User()
                user.initUserFromServerWithData(contactData).saveToDatabase()
            }
        }
        
        Room.syncRoom(rooms)

        
        if let silentRoomIdArray = data["silentRoom"] as? [String] {
            let realm = try! Realm()
            for roomId in silentRoomIdArray {
                if let room = realm.object(ofType: Room.self, forPrimaryKey: roomId) {
                    try! realm.write {
                        room.silent = true
                    }
                }
            }
        }

        return self
    }
    
    func syncCurrentUserWithData(_ data:NSDictionary) {
        let originProfilePictureUrl = User.currentUser?.profilePictureUrl
        try! Realm().write({ 
//            self.id = data["_id"] as? String
            self.username = data["displayName"] as? String
            self.email = data["email"] as? String
            self.universityID = data["university"] as? String
            self.profilePictureUrl = data["avatarUrl"] as? String
        })

//        print("profilUrl: \(self.profilePictureUrl)")
//        print("oriprofilUrl: \(originProfilePictureUrl)")
        if profilePictureUrl != nil {
            
            if User.currentUser?.profilePicture == nil || originProfilePictureUrl != self.profilePictureUrl  {
                print("download img")
                ServerHelper.sharedInstance.getNetworkImage(profilePictureUrl!, completion: { (data, error) in
                    if data != nil {
                        try! Realm().write({
                            self.profilePicture = data
                        })
                        NotificationCenter.default.post(name: Constant.NotificationKey.SyncUser, object: nil)
                    }
                })
            }
        }
        
        if let lang = data["userLang"] as? [Int] {
            User.userLang = lang
        }
        
        if let courseArray = data["joinedCourse"] as? [NSDictionary] {
            var courses:[Course] = []
            for courseData in courseArray {
                courses.append(Course.initCourse(courseData)!)
            }
            Course.syncCourse(courses)
        }
        
        var rooms:[Room] = []
        if let roomArray = data["joinedRoom"] as? [NSDictionary] {
            for roomData in roomArray {
                if let room = Room.createOrUpdateRoomWithData(data: roomData, isToUser: false) {
                    rooms.append(room)
                }
                
            }
        }
        
        if let contactsArray = data["contacts"] as? [NSDictionary] {
            for contactData in contactsArray {
                if let room = Room.createOrUpdateRoomWithData(data: contactData, isToUser: true) {
                    rooms.append(room)
                }
                let user = User()
                user.initUserFromServerWithData(contactData).saveToDatabase()
            }
        }
        
        Room.syncRoom(rooms)

        if let silentRoomIdArray = data["silentRoom"] as? [String] {
            let realm = try! Realm()
            for roomId in silentRoomIdArray {
                if let room = realm.object(ofType: Room.self, forPrimaryKey: roomId) {
                    try! realm.write {
                        room.silent = true
                    }
                }
            }
        }

    }
    
    //TODO: save other users method
//    internal func initUserFromCache(_ id:String) -> User? {
//        let userdata:JSON? = userCache.object(id)
//        
//        if userdata != nil {
//            let user = User()
//            user.username = userdata!.object["username"] as? String
//            user.id = userdata!.object["id"] as? String
//            user.profilePictureUrl = userdata!.object["profilePictureUrl"] as? String
//            return user
//        } else {
//            print("cache not found in init")
//            return nil
//        }
//    }
//    
//    func cacheUserInfo() {
//        if id == nil || username == nil { return }
//        var userData = ["id":id!, "username":username!]
//        if profilePictureUrl != nil {
//            userData["profilePictureUrl"] = profilePictureUrl!
//        }
//        print("add cach with data \(userData)")
//        userCache.add(id!, object: JSON.Dictionary(userData))
//    }
//    
    func saveToDatabase() {
        let realm = try! Realm()
        try! realm.write({
            realm.add(self, update: true)
        })
    }
    
}
