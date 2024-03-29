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
import SwiftyJSON

var _currentUser:User?
var _userLang:[String] = []

class User: Object {
    
    dynamic var id:String? = nil
    dynamic var username:String? = nil
    dynamic var profilePicture: Data? = nil
    dynamic var profilePictureUrl:String? = nil
    dynamic var email:String? = nil
    dynamic var universityId:String? = nil
    let fbUser = RealmOptional<Bool>()
    let joinedRoom = List<Room>()
    let joinedCourse = List<Course>()
    let langArray = List<Language>()
    
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
    
    func setLastMsgUpdateTime(_ Date:Date) {
        UserDefaults.standard.set(Date, forKey: Constant.UserDefaultKey.userMsgLastUpdateKey(id: self.id!))
        UserDefaults.standard.synchronize()
    }
    
    func getLastMsgUpdateTime() -> Date? {
        if let date = UserDefaults.standard.object(forKey: Constant.UserDefaultKey.userMsgLastUpdateKey(id: self.id!)) as? Date {
            return date
        } else {
            return nil
        }
    }
    
    func userLang() -> [String] {
        var langArr:[String] = []
        self.langArray.forEach { (lang) in
            langArr.append(lang.code!)
        }
        return langArr
    }
    
    // New
    internal class func createOrUpdateUserWithData(_ data:NSDictionary) -> User? {
//        print("user data: \(data)")
        let realm = try! Realm()
        // Check id
        guard let id = data["_id"] as? String else {
            return nil
        }
        
        //Check user exsit or not
        var user:User?
        if let existedUser = realm.object(ofType: User.self, forPrimaryKey: id) {
            user = existedUser
        } else {
            user = User()
            user?.id = id
            try! realm.write {
                realm.add(user!)
            }
        }
        
        user?.mapUserWithData(data)
        
        return user
    }
    
    func mapUserWithData(_ data:NSDictionary) {
        let realm = try! Realm()
        try! realm.write {
            if let username = data["displayName"] as? String {
                self.username = username
            }
            if let email = data["email"] as? String {
                self.email = email
            }
            if let profilePictureUrl = data["avatarUrl"] as? String {
                self.profilePictureUrl = profilePictureUrl
            }
            if let universityId = data["university"] as? String {
                self.universityId = universityId
            }
            if let fbUser = data["fbUser"] as? Bool {
                self.fbUser.value = fbUser
            }
        }
//        print("data: \(data)")
        if let langs = data["userLang"] as? [String] {

            try! realm.write {
                self.langArray.removeAll()
            }
                langs.forEach({ (lang) in
                    let language = Language.findOrCreate(code: lang)
                    try! realm.write {
                        self.langArray.append(language)
                    }
                })
            
        }
        
        
        if let courseArray = data["joinedCourse"] as? [NSDictionary] {
            try! realm.write {
                User.currentUser?.joinedCourse.removeAll()
            }
            for courseData in courseArray {
                if let course = Course.createOrUpdateCourse(courseData) {
                    try! realm.write {
                        self.joinedCourse.append(course)
                    }
                }
            }
        }
        
        if let roomArray = data["joinedRoom"] as? [NSDictionary] {
            try! realm.write {
                User.currentUser?.joinedRoom.removeAll()
            }
            for roomData in roomArray {
                if let room = Room.createOrUpdateRoomWithData(data: roomData, isToUser: false) {
                    try! realm.write {
                        self.joinedRoom.append(room)
                    }
                }
            }
        }
        
        if let contactsArray = data["contacts"] as? [NSDictionary] {
            for contactData in contactsArray {
                if let room = Room.createOrUpdateRoomWithData(data: contactData, isToUser: true) {
                    try! realm.write {
                        self.joinedRoom.append(room)
                    }
                }
//                User.createOrUpdateUserWithData(contactData)
            }
        }
        
        
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
    
    func joinRoom(_ room:Room) {
        if room.isToUser == true && room.id == self.id {
            return
        }
        
        let realm = try! Realm()
        let roomIndex = self.joinedRoom.index { (userroom) -> Bool in
            return userroom.id == room.id
        }
        if roomIndex == nil {
            try! realm.write {
                room.lastUpdateTime = NSDate()
                self.joinedRoom.append(room)
            }
        }
    }
    
    func joinRoomWithData(_ roomData: [NSDictionary]?) {
        if roomData == nil { return }
        for roomData in roomData! {
            if let room = Room.createOrUpdateRoomWithData(data: roomData, isToUser: false) {
                self.joinRoom(room)
            }
        }
    }
    
    func quitRoom(_ roomId:String) {
        let realm = try! Realm()
        if let room = realm.object(ofType: Room.self, forPrimaryKey: roomId) {
            if room.isToUser {
                let roomMessage = realm.objects(Message.self).filter("(senderId = '\(roomId)' OR toRoom = '\(roomId)') AND isToUser = true")
                try! realm.write {
                    realm.delete(roomMessage)
                }
            }
        }
        let roomIndex = self.joinedRoom.index { (userroom) -> Bool in
            return userroom.id == roomId
        }
        if roomIndex != nil {
            try! realm.write {
                self.joinedRoom.remove(objectAtIndex: roomIndex!)
            }
        }
    }
    
    func joinCourse(_ course:Course) {
        let realm = try! Realm()
        let courseIndex = self.joinedCourse.index { (usercourse) -> Bool in
            return usercourse.id == course.id
        }
        if courseIndex == nil {
            try! realm.write {
                self.joinedCourse.append(course)
            }
        }
    }
    
    func joinCourseWithData(_ courseData:[NSDictionary]?) {
        if courseData == nil { return }
        for courseData in courseData! {
            if let course = Course.createOrUpdateCourse(courseData) {
                self.joinCourse(course)
            }
        }
    }
    
    func quitCourse(_ courseId:String) {
        let realm = try! Realm()
        let courseIndex = self.joinedCourse.index { (usercourse) -> Bool in
            return usercourse.id == courseId
        }
        if courseIndex != nil {
            try! realm.write {
                self.joinedCourse.remove(objectAtIndex: courseIndex!)
                let rooms = realm.objects(Room.self).filter({ (room) -> Bool in
                    return room.courseID == courseId
                })
                realm.delete(rooms)

            }
        }
    }
    
    func setLang(_ langArr:[String]) {
        let realm = try! Realm()
        try! realm.write {
            self.langArray.removeAll()
            langArr.forEach { (lang) in
                self.langArray.append(Language.findOrCreate(code: lang))
            }
        }
        
    }
    
    func hasJoinedCourse(_ courseId: String) -> Bool {
        let courseIndex = self.joinedCourse.index { (usercourse) -> Bool in
            return usercourse.id == courseId
        }
        return courseIndex == nil ? false : true
    }
    
    func hasJoinedRoom(_ roomId: String) -> Bool {
        let roomIndex = self.joinedRoom.index { (userroom) -> Bool in
            print("\(userroom.id) : \(roomId)")
            return userroom.id == roomId
        }
        print("joinedroom: \(roomIndex)")
        return roomIndex == nil ? false : true
    }
    
    
    func countUnread() -> Int {
        var unreadCnt = 0
        self.joinedRoom.filter("silent = false").forEach { (room) in
            if !room.isToUser && room.id != self.id {
                unreadCnt += room.unread
            }
        }
        return unreadCnt
    }
    
}
