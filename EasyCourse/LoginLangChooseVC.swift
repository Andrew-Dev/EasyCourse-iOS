//
//  LoginLangChooseVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/5/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift
import JGProgressHUD

class LoginLangChooseVC: UIViewController {
    
    weak var delegate: moveToVCProtocol?
    
    @IBOutlet weak var langTableView: UITableView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var finishBtn: UIButton!
    
    @IBOutlet weak var titleLabelToCenterConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var langTVWidthConstraint: NSLayoutConstraint!
    
    var language:[(code: String, name: String, displayName: String)] = []
    var choosedLang: [String] = []
    
    var loadStatus = Constant.searchStatus.notSearching
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        titleLabel.textColor = UIColor(white: 0.9, alpha: 1)
        
        titleLabelToCenterConstraint.constant = UIScreen.main.bounds.height * -0.25
        finishBtn.layer.cornerRadius = finishBtn.frame.height/2
        finishBtn.layer.borderColor = UIColor.white.cgColor
        finishBtn.layer.borderWidth = 1
        finishBtn.layer.masksToBounds = true
        finishBtn.tintColor = UIColor.white
        
        langTableView.register(UINib(nibName: "LoginLangChooseTVCell", bundle: nil), forCellReuseIdentifier: "LoginLangChooseTVCell")
        langTableView.register(UINib(nibName: "LoadingTVCell", bundle: nil), forCellReuseIdentifier: "LoadingTVCell")
        langTableView.delegate = self
        langTableView.dataSource = self
        langTableView.tableFooterView = UIView()
        
        loadStatus = .isSearching
        getLanguage()
        
        
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
    
    func getLanguage() {
        loadStatus = .isSearching
        langTableView.reloadData()
        ServerConst.sharedInstance.getDefaultLanguage { (lang, error) in
            if error == nil {
                self.loadStatus = .receivedResult
                self.language = lang
            } else {
                self.loadStatus = .receivedError
            }
            self.langTableView.reloadData()
        }
    }
    
    @IBAction func finishBtnPressed(_ sender: UIButton) {
        let realm = try! Realm()
        let allCourse = realm.objects(Course.self)
        var courseIdArray:[String] = []
        for course in allCourse {
            courseIdArray.append(course.id!)
        }
        let hud = JGProgressHUD(style: .extraLight)
        hud?.textLabel.text = "Loading"
        hud?.show(in: self.view, animated: true)
        
        SocketIOManager.sharedInstance.joinCourse(courseIdArray, languages: choosedLang) { (success, error) in
            if success {
                hud?.indicatorView = JGProgressHUDSuccessIndicatorView()
                hud?.textLabel.text = "Success"
                hud?.dismiss(animated: true)
                self.delegate?.moveToVC(3)
                //                SocketIOManager.sharedInstance.syncUser()
            } else {
                hud?.indicatorView = JGProgressHUDErrorIndicatorView()
                hud?.textLabel.text = error?.description ?? "Error, try again"
                hud?.tapOutsideBlock = { (hu) in
                    hud?.dismiss()
                }
                hud?.tapOnHUDViewBlock = { (hu) in
                    hud?.dismiss()
                }
            }

        }
        
//        ServerConst.sharedInstance.userChooseCourseAndLang(["lang":choosedLang, "course":courseIdArray]) { (success, error) in
//            if success {
//                hud?.indicatorView = JGProgressHUDSuccessIndicatorView()
//                hud?.textLabel.text = "Success"
//                hud?.dismiss(animated: true)
//                self.delegate?.moveToVC(3)
////                SocketIOManager.sharedInstance.syncUser()
//            } else {
//                hud?.indicatorView = JGProgressHUDErrorIndicatorView()
//                hud?.textLabel.text = "Error, try again"
//                hud?.tapOutsideBlock = { (hu) in
//                    hud?.dismiss()
//                }
//                hud?.tapOnHUDViewBlock = { (hu) in
//                    hud?.dismiss()
//                }
//            }
//        }
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

extension LoginLangChooseVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if loadStatus == .receivedResult {
            return language.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch loadStatus {
        case .isSearching:
            let statusCell = tableView.dequeueReusableCell(withIdentifier: "LoadingTVCell", for: indexPath) as! LoadingTVCell
            statusCell.configureCell(loadingStatus: loadStatus, text: nil)
            return statusCell
        case .receivedError:
            let statusCell = tableView.dequeueReusableCell(withIdentifier: "LoadingTVCell", for: indexPath) as! LoadingTVCell
            statusCell.configureCell(loadingStatus: loadStatus, text: "Error, tap to reconnect")
            return statusCell
        case .receivedResult:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoginLangChooseTVCell", for: indexPath) as! LoginLangChooseTVCell
            let cellChoosed = choosedLang.index(of: language[indexPath.row].code) != nil
            cell.configureCell(langText: language[indexPath.row].displayName, choosed: cellChoosed)
            return cell
        default:
            let statusCell = tableView.dequeueReusableCell(withIdentifier: "LoadingTVCell", for: indexPath) as! LoadingTVCell
            statusCell.configureCell(loadingStatus: loadStatus, text: nil)
            return statusCell
        }
        
        
//        let cell = tableView.dequeueReusableCell(withIdentifier: "LoginLangChooseTVCell", for: indexPath) as! LoginLangChooseTVCell
//        cell.langLabel.text = language[(indexPath as NSIndexPath).row].0
//        let cellChoosed = choosedLang.index(of: language[(indexPath as NSIndexPath).row].1) != nil
//        cell.configureCell(langText: language[indexPath.row].0, choosed: cellChoosed)
//        if choosedLang.index(of: language[(indexPath as NSIndexPath).row].1) == nil {
//            cell.backgroundColor = UIColor.white
//            cell.operationImgView.image = UIImage(named: "plus-ion")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
//            cell.operationImgView.tintColor = UIColor(red: 0, green: 200/255, blue: 7/255, alpha: 1)
//        } else {
//            cell.backgroundColor = Design.color.cellSelectedGreen()
//            cell.operationImgView.image = UIImage(named: "close-ion")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
//            cell.operationImgView.tintColor = UIColor.red
//        }
        
//        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if loadStatus == .receivedResult {
            if let index = choosedLang.index(of: language[indexPath.row].code) {
                choosedLang.remove(at: index)
            } else {
                choosedLang.append(language[indexPath.row].code)
            }
            tableView.reloadRows(at: [indexPath], with: .middle)
        } else if loadStatus == .receivedError {
            getLanguage()
        }
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
}
