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
import AwesomeCache
import SwiftyJSON

class SocketIOManager: NSObject {
    
    static let sharedInstance = SocketIOManager()
    
    let timeoutSec = 5
    var socket:SocketIOClient!
    
    enum loadtype {
        case cacheAndLoad, cacheOnly, loadOnly
    }
    
    override init() {
        super.init()
    }
    
    
    
    func establishConnection() {
        socket = SocketIOClient(socketURL: URL(string: Constant.baseURL)!, config: [.connectParams(["token" : User.token!])])
//        socket = SocketIOClient(socketURL: URL(string: Constant.baseURL)!, config: [.connectParams(["token" : "asdf"])])

        
        socket.connect()
//        socket.connect(timeoutAfter: 3) { 
//            MessageAlert.sharedInstance.setupConnectionStatus()
//        }
       
        self.publicListener()
        
    }
    
    func closeConnection() {
        print("close connection")
        socket.disconnect()
    }
    
    
    
    func logout(_ completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
        var params:[String:Any] = [:]
        if UserSetting.userDeviceToken != nil {
            params["deviceToken"] = UserSetting.userDeviceToken!
        }
        
        socket.emitWithAck("logout", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                print("fail log out")
                return completion(false, err)
            }
            
            guard let arg0 = data[0] as? NSDictionary else {
                return completion(false, NetworkError.ParseJSONError)
            }
            
            guard let success = arg0["success"] as? Bool else {
                return completion(false, NetworkError.ParseJSONError)
            }
            
            if success {
                print("success log out")
                User.currentUser = nil
                User.token = nil
                RealmTools.setDefaultRealmForUser(nil)
                NotificationCenter.default.post(name: Constant.NotificationKey.UserDidLogout, object: nil)
                self.closeConnection()
                completion(true, nil)
            } else {
                completion(false, NetworkError.ParseJSONError)
            }
            
        }

    }
    
    func sendMessage(_ message:Message, completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
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
        if let sharedRoom = message.sharedRoom { param["sharedRoom"] = "\(sharedRoom)" }
//        print("param message \(param)")
        socket.emitWithAck("message", param).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: true) {
                print("get in check")
                try! Realm().write {
                    message.successSent.value = false
                }
                return completion(false, err)
            }
            
            guard let messageData = data[0] as? NSDictionary else {
                return completion(false, NetworkError.ParseJSONError)
            }
            print("res msg data: \(messageData)")
            do {
                try self.updateMessageInDatabase(message: message, resData: messageData)
            } catch let error as NetworkError {
                completion(false, error)
            } catch {
                completion(false, nil)
            }
            
            completion(true, nil)
            
            
            
        }
    }
    
    func searchRoom(_ text:String, limit:Int?, skip:Int?, completion: @escaping (_ rooms:[Room], _ error:NetworkError?) -> ()) {
        let localLimit = limit ?? 20
        let localSkip = skip ?? 0

        socket.emitWithAck("searchRoom", ["text":text, "university":(User.currentUser?.universityId)!, "limit":localLimit, "skip":localSkip]).timingOut(after: timeoutSec) { (data) in

            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion([], err)
            }
            
            guard let arg0 = data[0] as? NSDictionary else {
                return completion([], NetworkError.ParseJSONError)
            }
            
            guard let roomArray = arg0["room"] as? NSArray else {
                return completion([], NetworkError.ParseJSONError)
            }
            
            
            
            var finalRooms:[Room] = []
            roomArray.forEach({ (roomData) in
                if let roomDataDict = roomData as? NSDictionary {
                    let room = Room()
                    if room.initRoomWithData(roomDataDict, isToUser: false) != nil {
                        finalRooms.append(room)
                    }
                }
            })
            
//            if data[0] is NSArray {
//                for roomData in data[0] as! NSArray {
//                    let room = Room()
//                    if room.initRoomWithData(roomData as! NSDictionary, isToUser: false) != nil {
//                        finalRooms.append(room)
//                    }
//                }
//            }

            completion(finalRooms, nil)
        }
    }
    
    func getRoomInfo(_ roomId:String, refresh:Bool, completion: @escaping (_ room:Room?, _ error:NetworkError?) -> ()) {
        print("get room inf: \(roomId)")
        
        if !refresh {
            if let room = ServerHelper.sharedInstance.getRoomFromCache(id: roomId) {
                print("get room from cache")
                return completion(room, nil)
            }
        }
        
        
        let params = ["roomId":roomId]
        socket.emitWithAck("getRoomInfo", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                print("get room info error")
                return completion(nil, err)
            }
            
            guard let arg0 = data[0] as? NSDictionary else {
                return completion(nil, NetworkError.ParseJSONError)
            }
            
            guard let roomData = arg0["room"] as? NSDictionary else {
                return completion(nil, NetworkError.ParseJSONError)
            }
            print("data: \(roomData)")
            
            ServerHelper.sharedInstance.cacheObject(.RoomInfo, id: roomId, data: roomData)
            let room = Room().initRoomWithData(roomData, isToUser: false)
            return completion(room, nil)
            
        }
    }
    
    func getRoomMembers(_ roomId:String, limit:Int, skip:Int, refresh:Bool, completion: @escaping (_ userList:[User]?, _ error:NetworkError?) -> ()) {
        print("get room inf: \(roomId)")
        
        if !refresh {
            //TODO
        }
        
        
        let params = ["roomId":roomId]
        socket.emitWithAck("getRoomMembers", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                print("get room info error")
                return completion(nil, err)
            }
            
            guard let room = try! Realm().object(ofType: Room.self, forPrimaryKey: roomId) else {
                return completion(nil, NetworkError.LocalError(reason: "No room in local"))
            }
            
            let json = JSON(data)
            if let userArray = json[0]["users"].arrayObject {
                var userList:[User] = []
                userArray.forEach({ (userData) in
//                    print("user Data: \(userData)")
                    if let userDataDic = userData as? NSDictionary {
                        if let user = User.createOrUpdateUserWithData(userDataDic) {
                            userList.append(user)
                            if room.memberList.index(of: user) == nil {
                                try! Realm().write {
                                    room.memberList.append(user)
                                }
                            } else {
                                print("existed")
                            }
                        }
                    }
                })
                return completion(userList, nil)
            } else {
                print("error: \(json[0]["users"].error?.localizedDescription)")
                return completion(nil, NetworkError.ParseJSONError)
            }
            
        }
    }
    
    func createRoom(_ name:String, course:String?, completion: @escaping (_ room:Room?, _ error:NetworkError?) -> ()) {
        var params = ["name":name]
        if course != nil {
            params["course"] = course
        }
        socket.emitWithAck("createRoom", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion(nil, err)
            }
            
            guard let arg0 = data[0] as? NSDictionary else {
                return completion(nil, NetworkError.ParseJSONError)
            }
            
            guard let roomData = arg0["room"] as? NSDictionary else {
                return completion(nil, NetworkError.ParseJSONError)
            }
            
            
            print("create data: \(roomData)")
            let room = Room()
            room.initRoomWithData(roomData, isToUser: false)?.saveToDatabase()
            completion(room, nil)
        }
    }

    
    func quitRoom(_ roomId:String, deleteRoom: Bool, completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
        let params = ["roomId":roomId]
        socket.emitWithAck("quitRoom", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion(false, err)
            }
            
            guard let arg0 = data[0] as? NSDictionary else {
                return completion(false, NetworkError.ParseJSONError)
            }
            
            guard let success = arg0["success"] as? Bool else {
                return completion(false, NetworkError.ParseJSONError)
            }
            
            if success {
                print("success quit room")
                
                if deleteRoom {
                    let realm = try! Realm()
                    if let quitRoom = realm.object(ofType: Room.self, forPrimaryKey: roomId) {
                        try! realm.write {
                            realm.delete(quitRoom)
                        }
                    }

                }
                completion(true, nil)
            } else {
                completion(false, NetworkError.ServerError(reason: nil))
            }
            
        }
    }
    
    func joinRoom(_ roomId: String, completion: @escaping (_ room:Room?, _ error:NetworkError?) -> ()) {
        let params = ["roomId":roomId]
        socket.emitWithAck("joinRoom", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion(nil, err)
            }
            
            guard let arg0 = data[0] as? NSDictionary else {
                return completion(nil, NetworkError.ParseJSONError)
            }
            
            guard let roomData = arg0["room"] as? NSDictionary else {
                return completion(nil, NetworkError.ParseJSONError)
            }
            print("join room data: \(roomData)")
            
            let room = Room()
            room.initRoomWithData(roomData, isToUser: false)?.saveToDatabase()
            completion(room, nil)

        }
    }
    
    func dropCourse(_ courseId:String, completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
        let params = ["courseId":courseId]
        socket.emitWithAck("dropCourse", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion(false, err)
            }
            
            guard let arg0 = data[0] as? NSDictionary else {
                return completion(false, NetworkError.ParseJSONError)
            }
            
            guard let success = arg0["success"] as? Bool else {
                return completion(false, NetworkError.ParseJSONError)
            }
            
            if success {
                print("success drop course")
                let realm = try! Realm()
                if let dropCourse = realm.object(ofType: Course.self, forPrimaryKey: courseId) {
                    try! realm.write {
                        realm.delete(dropCourse)
                    }
                }
                completion(true, nil)
            } else {
                completion(false, NetworkError.ServerError(reason: nil))
            }
            
        }
    }
    
    func syncUser(_ username: String?, userProfileImageUrl:String?, completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
        var data:[String:String] = [:]
        if username != nil { data["displayName"] = username! }
        if userProfileImageUrl != nil { data["avatarUrl"] = userProfileImageUrl! }
        if data != [:] {
            self.syncUser(data, completion: { (success, error) in
                print("user get: \(data)")
                if success {
                    completion(true, nil)
                } else {
                    completion(false, error)
                }
            })
        }
        
    }
    
    func syncUser(_ data:[String:Any], completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
        socket.emitWithAck("syncUser", data).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                print("syncUser error \(err)")
                return completion(false, err)
            }
            
            guard let arg0 = data[0] as? NSDictionary else {
                return completion(false, NetworkError.ParseJSONError)
            }
            
            guard let userData = arg0["user"] as? NSDictionary else {
                return completion(false, NetworkError.ParseJSONError)
            }
