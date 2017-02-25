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
import AudioToolbox


class SocketIOManager: NSObject {
    
    static let sharedInstance = SocketIOManager()
    
    let timeoutSec = 5
    var socket:SocketIOClient!
    
    enum LoadType {
        case cacheAndNetwork, NetworkOnly, cacheElseNetwork
    }
    
    override init() {
        super.init()
    }
    
    
    func establishConnection() {
        print("connect with token: \(User.token)")
        socket = SocketIOClient(socketURL: URL(string: Constant.baseURL)!, config: [.connectParams(["token" : User.token!])])
        print("socket is \(socket)")
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
                NotificationCenter.default.post(name: Constant.NotificationKey.UserDidLogout, object: nil)
                self.closeConnection()
                completion(true, nil)
            } else {
                completion(false, NetworkError.ParseJSONError)
            }
            
        }

    }
    
    func sendMessage(_ message:Message, completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
        var param = ["id":"\(message.id!)"] as [String:Any]
        if let toRoom = message.toRoom {
            if message.isToUser {
                param["toUser"] = toRoom
            } else {
                param["toRoom"] = toRoom
            }
        }
        if let text = message.text { param["text"] = text }
        if let imageData = message.imageData {
            param["imageData"] = imageData
            if let imageWidth = message.imageWidth.value { param["imageWidth"] = "\(imageWidth)" }
            if let imageHeight = message.imageHeight.value { param["imageHeight"] = "\(imageHeight)" }
        }
        
        if let sharedRoom = message.sharedRoom { param["sharedRoom"] = "\(sharedRoom)" }
//        print("param message \(param)")
        socket.emitWithAck("message", param).timingOut(after: timeoutSec) { (data) in
            print("res data: \(data)")
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
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
    
    // MARK: - Room & Contacts
    
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
//            print("data: \(roomData)")
            
            ServerHelper.sharedInstance.cacheObject(.RoomInfo, id: roomId, data: roomData)
            let room = Room().initRoomWithData(roomData, isToUser: false)
            return completion(room, nil)
            
        }
    }
    
    func getRoomMembers(_ roomId:String, limit:Int, skip:Int, refresh:Bool, completion: @escaping (_ userList:[User], _ error:NetworkError?) -> ()) {
        print("get room id: \(roomId)")
        
        if !refresh {
            //TODO
        }
        
        
        let params = ["roomId":roomId, "limit":limit, "skip":skip] as [String : Any]
        
        socket.emitWithAck("getRoomMembers", params).timingOut(after: timeoutSec) { (data) in
            print("get room members: \(data)")
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                print("get room info error")
                return completion([], err)
            }
            
            let json = JSON(data)
            if let userArray = json[0]["users"].arrayObject {
                var userList:[User] = []
                userArray.forEach({ (userData) in
                    if let userDataDic = userData as? NSDictionary {
                        if let user = User.createOrUpdateUserWithData(userDataDic) {
                            userList.append(user)
                        }
                    }
                })
                return completion(userList, nil)
            } else {
                print("error: \(json[0]["users"].error?.localizedDescription)")
                return completion([], NetworkError.ParseJSONError)
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
            guard let room = Room.createOrUpdateRoomWithData(data: roomData, isToUser: false) else {
                return completion(nil, NetworkError.ParseJSONError)
            }
//            room.initRoomWithData(roomData, isToUser: false)?.saveToDatabase()
            if User.currentUser?.joinedRoom.index(of: room) == nil {
                try! Realm().write {
                    room.lastUpdateTime = NSDate()
                    User.currentUser?.joinedRoom.append(room)
                }
            }
            completion(room, nil)
        }
    }

    
    func quitRoom(_ roomId:String, completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
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
                
                User.currentUser?.quitRoom(roomId)
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

            if let room = Room.createOrUpdateRoomWithData(data: roomData, isToUser: false) {
                User.currentUser?.joinRoom(room)
                completion(room, nil)
            } else {
                completion(nil, NetworkError.ParseJSONError)
            }
            

        }
    }
    
    func silentRoom(_ roomId: String, silent: Bool, completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
        let params = ["roomId":roomId, "silent":silent] as [String : Any]
        socket.emitWithAck("silentRoom", params).timingOut(after: timeoutSec) { (data) in
            print("data is : \(data)")
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion(false, err)
            }
            
            let json = JSON(data)
            if let success = json[0]["success"].bool {
                return completion(success, nil)
            } else {
                print("get course error: \(json[0]["success"].error?.localizedDescription)")
                return completion(false, NetworkError.ParseJSONError)
            }
            
            
        }
    }
    
    func silentFriend(_ userId: String, silent: Bool, completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
        let params = ["otherUser":userId, "silent":silent] as [String : Any]
        socket.emitWithAck("silentFriend", params).timingOut(after: timeoutSec) { (data) in
            print("data is : \(data)")
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion(false, err)
            }
            
            let json = JSON(data)
            if let success = json[0]["success"].bool {
                return completion(success, nil)
            } else {
                print("get course error: \(json[0]["success"].error?.localizedDescription)")
                return completion(false, NetworkError.ParseJSONError)
            }
            
            
        }
    }
    
    func removeFriend(_ userId: String, completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
        let params = ["otherUser":userId]
        socket.emitWithAck("removeFriend", params).timingOut(after: timeoutSec) { (data) in
            print("data is : \(data)")
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion(false, err)
            }
            
            let json = JSON(data)
            if let success = json[0]["success"].bool {
                User.currentUser?.quitRoom(userId)
                return completion(success, nil)
            } else {
                print("get course error: \(json[0]["success"].error?.localizedDescription)")
                return completion(false, NetworkError.ParseJSONError)
            }
            
            
        }
    }
    
    
    // MARK: - Course
    
    func getCourseInfo(_ courseId:String, loadType:LoadType, completion: @escaping (_ course:Course?, _ error:NetworkError?) -> ()) {
        
        let realm = try! Realm()
        if loadType != .NetworkOnly {
            if let crs = realm.object(ofType: Course.self, forPrimaryKey: courseId) {
                if loadType == .cacheAndNetwork {
                    completion(crs, nil)
                } else if loadType == .cacheElseNetwork {
                    return completion(crs, nil)
                }
            }
        }
        
        let params = ["courseId":courseId]
        socket.emitWithAck("getCourseInfo", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion(nil, err)
            }
            
            
            let json = JSON(data)
            guard let courseData = json[0]["course"].dictionaryObject else {
                print("get course error: \(json[0]["course"].error?.localizedDescription)")
                return completion(nil, NetworkError.ParseJSONError)
            }
            
            if let course = Course.createOrUpdateCourse(courseData as NSDictionary) {
                return completion(course, nil)
            } else {
                return completion(nil, NetworkError.ParseJSONError)
            }
            
        }
    }
    
    func getCourseSubrooms(_ text:String?, courseId:String, skip:Int, limit: Int, completion: @escaping (_ rooms: [Room]?, _ error:NetworkError?) -> ()) {

        var params = ["courseId":courseId, "skip":skip, "limit":limit] as [String : Any]
        if (text != nil) {
            params["text"] = text!
        }
        socket.emitWithAck("searchCourseSubrooms", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion(nil, err)
            }
            
            
            let json = JSON(data)
            guard let roomArrayData = json[0]["rooms"].arrayObject else {
                print("get course error: \(json[0]["rooms"].error?.localizedDescription)")
                return completion(nil, NetworkError.ParseJSONError)
            }
            
            var roomArray:[Room] = []
            for roomData in roomArrayData {
                if let data = roomData as? NSDictionary,
                    let room = Room.createOrUpdateRoomWithData(data: data, isToUser: false) {
                    roomArray.append(room)
                }
            }
            return completion(roomArray, nil)
            
        }
    }
    
    func searchCourse(_ text:String, universityId:String, limit:Int?, skip:Int?, completion: @escaping (_ courses:[Course], _ error:NetworkError?) -> ()) {
        var params = ["text":text, "university":universityId] as [String : Any]
        if (skip != nil) {
            params["skip"] = skip!
        }
        if (limit != nil) {
            params["limit"] = limit!
        }
        socket.emitWithAck("searchCourse", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion([], err)
            }
            
            
            let json = JSON(data)
            guard let courseArrayData = json[0]["course"].arrayObject else {
                print("get course error: \(json[0]["course"].error?.localizedDescription)")
                return completion([], NetworkError.ParseJSONError)
            }
            
            var courseArray:[Course] = []
            for courseData in courseArrayData {
                if let data = courseData as? NSDictionary,
                    let course = Course.createOrUpdateCourse(data) {
                    courseArray.append(course)
                }
            }
            return completion(courseArray, nil)
            
        }
    }
    
    func joinCourse(_ courses: [String], languages: [String]?, completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
        var params = ["courses":courses]
        if languages != nil { params["lang"] = languages! }
        socket.emitWithAck("joinCourse", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion(false, err)
            }
            
            guard let arg0 = data[0] as? NSDictionary else {
                return completion(false, NetworkError.ParseJSONError)
            }
            
            guard let success = arg0["success"] as? Bool else {
                return completion(false, NetworkError.ParseJSONError)
            }
            
            let json = JSON(data)

            
            if let courseData = json[0]["joinedCourse"].arrayObject {
                print("get course error: \(json[0]["joinedCourse"].error?.localizedDescription)")
                User.currentUser?.joinCourseWithData(courseData as? [NSDictionary])
            }
            
            if let roomData = json[0]["joinedRoom"].arrayObject {
                print("get course error: \(json[0]["joinedRoom"].error?.localizedDescription)")
                User.currentUser?.joinRoomWithData(roomData as? [NSDictionary])
            }
            
            if success {
                print("success join course")
                if languages != nil {
                    User.currentUser?.setLang(languages!)
                }
                completion(true, nil)
            } else {
                completion(false, NetworkError.ServerError(reason: nil))
            }
            
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
                User.currentUser?.quitCourse(courseId)
                completion(true, nil)
            } else {
                completion(false, NetworkError.ServerError(reason: nil))
            }
            
        }
    }
    
    //MARK: - User
    func syncUser(_ username: String?, userProfileImage:UIImage?, userLang:[String]?, completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
        var data:[String:Any] = [:]
        if username != nil { data["displayName"] = username! }
        if userLang != nil { data["userLang"] = userLang! }
        if userProfileImage != nil {
            let imageData = UIImageJPEGRepresentation(userProfileImage!, 1)
            data["avatarImage"] = imageData
        }
        self.syncUser(data, completion: { (success, error) in
            print("user get: \(data)")
            if success {
                completion(true, nil)
            } else {
                completion(false, error)
            }
        })

        
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
            
            User.currentUser = User.createOrUpdateUserWithData(userData)
            
            NotificationCenter.default.post(name: Constant.NotificationKey.SyncUser, object: nil)
            print("syncUser received")
            completion(true, nil)
        }
    }
    
    func getHistMessage(_ initial: Bool, completion: @escaping (_ success:Bool, _ error:NetworkError?) -> ()) {
        var params:[String:Any] = [:]
        
//        let beginUpdateMsgTime = Date()
        if initial {
            params["lastUpdateTime"] = Date().timeIntervalSince1970 * 1000 - 1000*60*60*24*7
        } else if let lastUpdatedTime = User.currentUser!.getLastMsgUpdateTime() {
            params["lastUpdateTime"] = lastUpdatedTime.timeIntervalSince1970 * 1000
        } else if let lastUpdatedTime = try! Realm().objects(Message.self).filter("successSent != false").last?.createdAt {
            params["lastUpdateTime"] = lastUpdatedTime.timeIntervalSince1970 * 1000
        }
        print("lastupdateTime: \(params["lastUpdateTime"])")

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
            
            print("hist message cnt: \(messageArray.count)")
            for obj in messageArray {
//                print("hist message obj: \(obj)")
//                self.saveMessageToDatabase(data: obj)
                if let data = obj as? NSDictionary {
                    Message.createOrUpdateMessage(data)
                }
            }
            
            completion(true, nil)
            
        }
    }
    
    func getUserInfo(_ userId:String, loadType:LoadType, completion: @escaping (_ user:User?, _ error:NetworkError?) -> ()) {
//        print("get user inf: \(userId)")
        if loadType != .NetworkOnly {
            if let user = try! Realm().object(ofType: User.self, forPrimaryKey: userId) {
                if loadType == .cacheAndNetwork {
                    completion(user, nil)
                } else if loadType == .cacheElseNetwork {
                    return completion(user, nil)
                }
            }
        }
        
        let params = ["userId":userId]
        socket.emitWithAck("getUserInfo", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                print("get room info error")
                return completion(nil, err)
            }
//            print("data: \(data)")
            
            guard let arg0 = data[0] as? NSDictionary else {
                return completion(nil, NetworkError.ParseJSONError)
            }
            
            guard let userData = arg0["user"] as? NSDictionary else {
                return completion(nil, NetworkError.ParseJSONError)
            }

            let user = User.createOrUpdateUserWithData(userData)
            return completion(user, nil)
        }
    }
    
    func getUniversityInfo(_ univId:String, loadType:LoadType, completion: @escaping (_ course:University?, _ error:NetworkError?) -> ()) {
        
        let realm = try! Realm()
        if loadType != .NetworkOnly {
            if let univ = realm.object(ofType: University.self, forPrimaryKey: univId) {
                if loadType == .cacheAndNetwork {
                    completion(univ, nil)
                } else if loadType == .cacheElseNetwork {
                    return completion(univ, nil)
                }
            }
        }
        
        let params = ["univId":univId]
        socket.emitWithAck("getUniversityInfo", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion(nil, err)
            }
            
            
            let json = JSON(data)
            guard let univData = json[0]["univ"].dictionaryObject else {
                print("get course error: \(json[0]["univ"].error?.localizedDescription)")
                return completion(nil, NetworkError.ParseJSONError)
            }
            
            if let univ = University.createOrUpdateUniversity(univData as NSDictionary) {
                return completion(univ, nil)
            } else {
                return completion(nil, NetworkError.ParseJSONError)
            }
            
        }
    }
    
    // MARK: - Tutor
    func registerTutor(_ courseId:String, grade:String, price:Int, description:String, completion: @escaping (_ tutor:Tutor?, _ error:NetworkError?) -> ()) {
        
        let params = ["courseId":courseId, "grade":grade, "price":price, "description":description] as [String : Any]
        socket.emitWithAck("createTutor", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion(nil, err)
            }
            print("data: \(data)")
            
            let json = JSON(data)
            
            if let tutorData = json[0]["tutor"].dictionary {
                return completion(nil, nil)
            } else {
                return completion(nil, NetworkError.ParseJSONError)
            }
        }
    }
    
    func getTutors(_ limit:Int?, skip:Int?, postedByUserOnly: Bool, completion: @escaping (_ tutors:[Tutor], _ error:NetworkError?) -> ()) {
        var params:[String:Any] = [:]
        if skip != nil {
            params["skip"] = skip!
        }
        if limit != nil {
            params["limit"] = limit!
        }
        if postedByUserOnly {
            params["postedByUser"] = postedByUserOnly
        }
        socket.emitWithAck("getTutors", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion([], err)
            }
            print("get tutor: \(data)")
            
            let json = JSON(data)
            guard let tutorArrayData = json[0]["tutor"].arrayObject else {
                print("get course error: \(json[0]["tutor"].error?.localizedDescription)")
                return completion([], NetworkError.ParseJSONError)
            }
            
            var tutorArray:[Tutor] = []
            for tutorData in tutorArrayData {
                if let data = tutorData as? NSDictionary {
                    if let tutor = Tutor(data: data) {
                        tutorArray.append(tutor)
                    }
                }
            }
            return completion(tutorArray, nil)
            
        }
    }
    
    
    func getTutorStudents(_ limit:Int?, skip:Int?, pending: Bool, completion: @escaping (_ tutors:[TutorStudent], _ error:NetworkError?) -> ()) {
        var params:[String:Any] = [:]
        if skip != nil {
            params["skip"] = skip!
        }
        if limit != nil {
            params["limit"] = limit!
        }
        params["pending"] = pending
        socket.emitWithAck("getTutorStudents", params).timingOut(after: timeoutSec) { (data) in
            if let err = self.checkAckError(data, onlyCheckNetwork: false) {
                return completion([], err)
            }
            print("get tutor: \(data)")
            
            let json = JSON(data)
            guard let studentArrayData = json[0]["students"].arrayObject else {
                print("get course error: \(json[0]["students"].error?.localizedDescription)")
                return completion([], NetworkError.ParseJSONError)
            }
            
            var studentsArray:[TutorStudent] = []
            for studentData in studentArrayData {
                guard let studentDataDict = studentData as? NSDictionary else {
                    continue
                }
                guard let userData = studentDataDict["user"] as? NSDictionary else {
                    continue
                }
                guard let statusData = studentDataDict["status"] as? String else {
                    continue
                }
                if let student = User.createOrUpdateUserWithData(userData) {
                    if let tutorStudent = try? TutorStudent(_user: student, _status: statusData) {
                        studentsArray.append(tutorStudent)
                    }
                }
            }
            return completion(studentsArray, nil)
            
        }
    }
    
    // MARK: - public listener
    func publicListener() {
        socket.on("connect") {data, ack in
            print("socket connected")
            MessageAlert.sharedInstance.setupConnectionStatus()
            self.syncUser([:], completion: { (success, error) in
                if success {
                    self.getHistMessage(false, completion: { (success, error) in
                        //
                    })
                }

            })
            
        }
        
        socket.on("message") { (objects, ack) in
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            AudioServicesPlayAlertSound(1003)
            

            for object in objects {
                //                print("one object: \(object)")

                if (object as AnyObject).isKind(of: NSArray.self) {
                    let a = object as! NSArray
                    print("new message [array] cnt=\(a.count)")
                    for obj in object as! NSArray {
                        print("message obj: \(obj)")
                        if let data = object as? NSDictionary {
                            Message.createOrUpdateMessage(data)
                        }
                    }
                } else {
                    print("message [single]: \(object)")
                    if let data = object as? NSDictionary {
                        Message.createOrUpdateMessage(data)
                    }
                }
            }
        }
        
        socket.on("iOSUpdate") { (obj, ack) in
            print("ios update: \(obj)")
            guard let updateData = obj[0] as? NSDictionary else {
                return
            }
            guard let updateVersion = updateData["version"] as? Double else {
                return
            }
            let updateTitle = updateData["updateTitle"] as? String ?? "Update"
            let updateMessage = updateData["updateMessage"] as? String ?? "There is an update on app store. Please take a look."
            let forceUpdate = updateData["forceUpdate"] as? Bool ?? false
            let link = updateData["updateLink"] as? String ?? "https://itunes.apple.com/us/app/easycourse-chatroom-designed/id1157252902?ls=1&mt=8"
            
            
            let dictionary = Bundle.main.infoDictionary!
            if let version = dictionary["CFBundleShortVersionString"] as? String, let build = dictionary["CFBundleVersion"] as? String {
                if let localVersion = Double("\(version)") {
                    if localVersion < updateVersion {
                        Tools.sharedInstance.showUpdateAlert(title: updateTitle, message: updateMessage, forceUpdate: forceUpdate, link: link)
                    }
                }
            }
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
            let json = JSON(data)
            print("json: \(json)")
            if json[0].string == "auth" {
                // MARK: auth error log out
                NotificationCenter.default.post(name: Constant.NotificationKey.UserDidLogout, object: nil)
                self.closeConnection()
            }
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
    
    private func updateMessageInDatabase(message:Message, resData:NSDictionary) throws {
        let realm = try! Realm()
//        if let otherUserStatus = resData["otherUserStatus"] as? Int, message.isToUser {
//            let otherUser = realm.object(ofType: User.self, forPrimaryKey: message.toRoom)
//            try! realm.write {
//                otherUser?.otherFriendStatus = otherUserStatus
//            }
//        }
        
        if let updatedMessage = resData["msg"] as? NSDictionary {
            try! realm.write {
                message.successSent.value = true
                if let remoteId = updatedMessage["_id"] as? String {
                    message.remoteId = remoteId
                }
                if let remoteCreated = updatedMessage["createdAt"] as? String {
                    message.createdAt = remoteCreated.stringToDate()
                }
            }
            
            User.currentUser?.setLastMsgUpdateTime(message.createdAt!)

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
