//
//  LoginCourseComponentVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 8/28/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class LoginCourseComponentVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    
    weak var delegate: moveToVCProtocol?
    
    @IBOutlet weak var titleLabel: UILabel!

    
    @IBOutlet weak var courseSearchTextField: UITextField!
    
    @IBOutlet weak var courseListTableView: UITableView!
    
    @IBOutlet weak var backBtn: UIButton!
    
    @IBOutlet weak var nextBtn: UIButton!
    
    @IBOutlet weak var seperatorLineView: UIView!
    
    
    @IBOutlet weak var searchTextFieldWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleLabelToCenterConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var nextBtnWidthConstraint: NSLayoutConstraint!
    
    var courseList:[Course] = []
    var choosedCourse:[Course] = []
    var isSearching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.textColor = UIColor(white: 0.9, alpha: 1)
        
        titleLabelToCenterConstraint.constant = UIScreen.main.bounds.height * -0.25
        nextBtn.layer.cornerRadius = nextBtn.frame.height/2
        nextBtn.layer.borderColor = UIColor.white.cgColor
        nextBtn.layer.borderWidth = 1
        nextBtn.layer.masksToBounds = true
        nextBtn.tintColor = UIColor.white
        
        backBtn.layer.cornerRadius = nextBtn.frame.height/2
        backBtn.layer.borderColor = UIColor(white: 0.5, alpha: 1).cgColor
        backBtn.layer.borderWidth = 1
        backBtn.layer.masksToBounds = true
        backBtn.tintColor = UIColor(white: 0.5, alpha: 1)
        
        courseListTableView.delegate = self
        courseListTableView.dataSource = self
        courseListTableView.register(UINib(nibName: "LoginCourseChooseTVCell", bundle: nil), forCellReuseIdentifier: "LoginCourseChooseTVCell")
        courseListTableView.tableFooterView = UIView()
        
        
        let spacerView = UIView(frame:CGRect(x:0, y:0, width:10, height:10))
        courseSearchTextField.leftViewMode = UITextFieldViewMode.always
        courseSearchTextField.leftView = spacerView
        courseSearchTextField.backgroundColor = UIColor.white
        courseSearchTextField.delegate = self
        
        searchTextFieldWidthConstraint.constant = UIScreen.main.bounds.width * 0.9
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        titleLabel.alpha = 0
        courseListTableView.alpha = 0
        courseSearchTextField.alpha = 0
        backBtn.alpha = 0
        nextBtn.alpha = 0
        seperatorLineView.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0.3, options: .curveEaseOut, animations: {
            self.titleLabel.alpha = 1
            self.courseListTableView.alpha = 1
            self.courseSearchTextField.alpha = 1
            self.backBtn.alpha = 1
            self.nextBtn.alpha = 1
            self.seperatorLineView.alpha = 1
            self.titleLabelToCenterConstraint.constant = UIScreen.main.bounds.height * -0.3
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? courseList.count : choosedCourse.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LoginCourseChooseTVCell", for: indexPath) as! LoginCourseChooseTVCell
        let course = isSearching ? courseList[(indexPath as NSIndexPath).row] : choosedCourse[(indexPath as NSIndexPath).row]
        cell.courseNameLabel.text = course.coursename
        cell.courseTitleLabel.text = course.title
        let courseExisted = choosedCourse.contains { (crs) -> Bool in
            return crs.id == course.id
        }
        
        if courseExisted {
            cell.backgroundColor = Design.color.cellSelectedGreen()
            cell.operationImgView.image = UIImage(named: "close-ion")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            cell.operationImgView.tintColor = UIColor.red
        } else {
            cell.backgroundColor = UIColor.white
            cell.operationImgView.image = UIImage(named: "plus-ion")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            cell.operationImgView.tintColor = UIColor(red: 0, green: 200/255, blue: 7/255, alpha: 1)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        titleLabel.text = "Choose your course (\(choosedCourse.count))"
        if !isSearching {
            choosedCourse.remove(at: (indexPath as NSIndexPath).row)
            courseListTableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.middle)
        } else {
            let courseExisted = choosedCourse.index(where: { (crs) -> Bool in
                return crs.id == courseList[(indexPath as NSIndexPath).row].id
            })
            if courseExisted != nil {
                choosedCourse.remove(at: courseExisted!)
            } else {
                choosedCourse.append(courseList[(indexPath as NSIndexPath).row])
            }
            tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.middle)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Text Field
    
    @IBAction func searchTextFieldChanged(_ sender: UITextField) {
        
        if sender.text?.isEmpty == false {
            ServerConst.sharedInstance.searchCourse(sender.text) { (courseArr, error) in
                
                if error == nil {
                    self.isSearching = true
                    self.courseList = courseArr ?? []
                    self.courseListTableView.reloadData()
                }
            }
        } else {
            isSearching = false
            self.courseList = []
            self.courseListTableView.reloadData()
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func nextBtnPressed(_ sender: UIButton) {
        let realm = try! Realm()
        Course.removeAllCourse()
        for course in choosedCourse {
            try! realm.write({
                realm.add(course)
            })
        }
        delegate?.moveToVC(2)
    }
    
    @IBAction func backBtnPressed(_ sender: UIButton) {
        choosedCourse = []
        delegate?.moveToVC(0)
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
