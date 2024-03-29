//
//  AppDelegate.swift
//  EasyCourse
//
//  Created by ZengJintao on 8/25/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import Async
import SwiftMessages
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let homeDir = NSHomeDirectory()
        print("Home directory: \(homeDir)")
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.userDidLogout), name: Constant.NotificationKey.UserDidLogout, object: nil)
        
        let id = UserDefaults.standard.object(forKey: Constant.UserDefaultKey.currentUserIDKey) as? String
        print("the set default id: \(id)")
        RealmTools.setDefaultRealmForUser(id)
        
        window?.makeKeyAndVisible()
        window?.rootViewController = MainNavigationController()

        UINavigationBar.appearance().tintColor = Design.color.lighterDarkGunPowder()
//        UINavigationBar.appearance().backgroundColor = Design.color.lighterDarkGunPowder()
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().barStyle = .black
        UINavigationBar.appearance().barTintColor = Design.color.lighterDarkGunPowder()
//        UINavigationBar.appearance().barTintColor = Design.color.lighterGreenMountainMead()
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().tintColor = Design.color.lighterDarkGunPowder()
//        UITabBar.appearance().tintColor = Design.color.deepGreenPersianGreenColor()
        
        if !UserSetting.shouldAskPushNotif {
            if #available(iOS 10, *) {
                UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
                UIApplication.shared.registerForRemoteNotifications()
            } else {
                UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        
//        application.applicationIconBadgeNumber = User.currentUser?.countUnread() ?? 0

        
        return true
    }
    
    func userDidLogout() {
        User.currentUser = nil
        User.token = nil
        RealmTools.setDefaultRealmForUser(nil)
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
        window?.rootViewController?.present(vc, animated: true, completion: {

            guard let mainNavController = self.window?.rootViewController as? MainNavigationController else {
                return
            }

            let tabBarController = mainNavController.viewControllers[0] as? UITabBarController
            tabBarController?.removeFromParentViewController()

        })
        
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if User.currentUser != nil {
            SocketIOManager.sharedInstance.closeConnection()
        }
        print("enter bg cnt \(User.currentUser?.countUnread())")
        application.applicationIconBadgeNumber = User.currentUser?.countUnread() ?? 0
    }
    
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//        Async.background(after: 2, {
//            if SocketIOManager.sharedInstance.socket.status != .connected {
//                print("show alert")
//                let view = MessageView.viewFromNib(layout: .StatusLine)
//                var config = SwiftMessages.Config()
//                config.presentationContext = .window(windowLevel: UIWindowLevelNormal)
//                config.preferredStatusBarStyle = .lightContent
//                config.duration = .forever
//                view.configureContent(body: "Connecting")
//                view.configureTheme(.warning)
//                SwiftMessages.sharedInstance.show(config: config, view: view)
//                
//            }
////            MessageAlert.sharedInstance.setupConnectionStatus()
//        })
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if User.currentUser != nil {
            SocketIOManager.sharedInstance.establishConnection()
            Async.main(after: 2, {
                MessageAlert.sharedInstance.setupConnectionStatus()
            })
        }
        FBSDKAppEvents.activateApp()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        application.applicationIconBadgeNumber = User.currentUser?.countUnread() ?? 0
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    //MARK: - Push setup
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //save device token here
        var token: String = ""
        for i in 0..<deviceToken.count {
            token += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        UserSetting.userDeviceToken = token
        
//        let token = deviceToken.description.trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
//        UserSetting.userDeviceToken = token.replacingOccurrences(of: " ", with: "")
        print("DeviceToken is \(UserSetting.userDeviceToken)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {

        
        print(error.localizedDescription)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        //user info is data
        print("receive push: \(userInfo)")
    }
    
}

