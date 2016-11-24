//
//  MessageAlert.swift
//  EasyCourse
//
//  Created by ZengJintao on 11/19/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import Foundation
import SwiftMessages
import Async

class MessageAlert {
    
    static let sharedInstance = MessageAlert()
    
    let statusMessageView = MessageView.viewFromNib(layout: .StatusLine)
    var statusMessageConfig = SwiftMessages.Config()    
    
    init() {
        statusMessageConfig.presentationContext = .window(windowLevel: UIWindowLevelNormal)
        statusMessageConfig.preferredStatusBarStyle = .lightContent
        statusMessageConfig.duration = .forever
    }
    
    func setupConnectionStatus() {
        
        switch SocketIOManager.sharedInstance.socket.status {
        case .connected:
            print("alert get connected")
            statusMessageView.configureContent(body: "Connected")
            statusMessageView.configureTheme(.success)
            SwiftMessages.hideAll()
            
        case .connecting:
            print("alert get connecting")
            statusMessageView.configureContent(body: "Connecting")
            statusMessageView.configureTheme(.warning)
            SwiftMessages.show(config: self.statusMessageConfig, view: self.statusMessageView)            

        case .disconnected:
            print("alert get disconnected")
            statusMessageView.configureContent(body: "Disconnected")
            statusMessageView.configureTheme(.warning)
            
        case .notConnected:
            print("alert get notconnected")
            statusMessageView.configureContent(body: "Connection error")
            statusMessageView.configureTheme(.warning)
            SwiftMessages.show(config: self.statusMessageConfig, view: self.statusMessageView)

            
        }
    }
    
}
