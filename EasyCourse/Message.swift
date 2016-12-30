//
//  Message.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/5/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import Foundation
import RealmSwift
//import Cache

class Message: Object {
    
    dynamic var id:String? = nil
    dynamic var remoteId:String? = nil
    dynamic var senderId:String? = nil
    dynamic var text:String? = nil
    dynamic var imageUrl:String? = nil
    dynamic var imageData:Data? = nil
    dynamic var sharedRoom:String? = nil
    let successSent = RealmOptional<Bool>()
    let imageWidth = RealmOptional<Float>()
    let imageHeight = RealmOptional<Float>()
    
    dynamic var toRoom:String? = nil
    dynamic var isToUser = true
    dynamic var createdAt:Date? = nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["createdAt"]
    }
    
    func initMessage(_ data:NSDictionary) {
        if let id = data["_id"] as? String {
            self.id = id
            self.senderId = data["sender"] as? String
            self.text = data["text"] as? String
            self.imageUrl = data["imageUrl"] as? String
            self.sharedRoom = data["sharedRoom"] as? String
            if let toRoom = data["toRoom"] as? String {
                self.toRoom = toRoom
                self.isToUser = false
            }
            if let toUser = data["toUser"] as? String {
                self.toRoom = toUser
                self.isToUser = true
            }
            self.imageWidth.value = data["imageWidth"] as? Float
            self.imageHeight.value = data["imageHeight"] as? Float
            if let dateString = data["createdAt"] as? String {
                self.createdAt = dateString.stringToDate()
            }
        }
//        return self
    }
    
    func initForCurrentUser(_ text: String?, image: UIImage?, sharedRoom: String?, toRoom: String?, isToUser: Bool) {
        self.text = text
        self.sharedRoom = sharedRoom
        
        self.toRoom = toRoom
        self.isToUser = isToUser
        if image != nil {
            self.imageHeight.value = Float(image!.size.height)
            self.imageWidth.value = Float(image!.size.width)
            let data = UIImageJPEGRepresentation(image!, 0)
            self.imageData = data
        }
        
        senderId = User.currentUser?.id
        createdAt = Date()
        id = UUID().uuidString
    }
    
//    internal func cacheSenderUserInfo(_ data:NSDictionary) {
//        print("start cache")
//        if let senderId = data["sender"] as? String,
//            let username = data["senderName"] as? String,
//            let profilePictureUrl = data["avatarUrl"] as? String {
//            
//            let userData = ["id":senderId, "username":username, "profilePictureUrl":profilePictureUrl]
//            userCache.add(senderId, object: JSON.Dictionary(userData))
//            
//            print("user cache added:\(userData)")
//        }
//    }
    
    internal class func saveSenderUserInfo(_ data:NSDictionary) {
//        print("start cache")
        if let senderId = data["sender"] as? String,
            let username = data["senderName"] as? String {
            
            let realm = try! Realm()
            if let dbUser = realm.object(ofType: User.self, forPrimaryKey: senderId) {
                print("ready to update user")
                try! realm.write {
                    print("updating user")
                    dbUser.username = username
                    if let profilePictureUrl = data["avatarUrl"] as? String {
                        dbUser.profilePictureUrl = profilePictureUrl
                    }
                }
            } else {
                let user = User()
                user.id = senderId
                user.username = username
                if let profilePictureUrl = data["avatarUrl"] as? String {
                    user.profilePictureUrl = profilePictureUrl
                }
                
                try! realm.write {
                    realm.add(user, update: true)
                }
            }
        }
    }
    
    
    func saveToDatabase() {
        
        let realm = try! Realm()
        let roomID = self.isToUser ? self.senderId : self.toRoom
        if let room = realm.object(ofType: Room.self, forPrimaryKey: roomID) {
            
            if realm.object(ofType: Message.self, forPrimaryKey: self.id) == nil {
                print("save msg to db: \(self.text))")
                try! realm.write {
                    print("saving: \(self.text))")
                    room.messageList.append(self)
                    room.unread += 1
                }

            } else {
                print("message already exist")
            }
        } else {
            let room = Room()
            room.id = self.toRoom
            room.messageList.append(self)
            room.unread += 1
            room.isToUser = true
            try! realm.write {
                realm.add(room, update: true)
            }
        }
    }
    
}
