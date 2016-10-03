//
//  ServerConstant.swift
//  EasyCourse
//
//  Created by ZengJintao on 8/31/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import Foundation
import Alamofire
import RealmSwift
import KeychainSwift
//import Cache
import FBSDKLoginKit



class ServerConst {
    
    static let sharedInstance = ServerConst()
    
    //MARK: - Auth
    func signupWithEmail(_ email:String, password:String, username:String, completion: @escaping (_ success:Bool, _ error:Error?) -> ()) {
        
        let apiUrl = URL(string: "\(Constant.baseURL)/signup")
        let params = ["email": email, "password": password, "displayName": username] as Parameters

        Alamofire.request(apiUrl!, method: .post, parameters: params, encoding: JSONEncoding.default, headers: ["isMobile":"true"]).responseJSON { (response) in
            print(response.result.error)
            if response.result.error != nil {
                completion(false, response.result.error)
            } else {
                print(response.result.value)
                if let token = response.response?.allHeaderFields["Auth"] as? String {
                    User.token = token
                } else {
                    return completion(false, nil)
                }
                self.setupCurrentUserWithData(response.result.value as! NSDictionary)
                completion(true, nil)
            }
        }
    }
    
    func loginWithEmail(_ email:String, password:String, completion: @escaping (_ success:Bool, _ error:Error?) -> ()) {
        
        let apiUrl = URL(string: "\(Constant.baseURL)/login")
        let params = ["email": email, "password": password] as Parameters
        
        Alamofire.request(apiUrl!, method: .post, parameters: params, encoding: JSONEncoding.default, headers: ["isMobile":"true"]).responseJSON { (response) in
            if response.result.error != nil {
                completion(false, response.result.error)
            } else {
                print(response.result)
                print("==")
                print(response.response?.allHeaderFields["Auth"] as? String ?? "no auth")
                if let token = response.response?.allHeaderFields["Auth"] as? String {
                    User.token = token
                } else {
                    return completion(false, nil)
                }
                
                self.saveDeviceTokenForUser({ (success, err) in
                    if success {
                        print("success save device token")
                        self.setupCurrentUserWithData(response.result.value as! NSDictionary)
                        //MARK: connect to server after login
                        SocketIOManager.sharedInstance.establishConnection()
                        completion(true, nil)
                    } else {
                        print("fail save device token")
                        self.setupCurrentUserWithData(response.result.value as! NSDictionary)
                        //MARK: connect to server after login
                        SocketIOManager.sharedInstance.establishConnection()
                        completion(true, err)
                    }
                })
                
//                self.setupCurrentUserWithData(response.result.value as! NSDictionary)
//                //MARK: connect to server after login
//                SocketIOManager.sharedInstance.establishConnection()
//                completion(success: true, error: nil)
                
                
            }
        }
    }
    
    func loginWithFacebook(_ view: UIViewController, completion: @escaping (_ success:Bool, _ error:Error?) -> ()) {
        let login = FBSDKLoginManager()
        login.logIn(withReadPermissions: ["email", "public_profile"], from: view) { (result, error) in
            if error != nil {
                //Error
                return completion(false, error)
            } else if (result?.isCancelled)! {
                
                //TODO: result?
                return completion(false, nil)
            } else {
                if FBSDKAccessToken.current().tokenString == nil {
                    return completion(false, nil)
                }
                let apiUrl = URL(string: "\(Constant.baseURL)/facebook/token/?access_token=\(FBSDKAccessToken.current().tokenString!)")
                Alamofire.request(apiUrl!).responseJSON { response in
                    print(response.result.error)
                    if response.result.error != nil {
                        return completion(false, nil)
                    }
                    if let token = response.response?.allHeaderFields["Auth"] as? String {
                        User.token = token
                        print("get token: \(token)")
                    } else {
                        return completion(false, nil)
                    }
                    self.saveDeviceTokenForUser({ (success, err) in
                        if success {
                            self.setupCurrentUserWithData(response.result.value as! NSDictionary)
                            //MARK: connect to server after login
                            SocketIOManager.sharedInstance.establishConnection()
                            completion(true, nil)
                        } else {
                            print("===NO DEVICE TOKEN===")
                            self.setupCurrentUserWithData(response.result.value as! NSDictionary)
                            //MARK: connect to server after login
                            SocketIOManager.sharedInstance.establishConnection()
                            completion(true, nil)
                        }
                    })
                }
            }
        }
    }
    
