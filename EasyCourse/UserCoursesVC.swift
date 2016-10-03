//
//  UserCoursesVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/13/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class UserCoursesVC: UIViewController, cellTableviewProtocol {
    
    @IBOutlet weak var courseTableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    
    let userCourses = try! Realm().objects(Course.self)
    var filterCourses:[Course] = []
    var isSearching = false
    var notificationToken: NotificationToken? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "My courses"
        
        courseTableView.delegate = self
        courseTableView.dataSource = self
        courseTableView.tableFooterView = UIView()
        
        searchTextField.delegate = self
        searchTextField.becomeFirstResponder()
        
        notificationToken = userCourses.addNotificationBlock({ (result) in
            self.courseTableView.reloadData()
        })
    }
    
    deinit {
        notificationToken?.stop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func searchContentChanged(_ sender: UITextField) {
        let text = sender.text ?? ""
        filterCourses = []
        if !text.isEmpty {
            ServerConst.sharedInstance.searchCourse(text, completion: { (courseArr, error) in
                self.isSearching = true
                self.filterCourses = courseArr ?? []
                self.courseTableView.reloadData()
            })
        } else {
            isSearching = false
            self.courseTableView.reloadData()
        }
    }
    
    func reloadTableView() {
        courseTableView.reloadData()
    }

}

extension UserCoursesVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }
}

extension UserCoursesVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filterCourses.count : userCourses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCoursesTVCell", for: indexPath) as! UserCoursesTVCell
        if isSearching {
            cell.configureCell(filterCourses[indexPath.row], userJoinedCourses: userCourses)
        } else {
            cell.configureCell(userCourses[indexPath.row], userJoinedCourses: userCourses)
        }
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
