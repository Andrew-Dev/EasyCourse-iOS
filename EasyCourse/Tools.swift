//
//  Tools.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/13/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import Foundation
import UIKit

open class Tools {
    
    static let sharedInstance = Tools()
    
    func timeAgoSinceDatePrefered(_ date:Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let earliest = (now as NSDate).earlierDate(date)
        let latest = (earliest == now) ? date : now
        let components:DateComponents = (calendar as NSCalendar).components([NSCalendar.Unit.minute , NSCalendar.Unit.hour , NSCalendar.Unit.day , NSCalendar.Unit.weekOfYear , NSCalendar.Unit.month , NSCalendar.Unit.year , NSCalendar.Unit.second], from: earliest, to: latest, options: NSCalendar.Options())
        
        let dayTimePeriodFormatter = DateFormatter()
        
        if (components.year! >= 1){
            dayTimePeriodFormatter.dateFormat = "M/d/y"
            return dayTimePeriodFormatter.string(from: date)
        } else if (components.month! >= 1 || components.day! >= 2) {
            dayTimePeriodFormatter.dateFormat = "M/d"
            return dayTimePeriodFormatter.string(from: date)
        } else if (components.day! >= 1){
            return "Yesterday"
        } else if (components.hour! >= 2) {
            
            let unitFlags: NSCalendar.Unit = [.day]
            let components0 = (Calendar.current as NSCalendar).components(unitFlags, from: now)
            let components1 = (Calendar.current as NSCalendar).components(unitFlags, from: date)
            if components0.day != components1.day {
                return "Yesterday"
            }
            
            dayTimePeriodFormatter.dateFormat = "h:mm a"
            return dayTimePeriodFormatter.string(from: date)
        } else if (components.hour! >= 1){
            return "1 hour"
        } else if (components.minute! >= 2) {
            return "\(components.minute!) min"
        } else if (components.minute! >= 1){
            return "1 min"
        } else {
            return "Just now"
        }
        
    }
    
    func setTabBarBadge() {
        if User.currentUser == nil { return }
        guard let mainNav = UIApplication.shared.keyWindow?.rootViewController as? MainNavigationController else {
            return
        }
        
        guard let tabBarController = mainNav.viewControllers[0] as? UITabBarController else {
            return
        }
        let badgeValue = User.currentUser!.countUnread() == 0 ? nil : String(User.currentUser!.countUnread())
        tabBarController.tabBar.items?[0].badgeValue = badgeValue
    }
    
    func showUpdateAlert(title:String, message:String, forceUpdate:Bool, link:String) {
        
        if let lastShowDate = UserDefaults.standard.object(forKey: Constant.UserDefaultKey.updateShowDateKey) as? Date {
            if Date().timeIntervalSince(lastShowDate) < 60*60*24*3 {
                return
            } else {
                UserDefaults.standard.set(Date(), forKey: Constant.UserDefaultKey.updateShowDateKey)
                UserDefaults.standard.synchronize()
            }
        } else {
            UserDefaults.standard.set(Date(), forKey: Constant.UserDefaultKey.updateShowDateKey)
            UserDefaults.standard.synchronize()
        }
    
        guard let mainNav = UIApplication.shared.keyWindow?.rootViewController as? MainNavigationController else {
            return
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let update = UIAlertAction(title: "Update", style: .default, handler: { (UIAlertAction) in
            UIApplication.shared.openURL(URL(string:link)!)
        })
        alert.addAction(update)

        if !forceUpdate {
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancel)
        }
        mainNav.present(alert, animated: true, completion: nil)
    }
   
}
