//
//  Design.swift
//  EasyCourse
//
//  Created by ZengJintao on 8/25/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import Foundation
import UIKit

open class Design {
    
    open class color {
        class func deleteButtonColor() -> UIColor { return UIColor(red: 221/255, green: 120/255, blue: 130/255, alpha: 1) }
        class func facebookColor() -> UIColor { return UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 1) }

        
        //new
        
//        class func subBlueThemeColor() -> UIColor { return UIColor(red: 225/255, green: 231/255, blue: 255/255, alpha: 1) }
        
        
        
        //FROM design
        //MAIN
        //lighter dark
        class func lighterDarkGunPowder() -> UIColor { return UIColor(red: 73/255, green: 75/255, blue: 108/255, alpha: 1) }
        //dark
        class func DarkGunPowder() -> UIColor { return UIColor(red: 56/255, green: 59/255, blue: 87/255, alpha: 1) }
        //deep green
        class func deepGreenPersianGreenColor() -> UIColor { return UIColor(red: 0/255, green: 150/255, blue: 136/255, alpha: 1) }

        
        //ACCENT
        //light blue
        class func lightBlueMalibu() -> UIColor { return UIColor(red: 111/255, green: 168/255, blue: 254/255, alpha: 1) }
        //bright red
        class func brightRedPomegranate() -> UIColor { return UIColor(red: 244/255, green: 67/255, blue: 54/255, alpha: 1) }
        //lighter green
        class func lighterGreenMountainMead() -> UIColor { return UIColor(red: 30/255, green: 199/255, blue: 172/255, alpha: 1) }
        
        
        //LOCAL
        //very light green
        class func cellSelectedGreen() -> UIColor { return UIColor(red: 230/255, green: 255/255, blue: 236/255, alpha: 1) }
    }
    
    open static let defaultAvatarImage = UIImage(named: "DefaultAvatar")
    open static let defaultRoomImage = UIImage(named: "DefaultRoom")
    
}
