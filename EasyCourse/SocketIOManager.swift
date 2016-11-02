//
//  SocketIOManager.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/5/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import SocketIO
import RealmSwift

class SocketIOManager: NSObject {
    
    static let sharedInstance = SocketIOManager()
    
    var socket:SocketIOClient!
    
    override init() {
        super.init()
    }
    
    func establishConnection() {
        socket = SocketIOClient(socketURL: URL(string: Constant.baseURL)!, config: [.connectParams(["token" : User.token!])])
//        socket = SocketIOClient(socketURL: URL(string: Constant.baseURL)!, config: [.connectParams(["token" : "asdf"])])
        socket.on("auth:error") { (obj, ack) in
            print("auth error")
            
        }
        socket.connect()
        
        self.publicListener()
        
    }
    
    func closeConnection() {
        print("close connection")
        socket.disconnect()
    }
    
    func syncUser() {
        socket.emit("syncUser", 1)
    }
    
    func logout(_ completion: @escaping (_ success:Bool, _ error:NSError?) -> ()) {
        if UserSetting.userDeviceToken != nil {
            socket.emit("logout", ["deviceToken":UserSetting.userDeviceToken!])
        } else {
            socket.emit("logout", 1)
        }
        
        socket.once("userDidLogout") { (obj, act) in
            print("logout : \(obj)")
            if obj[0] as? Bool == false {
                completion(false, nil)
                print("fail log out")
            } else {
                
                print("success log out")
                User.currentUser = nil
                User.token = nil
                RealmTools.setDefaultRealmForUser(nil)
                NotificationCenter.default.post(name: Constant.NotificationKey.UserDidLogout, object: nil)
                self.closeConnection()
                completion(true, nil)
            }
        }
    }
    
    func sendMessage(_ message:Message) {
        var param = ["id":"\(message.id!)"]
        if let toRoom = message.toRoom {
            if message.isToUser {
                param["toUser"] = toRoom
            } else {
                param["toRoom"] = toRoom
            }
        }
        if let text = message.text { param["text"] = text }
        if let imageUrl = message.imageUrl { param["imageUrl"] = imageUrl }
        if let imageWidth = message.imageWidth.value { param["imageWidth"] = "\(imageWidth)" }
        if let imageHeight = message.imageHeight.value { param["imageHeight"] = "\(imageHeight)" }
//        print("param message \(param)")
        socket.emit("message", param)
    }
    
    func searchRoom(_ text:String, limit:Int?, skip:Int?, completion: @escaping (_ rooms:[Room], _ error:NSError?) -> ()) {
        let localLimit = limit ?? 20
        let localSkip = skip ?? 0
//        socket.emit("searchRoom", ["text":text, "university":(User.currentUser?.universityID)!, "limit":"\(localLimit)", skip:"\(localSkip)"])
        
        
        socket.emit("searchRoom", ["text":text, "university":(User.currentUser?.universityID)!, "limit":localLimit, "skip":localSkip])
        socket.once("searchRoom") { (objects, ack) in
            var finalRooms:[Room] = []
            for object in objects {
                if (object as AnyObject).isKind(of: NSArray.self) {
                    for obj in object as! NSArray {
                        let room = Room()
                        if room.initRoomWithData(obj as! NSDictionary, isToUser: false) != nil {
                            finalRooms.append(room)
                        }
                    }
                } else {
                    let room = Room()
                    if room.initRoomWithData(object as! NSDictionary, isToUser: false) != nil {
                        finalRooms.append(room)
                    }
                }
            }
            completion(finalRooms, nil)
        }
    }
    
    func quitRoom(_ roomId:String, completion: @escaping (_ success:Bool, _ error:NSError?) -> ()) {
        socket.emit("quitRoom", roomId)
        socket.once("quitRoom") { (obj, ack) in
            self.socket.emit("syncUser", 1)
            completion(true, nil)
        }
    }
    
    func joinRoom(_ roomsId: [String], completion: @escaping (_ success:Bool, _ error:NSError?) -> ()) {
        socket.emit("joinRooms", roomsId)
        socket.once("joinRooms") { (obj, ack) in
            self.socket.emit("syncUser", 1)
            self.socket.once("syncUser", callback: { (objects, ack) in
                User.currentUser!.syncCurrentUserWithData(objects[0] as! NSDictionary)
                completion(true, nil)
            })
            
        }
    }
    
    func dropCourse(_ courseId:String, completion: @escaping (_ success:Bool, _ error:NSError?) -> ()) {
        socket.emit("dropCourse", courseId)
        socket.once("dropCourse") { (obj, ack) in
            self.socket.emit("syncUser", 1)
            self.socket.once("syncUser", callback: { (objects, ack) in
                User.currentUser!.syncCurrentUserWithData(objects[0] as! NSDictionary)
                completion(true, nil)
            })
        }
    }
    
    func joinCourse(_ roomsId: [String], completion: @escaping (_ success:Bool, _ error:NSError?) -> ()) {
        socket.emit("joinCourse", roomsId)
        socket.once("joinCourse") { (obj, ack) in
            self.socket.emit("syncUser", 1)
            completion(true, nil)
        }
    }
    
