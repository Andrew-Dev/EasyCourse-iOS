//
//  UserEditProfileChooseLangVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 1/3/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit
import JGProgressHUD

class UserEditProfileChooseLangVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var LangTableView: UITableView!
    
    var langArray:[(code: String, name: String, displayName: String)] = []
    var selectedCode:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LangTableView.delegate = self
        LangTableView.dataSource = self
        LangTableView.tableFooterView = UIView()
        
        let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(self.saveLang))
        self.navigationItem.rightBarButtonItem = saveButton
        
        selectedCode = User.currentUser?.userLang() ?? []
        
        ServerConst.sharedInstance.getDefaultLanguage { (language, error) in
            if (error != nil) {
                
            } else {
                self.langArray = language
                self.LangTableView.reloadData()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return langArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = langArray[indexPath.row].displayName
        if selectedCode.index(of: langArray[indexPath.row].code) != nil {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let index = selectedCode.index(of: langArray[indexPath.row].code) {
            selectedCode.remove(at: index)
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
        } else {
            selectedCode.append(langArray[indexPath.row].code)
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func saveLang() {
        let hud = JGProgressHUD()
        hud.show(in: self.view)
        SocketIOManager.sharedInstance.syncUser(nil, userProfileImage: nil, userLang: selectedCode) { (success, error) in
            if success {
                hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                hud.dismiss()
                _ = self.navigationController?.popViewController(animated: true)
            } else {
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = error?.description ?? "Error"
                hud.tapOutsideBlock = { (hu) in hud.dismiss() }
                hud.tapOnHUDViewBlock = { (hu) in hud.dismiss() }
            }
        }
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
