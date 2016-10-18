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
    let successSent = RealmOptional<Bool>()
    let imageWidth = RealmOptional<Float>()
    let imageHeight = RealmOptional<Float>()
    
    dynamic var roomId:String? = nil
    dynamic var createdAt:Date? = nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["createdAt"]
    }
    
    func initMessage(_ data:NSDictionary) {
        if let id = data["_id"] as? String {
            //            print("init date: \(data["createdAt"] as? NSDate)")
            self.id = id
            self.senderId = data["sender"] as? String
//            message.senderName = data["senderName"] as? String
            self.text = data["text"] as? String
            self.imageUrl = data["imageUrl"] as? String
            self.roomId = data["room"] as? String
            self.imageWidth.value = data["imageWidth"] as? Float
            self.imageHeight.value = data["imageHeight"] as? Float
            if let interval = data["createdAt"] as? Double {
                self.createdAt = Date(timeIntervalSince1970: interval)
            } else {
                //                message.createdAt = NSDate()
            }
            //            print("create at: \(message.createdAt)")
        }
//        return self
    }
    
    func initForCurrentUser(_ text: String?, imageUrl: String?, image: UIImage?, roomId: String) {
        self.text = text
        self.imageUrl = imageUrl
        
        self.roomId = roomId
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
    
    internal func saveSenderUserInfo(_ data:NSDictionary) {
//        print("start cache")
        if let senderId = data["sender"] as? String,
            let username = data["senderName"] as? String {
            
            let user = User()
            user.id = senderId
            user.username = username
            if let profilePictureUrl = data["avatarUrl"] as? String {
                user.profilePictureUrl = profilePictureUrl
            }
            let realm = try! Realm()
            try! realm.write {
                realm.add(user, update: true)
            }
        }
    }
    
    
    func saveToDatabase() {
        
        let realm = try! Realm()
        if let room = realm.object(ofType: Room.self, forPrimaryKey: self.roomId) {
            
            if realm.object(ofType: Message.self, forPrimaryKey: self.id) == nil {
                print("save msg to db: \(self.text))")
                try! realm.write({
                    room.messageList.append(self)
                    room.unread += 1
                })
            } else {
                print("message already exist")
            }
        } else {
            try! realm.write({
                realm.add(self, update: true)
            })
        }
    }
    
}
