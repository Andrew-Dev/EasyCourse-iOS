//
//  MessageBubbleView.swift
//  EasyCourse
//
//  Created by ZengJintao on 1/7/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class MessageBubbleView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    var message:Message?

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        sharedInit()
    }
    
    func sharedInit() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.popUpMenu)))
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if (action == #selector(self.deleteMsg) || action == #selector(self.customCopy)) {
            return true
        } else {
            return false
        }
    }
    
    
    func popUpMenu() {
        guard let msg = message else {
            return
        }
        if UIMenuController.shared.isMenuVisible {
            return
        }
        becomeFirstResponder()
        
        var itemArr:[UIMenuItem] = []
        
        if msg.text != nil && !msg.text!.isEmpty {
            let copyItem = UIMenuItem(title: "Copy", action: #selector(self.customCopy))
            itemArr.append(copyItem)
        }

        let deleteItem = UIMenuItem(title: "Delete", action: #selector(self.deleteMsg))
        itemArr.append(deleteItem)
        
        let menu = UIMenuController.shared
        
        menu.menuItems = itemArr
        menu.setTargetRect(self.bounds, in: self)
        
        menu.setMenuVisible(true, animated: true)
    }
    
    func customCopy() {
        UIPasteboard.general.string = message?.text
    }
    
    func deleteMsg() {
        if message != nil {
            let realm = try! Realm()
            try! realm.write {
                realm.delete(message!)
            }
        }
    }
}
