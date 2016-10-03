//
//  LoginLangChooseVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/5/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class LoginLangChooseVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    weak var delegate: moveToVCProtocol?
    
    @IBOutlet weak var langTableView: UITableView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var finishBtn: UIButton!
    
    @IBOutlet weak var titleLabelToCenterConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var langTVWidthConstraint: NSLayoutConstraint!
    
    var language:[(String,Int)] = []
    var choosedLang: [Int] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.textColor = UIColor(white: 0.9, alpha: 1)
        
        titleLabelToCenterConstraint.constant = UIScreen.main.bounds.height * -0.25
        finishBtn.layer.cornerRadius = finishBtn.frame.height/2
        finishBtn.layer.borderColor = UIColor.white.cgColor
        finishBtn.layer.borderWidth = 1
        finishBtn.layer.masksToBounds = true
        finishBtn.tintColor = UIColor.white
        
        langTableView.register(UINib(nibName: "LoginLangChooseTVCell", bundle: nil), forCellReuseIdentifier: "LoginLangChooseTVCell")
        langTableView.delegate = self
        langTableView.dataSource = self
        langTableView.tableFooterView = UIView()
        
        ServerConst.sharedInstance.getDefaultLanguage { (lang, error) in
            if lang != nil {
                self.language = self.sortLanguage(lang!)
                self.langTableView.reloadData()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        titleLabel.alpha = 0
        langTableView.alpha = 0
        finishBtn.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0.3, options: .curveEaseOut, animations: {
            self.titleLabel.alpha = 1
            self.langTableView.alpha = 1
            self.finishBtn.alpha = 1
            self.titleLabelToCenterConstraint.constant = UIScreen.main.bounds.height * -0.3
            self.view.layoutIfNeeded()
            }, completion: nil)
    }

    func sortLanguage(_ lang:[(String,Int)]) ->[(String, Int)] {
        let englishIndex = lang.index { (lang) -> Bool in
            return lang.1 == 0
        }
        var eliminateEnglishArr = lang
        if englishIndex != nil { eliminateEnglishArr.remove(at: englishIndex!) }
        
        return eliminateEnglishArr.sorted { (a, b) -> Bool in
            return a.1 < b.1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return language.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LoginLangChooseTVCell", for: indexPath) as! LoginLangChooseTVCell
        cell.langLabel.text = language[(indexPath as NSIndexPath).row].0
        if choosedLang.index(of: language[(indexPath as NSIndexPath).row].1) == nil {
            cell.backgroundColor = UIColor.white
            cell.operationImgView.image = UIImage(named: "plus-ion")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            cell.operationImgView.tintColor = UIColor(red: 0, green: 200/255, blue: 7/255, alpha: 1)
        } else {
            cell.backgroundColor = Design.color.cellSelectedGreen()
            cell.operationImgView.image = UIImage(named: "close-ion")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            cell.operationImgView.tintColor = UIColor.red
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let index = choosedLang.index(of: language[(indexPath as NSIndexPath).row].1) {
            choosedLang.remove(at: index)
        } else {
            choosedLang.append(language[(indexPath as NSIndexPath).row].1)
        }
        tableView.reloadRows(at: [indexPath], with: .middle)
    }
    
    @IBAction func finishBtnPressed(_ sender: UIButton) {
        User.userLang = choosedLang
        let realm = try! Realm()
        let allCourse = realm.objects(Course.self)
        var courseIdArray:[String] = []
        for course in allCourse {
            courseIdArray.append(course.id!)
        }
        ServerConst.sharedInstance.userChooseCourseAndLang(["lang":choosedLang, "course":courseIdArray]) { (success, error) in
            if success {
                self.delegate?.moveToVC(3)
            }
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