    //MARK: - User action
    func postUpdateUser(_ params:[String:AnyObject], completion: @escaping (_ success:Bool, _ error:Error?) -> ()) {
        if User.token == nil { return completion(false, nil) }
        let apiUrl = URL(string: "\(Constant.baseURL)/user/update")
        
        Alamofire.request(apiUrl!, method: .post, parameters: params, encoding: JSONEncoding.default, headers: ["auth":User.token!]).response { (response) in
            print("respons: \(response)")
            if response.error != nil {
                completion(false, response.error)
            } else {
                completion(true, nil)
            }
        }
    }
    
    
    
    func userChooseCourseAndLang(_ params:Parameters, completion: @escaping (_ success:Bool, _ error:Error?) -> ()) {
        if User.token == nil { return completion(false, nil) }
        let apiUrl = URL(string: "\(Constant.baseURL)/choosecourse")
        print("choose course: \(params)")
        Alamofire.request(apiUrl!, method: .post, parameters: params, encoding: JSONEncoding.default, headers: ["auth":User.token!]).response { (response) in
            if response.error != nil {
                //MARK: connect after finishing choose course
                completion(false, response.error)
            } else {
                print("=====choose course finish")
                SocketIOManager.sharedInstance.establishConnection()
                completion(true, nil)
            }
        }
    }
    