//            print("user data: \(data)")
            
//            if User.currentUser == nil {
//                User.currentUser = User().initCurrentUserWithData(userData)
//            } else {
//                User.currentUser!.syncCurrentUserWithData(userData)
//            }
            User.currentUser = User.createOrUpdateUserWithData(userData)
            
            NotificationCenter.default.post(name: Constant.NotificationKey.SyncUser, object: nil)
            print("syncUser received")
            completion(true, nil)
        }
    }
    
    func getHistMessage(_ completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
        var params:[String:Any] = [:]
        if let lastUpdatedTime = try! Realm().objects(Message.self).filter("successSent != false").last?.createdAt {
            params["lastUpdateTime"] = lastUpdatedTime.timeIntervalSince1970 * 1000
        }

        let a = try! Realm().objects(Message.self).last?.text
        print("lastupdateTime: \(a), \(params["lastUpdateTime"])")
        socket.emitWithAck("getHistMessage", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                print("get histmsg error")
                return completion(false, err)
            }
            
            guard let arg0 = data[0] as? NSDictionary else {
                return completion(false, NetworkError.ParseJSONError)
            }
            
            guard let messageArray = arg0["msg"] as? NSArray else {
                return completion(false, NetworkError.ParseJSONError)
            }
            
            for obj in messageArray {
                print("hist message obj: \(obj)")
                self.saveMessageToDatabase(data: obj)
            }
            
            completion(true, nil)
            
        }
    }
    
    func getUserInfo(_ userId:String, refresh:Bool, completion: @escaping (_ user:User?, _ error:NetworkError?) -> ()) {
        print("get user inf: \(userId)")
        // Cache user
        if !refresh {
            if let user = try! Realm().object(ofType: User.self, forPrimaryKey: userId) {
                print("user get in database")
                return completion(user, nil)
            }
        }
        
        let params = ["userId":userId]
        socket.emitWithAck("getUserInfo", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                print("get room info error")
                return completion(nil, err)
            }
            print("data: \(data)")
            
            guard let arg0 = data[0] as? NSDictionary else {
                return completion(nil, NetworkError.ParseJSONError)
            }
            
            guard let userData = arg0["user"] as? NSDictionary else {
                return completion(nil, NetworkError.ParseJSONError)
            }

            let user = User.createOrUpdateUserWithData(userData)
//            user.initUserFromServerWithData(userData)?.saveToDatabase()
            return completion(user, nil)
        }
    }
    
    // MARK: - public listener
    func publicListener() {
        socket.on("connect") {data, ack in
            print("socket connected")
            MessageAlert.sharedInstance.setupConnectionStatus()
            self.syncUser([:], completion: { (success, error) in
                if success {
                    self.getHistMessage({ (histSuccess, histError) in
                        //
                    })
                }

            })
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
        

        socket.on("exception") { (obj, ack) in
            print(obj)
        }
        

        
        socket.on("disconnect") { (data, ack) in
            print("disconnect here \(self.socket.status.rawValue)")
            MessageAlert.sharedInstance.setupConnectionStatus()
        }
        
        socket.on("reconnect") { (data, ack) in
            print("reconnect here \(self.socket.status.rawValue)")
            MessageAlert.sharedInstance.setupConnectionStatus()
        }
        
        socket.on("reconnectAttempt") { (data, ack) in
            print("reconnectAttempt here \(self.socket.status.rawValue)")
            MessageAlert.sharedInstance.setupConnectionStatus()
        }
        
        socket.on("error") { (data, ack) in
            print("error here \(data) \(self.socket.status.rawValue)")
            MessageAlert.sharedInstance.setupConnectionStatus()
        }
        

    }
    
    // MARK: - private help function
    private func checkAckError(_ data:[Any], onlyCheckNetwork: Bool) -> NetworkError? {
        if let arg0 = data[0] as? String {
            if arg0 == "NO ACK" {
                return NetworkError.NoResponse
            }
        }
        if !onlyCheckNetwork, let arg0 = data[0] as? NSDictionary {
            if let error = arg0["error"] as? String {
                return NetworkError.ServerError(reason: error)
            }
        }
        return nil
    }
    
    private func saveMessageToDatabase(data: Any) {
        if !(data is NSDictionary) {
            return
        }
        let newMessage = Message()
        newMessage.initMessage(data as! NSDictionary)
        
        if newMessage.senderId != User.currentUser!.id {
            Message.saveSenderUserInfo(data as! NSDictionary)
            newMessage.saveToDatabase()
        }
    }
    
    private func updateMessageInDatabase(message:Message, resData:NSDictionary) throws {
        let realm = try! Realm()
        if let otherUserStatus = resData["otherUserStatus"] as? Int, message.isToUser {
            let otherUser = realm.object(ofType: User.self, forPrimaryKey: message.toRoom)
            try! realm.write {
                otherUser?.otherFriendStatus = otherUserStatus
            }
        }
        
        if let updatedMessage = resData["msg"] as? NSDictionary {
            try! realm.write {
                message.successSent.value = true
                if let remoteId = updatedMessage["_id"] as? String {
                    message.remoteId = remoteId
                }
                print("time==")
                if let remoteCreated = updatedMessage["createdAt"] as? String {
                    print("update remote date \(remoteCreated)")
                    message.createdAt = remoteCreated.stringToDate()
                }
            }
        } else {
            try! realm.write {
                message.successSent.value = false
            }
            throw NetworkError.ParseJSONError
        }
        
        if let errorReason = resData["error"] as? String {
            try! realm.write {
                message.successSent.value = false
            }
            throw NetworkError.ServerError(reason: errorReason)
        }
        
        if message.successSent.value == nil {
            try! realm.write {
                message.successSent.value = false
            }
        }
    }
    
}