    func updateUser(_ username: String?, userProfileImageUrl:String?) {
        var data:[String:String] = [:]
        if username != nil { data["displayName"] = username! }
        if userProfileImageUrl != nil { data["avatarUrl"] = userProfileImageUrl! }
        if data != [:] {
            print("update data: \(data)")
            socket.emit("syncUser", data)
        }
    }
    
    func publicListener() {
        socket.on("connect") {data, ack in
            print("socket connected")
            self.socket.emit("syncUser", 1)
            
            
        }
        
        socket.on("syncUser") { (objects, ack) in
            print("object get : \(objects)")
            
            if User.currentUser == nil {
                User.currentUser = User().initCurrentUserWithData(objects[0] as! NSDictionary)
            } else {
                User.currentUser!.syncCurrentUserWithData(objects[0] as! NSDictionary)
            }
            
            NotificationCenter.default.post(name: Constant.NotificationKey.SyncUser, object: nil)
            print("syncUser received")
            
            // Get Hist Message
//            var updatedTime = NSDate().timeIntervalSince1970
            var params:[String:Any] = [:]
            if let lastUpdatedTime = try! Realm().objects(Message.self).filter("successSent != false").last?.createdAt {
                params["updatedTime"] = lastUpdatedTime.timeIntervalSince1970
            }
            let a = try! Realm().objects(Message.self).last?.text
            print("lastupdateTime: \(a), \(params["updatedTime"])")
            self.socket.emit("getHistMessage", params)
            
            // Get Contact Info
//            let realm = try! Realm()
//            let currentUserContacts = realm.objects(Room.self).filter("isGroupChat == false")
//            var incompleteContactsID:[String] = []
//            currentUserContacts.forEach({ (room) in
//                if realm.object(ofType: User.self, forPrimaryKey: room.id) == nil {
//                    incompleteContactsID.append(room.id!)
//                }
//            })
//            print("incomplete user: \(incompleteContactsID)")
//            self.socket.emit("getUserInfo", ["userList":incompleteContactsID])
            
        }
        
        socket.on("message") { (objects, ack) in
            for object in objects {
                //                print("one object: \(object)")

                if (object as AnyObject).isKind(of: NSArray.self) {
                    let a = object as! NSArray
                    print("new message [array] cnt=\(a.count)")
                    for obj in object as! NSArray {
                        print("message obj: \(obj)")
                        let newMessage = Message()
                        newMessage.initMessage(obj as! NSDictionary)
                        
                        if newMessage.senderId != User.currentUser!.id {
                            Message.saveSenderUserInfo(obj as! NSDictionary)
                            newMessage.saveToDatabase()
                        }
                    }
                } else {
                    print("message obj: \(object)")
                    print("new message [single]")
                    let newMessage = Message()
                    newMessage.initMessage(object as! NSDictionary)
                    Message.saveSenderUserInfo(object as! NSDictionary)
                    newMessage.saveToDatabase()
//                    if newMessage.senderId != User.currentUser!.id {
//                        Message().saveSenderUserInfo(object as! NSDictionary)
//                        newMessage.saveToDatabase()
//                    }
                }
                
//                NotificationCenter.default.post(name: Constant.NotificationKey.GetMessage, object: nil)
            }
//            print("objects: \(objects)")
//            print("new message recieve")
        }
        
        socket.on("message:success") { (obj, ack) in
            print("message sent success \(obj)")
            if (obj as AnyObject).isKind(of: NSArray.self), let receivedMsg = obj[0] as? [String:AnyObject] {
                
                if let localId = receivedMsg["localId"] as? String, let msg = receivedMsg["msg"] as? NSDictionary {
                    let realm = try! Realm()
                    if let message = realm.object(ofType: Message.self, forPrimaryKey: localId) {
                        try! Realm().write {
                            message.successSent.value = true
                            if let remoteId = msg["_id"] as? String {
                                message.remoteId = remoteId
                            }
                            if let remoteCreated = msg["createdAt"] as? Double {
                                message.createdAt = Date(timeIntervalSince1970: remoteCreated)
                            }
                        }
                    }
                }
                
                
                
            } else {
                print("message success wrong callback")
            }
        }
        
        socket.on("message:error") { (obj, ack) in
            print("message sent error \(obj)")
            if (obj as AnyObject).isKind(of: NSArray.self), let msgId = obj[0] as? String {
                let realm = try! Realm()
                if let message = realm.object(ofType: Message.self, forPrimaryKey: msgId) {
                    try! Realm().write {
                        message.successSent.value = false
                    }
                }
            } else {
                print("message error wrong callback")
            }
        }
        
        socket.on("exception") { (obj, ack) in
            print(obj)
        }
        
        socket.on("auth:error") { (obj, ack) in
            print("auth error")
            
        }
        
        socket.on("getUserInfo:succuss") { (obj, ack) in
            print("get user info: \(obj)")
            
            
        }
    }
    
}
