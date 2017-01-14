//
//  LoginUnivComponentVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 8/28/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class LoginUnivComponentVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var univTableView: UITableView!
    
    @IBOutlet weak var univTVWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var titleLabelToCenterConstraint: NSLayoutConstraint!
    
    weak var delegate: loginProtocol?
    
    var universities:[University] = []
    
    var loadStatus = Constant.searchStatus.notSearching
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
//        titleLabel.textColor = UIColor(white: 0.9, alpha: 1)
        titleLabelToCenterConstraint.constant = UIScreen.main.bounds.height * -0.15
        
        univTableView.layer.cornerRadius = 3
        univTableView.layer.masksToBounds = true
        
        univTableView.delegate = self
        univTableView.dataSource = self
        univTableView.register(UINib(nibName: "LoginUnivChooseCell", bundle: nil), forCellReuseIdentifier: "LoginUnivChooseCell")
        univTableView.register(UINib(nibName: "LoadingTVCell", bundle: nil), forCellReuseIdentifier: "LoadingTVCell")
        univTableView.tableFooterView = UIView()
        univTVWidthConstraint.constant = UIScreen.main.bounds.width * 0.9
        
        loadStatus = .isSearching
        getUniversity()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getUniversity() {
        loadStatus = .isSearching
        univTableView.reloadData()
        ServerConst.sharedInstance.getUniversity(nil, limit: nil, skip: nil) { (univArr, error) in
            if univArr != nil {
                self.loadStatus = .receivedResult
                self.universities = univArr!
            } else {
                self.loadStatus = .receivedError
            }
            self.univTableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        titleLabel.alpha = 0
        univTableView.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0.3, options: .curveEaseOut, animations: {
            self.titleLabel.alpha = 1
            self.univTableView.alpha = 1
            self.titleLabelToCenterConstraint.constant = UIScreen.main.bounds.height * -0.2
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if loadStatus == .receivedResult {
            return universities.count
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoginUnivChooseCell", for: indexPath) as! LoginUnivChooseCell
            cell.univLabel.text = universities[(indexPath as NSIndexPath).row].name
            return cell
        default:
            let statusCell = tableView.dequeueReusableCell(withIdentifier: "LoadingTVCell", for: indexPath) as! LoadingTVCell
            statusCell.configureCell(loadingStatus: loadStatus, text: nil)
            return statusCell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if loadStatus == .receivedResult {
            ServerConst.sharedInstance.postUpdateUser(["university":universities[indexPath.row].id! as AnyObject]) { (success, error) in
                if success {
                    try! Realm().write({
                        User.currentUser?.universityId = self.universities[indexPath.row].id
                    })
                    self.delegate?.moveToVC(1)
                } else {
                    //TODO: error
                    self.loadStatus = .receivedError
                    self.univTableView.reloadData()
                }
            }
        } else if loadStatus == .receivedError {
            getUniversity()
        }
        
        univTableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
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
