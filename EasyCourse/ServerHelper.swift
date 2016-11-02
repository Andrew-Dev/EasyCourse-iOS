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


class ServerHelper: NSObject {

    static let sharedInstance = ServerHelper()
    
    fileprivate let photoCache = AutoPurgingImageCache(
        memoryCapacity: 100 * 1024 * 1024,
        preferredMemoryUsageAfterPurge: 60 * 1024 * 1024
    )
    
    func getNetworkImage(_ urlString: String, completion: @escaping (_ data:Data?, _ error:NSError?) -> ()) {
//        return Alamofire.request(.GET, urlString).responseImage { (response) -> Void in
//            guard let image = response.result.value else { return }
//            completion(image)
//            self.cacheImage(image, urlString: urlString)
//        }
        let a = try! URLRequest(url: urlString, method: .get)
        Alamofire.request(a).responseData { (response) in
            guard let imageData = response.result.value else { return completion(nil, response.result.error as NSError?)}
            self.cacheImage(UIImage(data: imageData)!, urlString: urlString)
            completion(imageData, nil)
            
        }
        
        
//
//        
//        
//        Alamofire.request(.GET, urlString).responseData { (response) in
//            guard let imageData = response.result.value else { return completion(data: nil, error: response.result.error)}
//            self.cacheImage(UIImage(data: imageData)!, urlString: urlString)
//            completion(data: imageData, error: nil)
//            
//        }
    }
    
    //MARK: = Image Caching
    
    func cacheImage(_ image: Image, urlString: String) {
        photoCache.add(image, withIdentifier: urlString)
    }
    
    func cachedImage(_ urlString: String) -> UIImage? {
        return photoCache.image(withIdentifier: urlString)
    }
    
}
