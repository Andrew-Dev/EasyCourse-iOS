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
            if let sender = data["sender"] as? NSDictionary {
                self.senderId = sender["_id"] as? String
            }
            
            self.text = data["text"] as? String
            self.imageUrl = data["imageUrl"] as? String
            if let sharedRoomData = data["sharedRoom"] as? NSDictionary,
                let sharedRoomId = sharedRoomData["_id"] as? String {
                self.sharedRoom = sharedRoomId
                _ = Room.createOrUpdateRoomWithData(data: sharedRoomData, isToUser: false)
            }
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
    
    internal class func createOrUpdateMessage(_ data:NSDictionary) {
        guard let id = data["_id"] as? String else {
            return
        }
        
        let text = data["text"] as? String
        let imageUrl = data["imageUrl"] as? String
        let sharedRoomData = data["sharedRoom"] as? NSDictionary
        if text == nil && imageUrl == nil && sharedRoomData == nil {
            return
        }
        
        var messageAlreadyExist = false
        var message = Message()
        let realm = try! Realm()
        if let msg = realm.object(ofType: Message.self, forPrimaryKey: id) {
            message = msg
            messageAlreadyExist = true
        } else if let msg = realm.objects(Message.self).filter("remoteId = '\(id)'").last {
            message = msg
            messageAlreadyExist = true
        } else {
            try! realm.write {
                message.id = id
                realm.add(message)
            }
        }
        
        try! realm.write {
            if let sender = data["sender"] as? NSDictionary {
                message.senderId = sender["_id"] as? String
            }
            
            message.text = data["text"] as? String
            message.imageUrl = data["imageUrl"] as? String
            if let sharedRoomData = data["sharedRoom"] as? NSDictionary,
                let sharedRoomId = sharedRoomData["_id"] as? String {
                message.sharedRoom = sharedRoomId
            }
            if let toRoom = data["toRoom"] as? String {
                message.toRoom = toRoom
                message.isToUser = false
            }
            if let toUser = data["toUser"] as? String {
                message.toRoom = toUser
                message.isToUser = true
            }
            message.imageWidth.value = data["imageWidth"] as? Float
            message.imageHeight.value = data["imageHeight"] as? Float
            if let dateString = data["createdAt"] as? String {
                message.createdAt = dateString.stringToDate()
            } else {
                message.createdAt = Date()
            }
        }
        
        if let sharedRoomData = data["sharedRoom"] as? NSDictionary,
            let _ = sharedRoomData["_id"] as? String {
            _ = Room.createOrUpdateRoomWithData(data: sharedRoomData, isToUser: false)
        }
        
        // Save sender
        saveSenderUserInfo(data)
        
        // Save room
        if message.toRoom == nil { return }
        let roomId = message.isToUser ? message.senderId : message.toRoom
        if let room = realm.object(ofType: Room.self, forPrimaryKey: roomId) {
            if User.currentUser?.joinedRoom.index(of: room) == nil {
                try! realm.write {
                    User.currentUser?.joinedRoom.append(room)
                }
            }
            if !messageAlreadyExist {
                try! realm.write {
                    room.messageList.append(message)
                    room.unread += 1
                }
                Tools.sharedInstance.setTabBarBadge()
            }
        } else {
            let room = Room()
            room.id = roomId
            room.messageList.append(message)
            room.unread += 1
            Tools.sharedInstance.setTabBarBadge()
            room.isToUser = message.isToUser
            try! realm.write {
                User.currentUser?.joinedRoom.append(room)
            }
        }
        
        // Update lastGetMessageTime
        User.currentUser?.setLastMsgUpdateTime(message.createdAt!)
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
    
    internal class func saveSenderUserInfo(_ data:NSDictionary) {
//        print("start cache")
        if let sender = data["sender"] as? NSDictionary,
            let senderId = sender["_id"] as? String {
            let realm = try! Realm()
            if let dbUser = realm.object(ofType: User.self, forPrimaryKey: senderId) {
                print("ready to update user")
                try! realm.write {
                    print("updating user")
                    if let username = sender["displayName"] as? String {
                        dbUser.username = username
                    }
                    if let profilePictureUrl = sender["avatarUrl"] as? String {
                        dbUser.profilePictureUrl = profilePictureUrl
                    }
                }
            } else {
                let user = User()
                user.id = senderId
                if let username = sender["displayName"] as? String {
                    user.username = username
                }
                if let profilePictureUrl = sender["avatarUrl"] as? String {
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
        var roomID = self.isToUser ? self.senderId : self.toRoom
        if self.isToUser {
            if self.senderId == User.currentUser?.id {
                roomID = self.toRoom
            } else {
                roomID = self.senderId
            }
        } else {
            roomID = self.toRoom
        }
        print("save the room: \(roomID) + \(self)")
        if let room = realm.object(ofType: Room.self, forPrimaryKey: roomID) {
            User.currentUser?.joinRoom(room)
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
            room.id = roomID
            room.messageList.append(self)
            room.unread += 1
            room.isToUser = true
            Tools.sharedInstance.setTabBarBadge()
            try! realm.write {
                User.currentUser?.joinedRoom.append(room)
            }
        }
    }
    
}
