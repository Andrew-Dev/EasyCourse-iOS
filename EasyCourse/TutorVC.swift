//
//  TutorVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 2/11/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class TutorVC: ButtonBarPagerTabStripViewController {

    override func viewDidLoad() {
        setupStripViewUI()
        super.viewDidLoad()
    }
    
    func setupStripViewUI() {
        self.settings.style.selectedBarHeight = 2
        self.settings.style.selectedBarBackgroundColor = Design.color.deepGreenPersianGreenColor()
        self.settings.style.buttonBarBackgroundColor = UIColor.white
        self.settings.style.buttonBarItemBackgroundColor = UIColor.white
        self.settings.style.buttonBarHeight = 35
        let originFontName = self.settings.style.buttonBarItemFont.fontName
        self.settings.style.buttonBarItemFont = UIFont(name: originFontName, size: 15)!
        self.settings.style.buttonBarItemTitleColor = UIColor.darkGray
        
        changeCurrentIndexProgressive = { [weak self] (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = .darkGray
            newCell?.label.textColor = Design.color.deepGreenPersianGreenColor()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let tutorAvaibaleVC = self.storyboard?.instantiateViewController(withIdentifier: "TutorAvailableVC") as! TutorAvailableVC
        let myTutorVC = self.storyboard?.instantiateViewController(withIdentifier: "TutorMyTutorVC") as! TutorMyTutorVC
        let myStudentAvaibaleVC = self.storyboard?.instantiateViewController(withIdentifier: "TutorMyStudentVC") as! TutorMyPostsVC
        return [tutorAvaibaleVC, myTutorVC, myStudentAvaibaleVC]
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
