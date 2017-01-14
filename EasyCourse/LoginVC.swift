//
//  NewLoginVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 8/28/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
protocol loginProtocol : NSObjectProtocol {
    func moveToVC(_ index:Int) -> Void
    func updateChoosedCourse(_ courseArr:[Course]) -> Void
    func getChoosedCourse() -> [Course]
    func showMainTabBarVC(_ getPassMessage:Bool) -> Void
}

class LoginVC: UIViewController, loginProtocol {
    
    
    @IBOutlet weak var mainScrollView: UIScrollView!
    
    let mainLoginVC = LoginMainComponentVC(nibName: "LoginMainComponentVC", bundle: nil)
    
    var chooseUnivVC:LoginUnivComponentVC?
    var chooseCourseVC:LoginCourseComponentVC?
    var chooseLangVC:LoginLangChooseVC?
    
    var choosedCourse:[Course] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
//        mainScrollView.backgroundColor = Design.color.DarkGunPowder()
        
        mainLoginVC.delegate = self
        self.addChildViewController(mainLoginVC)
        self.mainScrollView.addSubview(mainLoginVC.view)
        mainLoginVC.didMove(toParentViewController: self)
        
        
        self.mainScrollView.contentSize = CGSize(width: self.view.frame.size.width * 3, height: self.view.frame.size.height);
        self.mainScrollView.isScrollEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mainLoginVC.view.frame.size.width = self.view.frame.width
        mainLoginVC.view.frame.size.height = self.view.frame.height
        
        if chooseUnivVC != nil {
            chooseUnivVC!.view.frame.size.width = self.view.frame.width
            chooseUnivVC!.view.frame.size.height = self.view.frame.height
        }
        
        if chooseCourseVC != nil {
            chooseCourseVC!.view.frame.size.width = self.view.frame.width
            chooseCourseVC!.view.frame.size.height = self.view.frame.height
        }
        
        if chooseLangVC != nil {
            chooseLangVC!.view.frame.size.width = self.view.frame.width
            chooseLangVC!.view.frame.size.height = self.view.frame.height
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: login protocol
    
    func updateChoosedCourse(_ courseArr:[Course]) {
        choosedCourse = courseArr
    }
    
    func getChoosedCourse() -> [Course] {
        return choosedCourse
    }
    
    func moveToVC(_ index: Int) {
        if index == 0 && chooseUnivVC == nil {
            chooseUnivVC = LoginUnivComponentVC(nibName: "LoginUnivComponentVC", bundle:nil)
            var frame1 = chooseUnivVC!.view.frame
            frame1.origin.x = self.view.frame.size.width
            chooseUnivVC!.view.frame = frame1
            chooseUnivVC?.delegate = self
            
            self.addChildViewController(chooseUnivVC!)
            self.mainScrollView.addSubview(chooseUnivVC!.view)
            chooseUnivVC!.didMove(toParentViewController: self)
        } else if index == 1 && chooseCourseVC == nil {
            chooseCourseVC = LoginCourseComponentVC(nibName: "LoginCourseComponentVC", bundle:nil)
            var frame2 = chooseCourseVC!.view.frame
            frame2.origin.x = self.view.frame.size.width * 2
            chooseCourseVC!.view.frame = frame2
            chooseCourseVC?.delegate = self
            
            self.addChildViewController(chooseCourseVC!)
            self.mainScrollView.addSubview(chooseCourseVC!.view)
            chooseCourseVC!.didMove(toParentViewController: self)
        } else if index == 2 && chooseLangVC == nil {
            chooseLangVC = LoginLangChooseVC(nibName: "LoginLangChooseVC", bundle:nil)
            var frame2 = chooseLangVC!.view.frame
            frame2.origin.x = self.view.frame.size.width * 3
            chooseLangVC!.view.frame = frame2
            chooseLangVC?.delegate = self
            
            self.addChildViewController(chooseLangVC!)
            self.mainScrollView.addSubview(chooseLangVC!.view)
            chooseLangVC!.didMove(toParentViewController: self)
        }
        self.view.setNeedsLayout()
        mainScrollView.setContentOffset(CGPoint(x: (self.view.frame.width * CGFloat(index + 1)), y: 0), animated: true)
        
    }
    
    func showMainTabBarVC(_ getPassMessage: Bool) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let mainTabBarController = sb.instantiateViewController(withIdentifier: "BaseTabBarController") as! UITabBarController
        
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController

        guard let mainNavigationController = rootViewController as? MainNavigationController else { return }
        
        mainNavigationController.viewControllers = [mainTabBarController]
        
        dismiss(animated: true, completion: nil)
        
        if getPassMessage {
            SocketIOManager.sharedInstance.getHistMessage(true, completion: { (success, error) in
                //
            })
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