    func uploadImage(_ image: UIImage, uploadType:Constant.imageUploadType, room: String?, completion: @escaping (_ imageUrl: String?, _ progress:Double, _ error:Error?) -> ()) {
        
        if User.token == nil { return completion(nil, 0, NSError(domain: "no token", code: 1, userInfo: nil)) }
        
        let imageData = UIImageJPEGRepresentation(image, 0)
        let apiUrl = try! URLRequest(url: "\(Constant.baseURL)/uploadimage", method: .post, headers: ["auth":User.token!, "type":uploadType.rawValue, "room":room ?? ""])
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            
            multipartFormData.append(imageData!, withName: "img", fileName: "imageFileName.jpg", mimeType: "image/jpg")
            
            }, with: apiUrl, encodingCompletion: { (encodingResult) in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.uploadProgress { progress in
                        // Called on main dispatch queue by default
                        completion(nil,progress.fractionCompleted, nil)
                    }
                    
                    upload.responseJSON { response in
                        if let value = response.result.value as? NSDictionary {
                            if let imageUrl = value["url"] as? String {
                                completion(imageUrl, 1, nil)
                            } else {
                                completion(nil, 1, NSError(domain: "no url get", code: 1, userInfo: nil))
                            }
                        }
                    }
                    
                case .failure(let encodingError):
                    print(encodingError)
                }
                
        })
        
        
    }
    
    func reportToServer(_ userId:String, reason: String?, completion: @escaping (_ success:Bool, _ error:Error?) -> ()) {
        if User.token == nil { return completion(false, nil) }
        let apiUrl = URL(string: "\(Constant.baseURL)/report")
        let params = ["targetUser":userId, "reason":reason ?? ""] as Parameters
        
        Alamofire.request(apiUrl!, method: .post, parameters: params, encoding: JSONEncoding.default, headers: ["auth":User.token!]).response { (response) in
            print("respons: \(response)")
            if response.error != nil {
                completion(false, response.error)
            } else {
                completion(true, nil)
            }
        }
    }
    
    func silentRoom(_ room:String, silent: Bool, completion: @escaping (_ success:Bool, _ error:Error?) -> ()) {
        if User.token == nil { return completion(false, nil) }
        let apiUrl = URL(string: "\(Constant.baseURL)/report")
        let params = ["room":room, "silent":silent] as Parameters
        
        Alamofire.request(apiUrl!, method: .post, parameters: params, encoding: JSONEncoding.default, headers: ["auth":User.token!]).response { (response) in
            print("silent respons: \(response)")
            if response.error != nil {
                completion(false, response.error)
            } else {
                completion(true, nil)
            }
        }
    }
    
    
    //MARK: - Non user related
    func searchCourse(_ searchText:String?, completion: @escaping (_ courseArr:[Course]?, _ error:Error?) -> ()) {
        let query = generateQuery(searchText, limit: nil, skip: nil, univ: User.currentUser!.universityID)
        let apiUrl = URL(string: "\(Constant.baseURL)/course\(query)")
        
        Alamofire.request(apiUrl!).responseJSON { (response) in
            print("get respons\(response)")
            if response.result.error != nil {
                completion(nil, response.result.error)
            } else {
                if let crsArr = response.result.value as? [NSDictionary] {
                    var finalArray:[Course] = []
                    for crs in crsArr {
                        finalArray.append(Course.initCourse(crs)!)
                    }
                    completion(finalArray, nil)
                } else {
                    completion(nil, nil)
                }
            }
        }
    }
    
    func getUniversity(_ searchText:String?, limit:Int?, skip:Int?, completion: @escaping (_ univArr:[University]?, _ error:Error?) -> ()) {
        let query = generateQuery(searchText, limit: limit, skip: skip, univ: nil)
        let apiUrl = URL(string: "\(Constant.baseURL)/univ\(query)")
        
        Alamofire.request(apiUrl!).responseJSON { (response) in
            if response.result.error != nil {
                completion(nil, response.result.error)
            } else {
                University.removeAllUniv()
                if let univArr = response.result.value as? [NSDictionary] {
                    for univ in univArr {
                        University.initUniv(univ)
                    }
                    completion(University.getAllUnivArr(), nil)
                } else {
                    completion(nil, nil)
                }
            }
        }
    }
    
    func getDefaultLanguage(_ completion: @escaping (_ lang:[(String,Int)]?, _ error:Error?) -> ()) {
        let apiUrl = URL(string: "\(Constant.baseURL)/defaultlanguage")
        
        Alamofire.request(apiUrl!).responseJSON { (response) in
            if response.result.error != nil {
                completion(nil, response.result.error)
            } else {
                if let langArray = response.result.value as? [String:NSDictionary] {
                    var final:[(String, Int)] = []
                    for lan in langArray {
                        if let name = lan.1["name"] as? String, let code = lan.1["code"] as? Int {
                            final.append((name,code))
                        }
                    }
                    completion(final, nil)
                }
            }
        }
    }
    
    func getUserInfo(_ id:String, refresh: Bool, completion: @escaping (_ user:User?, _ joinedCourse:[String], _ error:Error?) -> ()) {
        //TODO: check from database or cache
        if !refresh {
            if let user = try! Realm().object(ofType: User.self, forPrimaryKey: id) {
                print("user get in database")
                return completion(user, [], nil)
            }
        }
        
        let apiUrl = URL(string: "\(Constant.baseURL)/user/\(id)")
        
        Alamofire.request(apiUrl!).responseJSON { (response) in
            if response.result.error != nil {
                print("error in getuserinfo \(Constant.baseURL)/user/\(id)")
                completion(nil, [], response.result.error)
            } else {
                let resData = response.result.value as! NSDictionary
                let user = User()
                user.initUserFromServerWithData(resData).saveToDatabase()
//                user.cacheUserInfo()
                completion(user, [], nil)
            }
        }
    }
    
    fileprivate func generateQuery(_ searchText:String?, limit:Int?, skip:Int?, univ:String?) -> String {
        if (searchText == nil && limit == nil && skip == nil) { return "" }
        var query = "?"
        query += searchText == nil ? "" : "q=\(searchText!.removeSpecialCharsFromString())&"
        query += limit == nil ? "" : "limit=\(limit!)&"
        query += skip == nil ? "" : "skip=\(skip!)&"
        query += univ == nil ? "" : "univ=\(univ!)&"

        return query.substring(to: query.characters.index(before: query.endIndex))
    }
    
    fileprivate func setupCurrentUserWithData(_ data:NSDictionary) {
        RealmTools.setDefaultRealmForUser(data["_id"] as? String)
        User.currentUser = User().initCurrentUserWithData(data)
    }
    
    func saveDeviceTokenForUser(_ completion: @escaping (_ success:Bool, _ error:Error?) -> ()) {
        if User.token == nil || UserSetting.userDeviceToken == nil { return completion(false, nil) }
        
        let params = ["deviceToken":UserSetting.userDeviceToken!, "deviceType": 0] as Parameters
        let apiUrl = URL(string: "\(Constant.baseURL)/installation")
        
        Alamofire.request(apiUrl!, method: .post, parameters: params, encoding: JSONEncoding.default, headers: ["auth":User.token!]).response { (response) in
            print("device token respons: \(response)")
            if response.error != nil {
                completion(false, response.error)
            } else {
                completion(true, nil)
            }
        }
    }
    
    
}
