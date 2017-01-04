//
//  UserEditProfileChooseLangVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 1/3/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit

class UserEditProfileChooseLangVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var LangTableView: UITableView!
    
    var langArray:[(code: String, name: String, displayName: String)] = []
    var selectedCode:[String] = []
    var delegate:viewUpdateDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LangTableView.delegate = self
        LangTableView.dataSource = self
        LangTableView.tableFooterView = UIView()
        
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
            delegate?.viewUpdateWithData(value: selectedCode)
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
        } else {
            selectedCode.append(langArray[indexPath.row].code)
            delegate?.viewUpdateWithData(value: selectedCode)
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        }
        tableView.deselectRow(at: indexPath, animated: true)
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
