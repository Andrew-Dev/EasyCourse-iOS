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
    
    weak var delegate: moveToVCProtocol?
    
    var universities:[University] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.textColor = UIColor(white: 0.9, alpha: 1)
        titleLabelToCenterConstraint.constant = UIScreen.main.bounds.height * -0.15
        
        
        
        univTableView.delegate = self
        univTableView.dataSource = self
        univTableView.register(UINib(nibName: "LoginUnivChooseCell", bundle: nil), forCellReuseIdentifier: "LoginUnivChooseCell")
        univTableView.tableFooterView = UIView()
        univTVWidthConstraint.constant = UIScreen.main.bounds.width * 0.9
        ServerConst.sharedInstance.getUniversity(nil, limit: nil, skip: nil) { (univArr, error) in
            if univArr != nil {
                self.universities = univArr!
                self.univTableView.reloadData()
            } else {
                //TODO: error situation
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
        univTableView.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0.3, options: .curveEaseOut, animations: {
            self.titleLabel.alpha = 1
            self.univTableView.alpha = 1
            self.titleLabelToCenterConstraint.constant = UIScreen.main.bounds.height * -0.2
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return universities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LoginUnivChooseCell", for: indexPath) as! LoginUnivChooseCell
        cell.univLabel.text = universities[(indexPath as NSIndexPath).row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let a = universities[indexPath.row]
        ServerConst.sharedInstance.postUpdateUser(["university":a.id! as AnyObject]) { (success, error) in
            if success {
                try! Realm().write({ 
                    User.currentUser?.universityID = self.universities[indexPath.row].id
                })
                self.delegate?.moveToVC(1)
            } else {
                //TODO: error
            }
        }
        univTableView.deselectRow(at: indexPath, animated: true)
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
