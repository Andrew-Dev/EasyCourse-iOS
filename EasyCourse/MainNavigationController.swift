//
//  MainTabBarController.swift
//  EasyCourse
//
//  Created by ZengJintao on 1/9/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//


import UIKit

class MainNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.setNavigationBarHidden(true, animated: false)
        self.isNavigationBarHidden = true
        
        
        if isLoggedIn() {
            if User.currentUser?.universityId == nil {
                perform(#selector(goChooseCourse), with: nil, afterDelay: 0.01)
                return
            }
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let baseTabBarController = storyboard.instantiateViewController(withIdentifier: "BaseTabBarController") as! UITabBarController
            viewControllers = [baseTabBarController]
        } else {
            perform(#selector(showLoginController), with: nil, afterDelay: 0.01)
        }
    }
    
    private func isLoggedIn() -> Bool {
        return User.currentUser != nil
    }
    
    func showLoginController() {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let logInViewController = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
        present(logInViewController, animated: true, completion: {
            //
        })
    }
    
    func goChooseCourse() {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let logInViewController = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
        logInViewController.moveToVC(0)
        present(logInViewController, animated: true, completion: {
            //
        })
    }
}

