//
//  LoginCourseComponentVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 8/28/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class LoginCourseComponentVC: UIViewController, UITextFieldDelegate {
    
    
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
    var searchStatus = Constant.searchStatus.notSearching
    
    //Load more
    var pageOffset = 20
    var page = 0
    var noMoreData = false
    var isMoreDataLoading = false
    var loadingMoreView: InfiniteScrollActivityView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
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
        courseListTableView.register(UINib(nibName: "LoadingTVCell", bundle: nil), forCellReuseIdentifier: "LoadingTVCell")
        courseListTableView.tableFooterView = UIView()
        
        
        let spacerView = UIView(frame:CGRect(x:0, y:0, width:10, height:10))
        courseSearchTextField.leftViewMode = UITextFieldViewMode.always
        courseSearchTextField.leftView = spacerView
        courseSearchTextField.backgroundColor = UIColor.white
        courseSearchTextField.delegate = self
        courseSearchTextField.becomeFirstResponder()
        
        let frame = CGRect(x: 0, y: courseListTableView.contentSize.height, width: courseListTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        courseListTableView.addSubview(loadingMoreView!)
        
        var insets = courseListTableView.contentInset;
        insets.bottom += InfiniteScrollActivityView.defaultHeight;
        courseListTableView.contentInset = insets
        
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
    
    func searchCourse(text:String, page:Int) {
        searchStatus = .isSearching
        self.courseListTableView.reloadData()
        ServerConst.sharedInstance.searchCourse(text, limit: pageOffset, skip: page, completion: { (courseArr, error) in
            if error != nil {
                self.searchStatus = .receivedError
            } else {
                self.noMoreData = courseArr.count < self.pageOffset
                self.courseList = courseArr
                self.searchStatus = self.courseList.isEmpty ? .receivedEmptyResult : .receivedResult
            }
            self.courseListTableView.reloadData()
        })
    }
    
    
    //MARK: - Text Field
    
    @IBAction func searchTextFieldChanged(_ sender: UITextField) {
        let text = sender.text ?? ""
        courseList = []
        page = 0
        noMoreData = false
        if !text.isEmpty {
            searchCourse(text: text, page: 0)
        } else {
            searchStatus = .notSearching
            self.courseListTableView.reloadData()
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func nextBtnPressed(_ sender: UIButton) {
        let realm = try! Realm()
        for course in choosedCourse {
            try! realm.write({
                realm.add(course, update: true)
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

extension LoginCourseComponentVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return isSearching ? courseList.count : choosedCourse.count
        if searchStatus == .isSearching || searchStatus == .receivedEmptyResult || searchStatus == .receivedError {
            return 1
        } else {
            return courseSearchTextField.text?.isEmpty == false ? courseList.count : choosedCourse.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch searchStatus {
        case .isSearching:
            let statusCell = tableView.dequeueReusableCell(withIdentifier: "LoadingTVCell", for: indexPath) as! LoadingTVCell
            statusCell.configureCell(loadingStatus: searchStatus, text: nil)
            return statusCell
        case .receivedEmptyResult:
            let statusCell = tableView.dequeueReusableCell(withIdentifier: "LoadingTVCell", for: indexPath) as! LoadingTVCell
            statusCell.configureCell(loadingStatus: searchStatus, text: "No results")
            return statusCell
        case .receivedError:
            let statusCell = tableView.dequeueReusableCell(withIdentifier: "LoadingTVCell", for: indexPath) as! LoadingTVCell
            statusCell.configureCell(loadingStatus: searchStatus, text: "Error, tap to reconnect")
            return statusCell
        case .receivedResult:
            let courseCell = tableView.dequeueReusableCell(withIdentifier: "LoginCourseChooseTVCell", for: indexPath) as! LoginCourseChooseTVCell
            let courseChoosed = choosedCourse.contains { (crs) -> Bool in
                return crs.id == courseList[indexPath.row].id
            }
            courseCell.configureCell(course: courseList[indexPath.row], choosed: courseChoosed)
            return courseCell
        case .notSearching:
            let courseCell = tableView.dequeueReusableCell(withIdentifier: "LoginCourseChooseTVCell", for: indexPath) as! LoginCourseChooseTVCell
            courseCell.configureCell(course: choosedCourse[indexPath.row], choosed: true)
            return courseCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchStatus == .receivedError {
            searchCourse(text: courseSearchTextField.text ?? "", page:0)
        } else if searchStatus == .notSearching {
            choosedCourse.remove(at: (indexPath as NSIndexPath).row)
            courseListTableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.middle)
        } else if searchStatus == .receivedResult || searchStatus == .notSearching {
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
        
        
        
//        if !isSearching {
//            choosedCourse.remove(at: (indexPath as NSIndexPath).row)
//            courseListTableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.middle)
//        } else {
//            let courseExisted = choosedCourse.index(where: { (crs) -> Bool in
//                return crs.id == courseList[(indexPath as NSIndexPath).row].id
//            })
//            if courseExisted != nil {
//                choosedCourse.remove(at: courseExisted!)
//            } else {
//                choosedCourse.append(courseList[(indexPath as NSIndexPath).row])
//            }
//            tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.middle)
//        }
        titleLabel.text = "Choose your course (\(choosedCourse.count))"
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
        if (!noMoreData && !isMoreDataLoading && searchStatus != .notSearching) {
            // ... Code to load more results ...
            let scrollViewContentHeight = courseListTableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - courseListTableView.bounds.size.height
            
            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && courseListTableView.isDragging) {
                isMoreDataLoading = true
                let frame = CGRect(x:0, y:courseListTableView.contentSize.height, width:courseListTableView.bounds.size.width, height:InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                
                // ... Code to load more results ...
                page += 1
                ServerConst.sharedInstance.searchCourse(courseSearchTextField.text ?? "", limit: pageOffset, skip: page*pageOffset, completion: { (courseArr, error) in
                    if error != nil {
                        self.searchStatus = .receivedError
                    } else {
                        self.noMoreData = courseArr.count < self.pageOffset
                        self.courseList += courseArr
                        self.searchStatus = self.courseList.isEmpty ? .receivedEmptyResult : .receivedResult
                    }
                    self.isMoreDataLoading = false
                    self.loadingMoreView?.stopAnimating()
                    self.courseListTableView.reloadData()
                })
            }
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
}
