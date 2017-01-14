//
//  ServerHelper.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/16/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import AwesomeCache

class ServerHelper: NSObject {

    enum objectType:String {
        case RoomInfo = "RoomInfo"
        case UserInfo = "UserInfo"
        case RoomMembers = "RoomMembers"
    }
    
    static let sharedInstance = ServerHelper()
    
    fileprivate let photoCache = AutoPurgingImageCache(
        memoryCapacity: 1000 * 1024 * 1024,
        preferredMemoryUsageAfterPurge: 600 * 1024 * 1024
    )
    
    func getNetworkImageData(_ urlString: String, completion: @escaping (_ data:Data?, _ error:NSError?) -> ()) {
        do {
            let a = try URLRequest(url: urlString, method: .get)
            Alamofire.request(a).responseData { (response) in
                guard let imageData = response.result.value else { return completion(nil, response.result.error as NSError?)}
                self.cacheImage(UIImage(data: imageData)!, urlString: urlString)
                completion(imageData, nil)
            }
        } catch {
            completion(nil, NSError())
        }

    }
    
    func getNetworkImage(_ urlString: String, completion: @escaping (_ image:Image?, _ cached:Bool, _ error:NSError?) -> ()) {
        
        if let cachedImage = cachedImage(urlString) {
            print("cached Image")
            return completion(cachedImage, true, nil)
        }
        print("no Image")
        do {
            let a = try URLRequest(url: urlString, method: .get)
            Alamofire.request(a).responseData { (response) in
                guard let imageData = response.result.value else { return completion(nil, false, response.result.error as NSError?)}
                self.cacheImage(UIImage(data: imageData)!, urlString: urlString)
                completion(UIImage(data: imageData)!, false, nil)
            }
        } catch {
            completion(nil, false, NSError())
        }
        
    }
    
    //MARK: - Image Caching
    
    func cacheImage(_ image: Image, urlString: String) {
        photoCache.add(image, withIdentifier: urlString)
    }
    
    func cachedImage(_ urlString: String) -> UIImage? {
        return photoCache.image(withIdentifier: urlString)
    }
    
    //MARK: - Object Caching
    func cacheObject(_ type: objectType, id: String, data: NSDictionary) {
        let cacheName = type.rawValue
        do {
            let cache = try Cache<NSDictionary>(name: cacheName)
            cache.setObject(data, forKey: id)
        } catch _ {
            print("cache error")
        }
    }
    
    func getRoomFromCache(id:String) -> Room? {
        do {
            let cache = try Cache<NSDictionary>(name: objectType.RoomInfo.rawValue)
            if let roomData = cache.object(forKey: id) {
                return Room().initRoomWithData(roomData, isToUser: false)
            }
            return nil
        } catch _ {
            print("cache error")
            return nil
        }
    }
    
    func getUserFromCache(id:String) -> User? {
        do {
            let cache = try Cache<NSDictionary>(name: objectType.UserInfo.rawValue)
            if let userData = cache.object(forKey: id) {
                return User.createOrUpdateUserWithData(userData)
            }
            return nil
        } catch _ {
            print("cache error")
            return nil
        }
    }
    
    func getUserFromCacahe(id:String) -> User? {
        do {
            let cache = try Cache<NSArray>(name: objectType.UserInfo.rawValue)
            
            return nil
        } catch _ {
            print("cache error")
            return nil
        }
    }
}



