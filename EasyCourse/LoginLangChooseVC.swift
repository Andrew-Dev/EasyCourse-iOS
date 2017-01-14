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
    
    weak var delegate: loginProtocol?
    
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
        
        titleLabelToCenterConstraint.constant = UIScreen.main.bounds.height * -0.25
        finishBtn.layer.cornerRadius = finishBtn.frame.height/2
        finishBtn.layer.borderColor = UIColor(white: 0.5, alpha: 1).cgColor
        finishBtn.layer.borderWidth = 1
        finishBtn.layer.masksToBounds = true
        finishBtn.tintColor = UIColor(white: 0.5, alpha: 1)
        
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
            self.titleLabelToCenterConstraint.constant = UIScreen.main.bounds.height * -0.4
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
        var courseIdArray:[String] = []
        if let choosedCourse = delegate?.getChoosedCourse() {
            for course in choosedCourse {
                courseIdArray.append(course.id!)
            }
        }
        
        let hud = JGProgressHUD(style: .extraLight)
        hud?.show(in: self.view, animated: true)
        
        SocketIOManager.sharedInstance.joinCourse(courseIdArray, languages: choosedLang) { (success, error) in
            if success {
                hud?.indicatorView = JGProgressHUDSuccessIndicatorView()
                hud?.dismiss(animated: true)
                self.delegate?.showMainTabBarVC(true)
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
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if loadStatus == .receivedResult {
            if let index = choosedLang.index(of: language[indexPath.row].code) {
                tableView.cellForRow(at: indexPath)?.accessoryType = .none
                choosedLang.remove(at: index)
            } else {
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                choosedLang.append(language[indexPath.row].code)
            }
        } else if loadStatus == .receivedError {
            getLanguage()
        }
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
}
