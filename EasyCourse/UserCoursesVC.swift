//
//  UserCoursesVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/13/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift
import JGProgressHUD

class UserCoursesVC: UIViewController, cellTableviewProtocol {
    
    @IBOutlet weak var courseTableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var searchView: UIView!
    
    let userCourses = try! Realm().objects(Course.self)
    var filterCourses:[Course] = []
    var searchStatus = Constant.searchStatus.notSearching

    //Load more
    var pageOffset = 20
    var page = 0
    var noMoreData = false
    var isMoreDataLoading = false
    var loadingMoreView: InfiniteScrollActivityView?
    
    var notificationToken: NotificationToken? = nil
    
    var hud:JGProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        self.navigationItem.title = "My courses"
        
        courseTableView.delegate = self
        courseTableView.dataSource = self
        courseTableView.tableFooterView = UIView()
        courseTableView.register(UINib(nibName: "LoadingTVCell", bundle: nil), forCellReuseIdentifier: "LoadingTVCell")
        
        searchView.layer.cornerRadius = searchView.frame.height/2
        searchView.layer.masksToBounds = true
        searchView.layer.borderWidth = 1
        searchView.layer.borderColor = UIColor.lightGray.cgColor
        
        searchTextField.delegate = self
        searchTextField.becomeFirstResponder()
        
        let frame = CGRect(x: 0, y: courseTableView.contentSize.height, width: courseTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        courseTableView.addSubview(loadingMoreView!)
        
        var insets = courseTableView.contentInset;
        insets.bottom += InfiniteScrollActivityView.defaultHeight;
        courseTableView.contentInset = insets
        
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
    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        self.view.endEditing(true)
//    }
    

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
        page = 0
        noMoreData = false
        if !text.isEmpty {
            searchCourse(text: text, page: 0)
        } else {
            searchStatus = .notSearching
            self.courseTableView.reloadData()
        }
    }
    
    func searchCourse(text:String, page:Int) {
        searchStatus = .isSearching
        self.courseTableView.reloadData()
        ServerConst.sharedInstance.searchCourse(text, limit: pageOffset, skip: page, completion: { (courseArr, error) in
            if error != nil {
                self.searchStatus = .receivedError
            } else {
                self.noMoreData = courseArr.count < self.pageOffset
                self.filterCourses = courseArr
                self.searchStatus = self.filterCourses.isEmpty ? .receivedEmptyResult : .receivedResult
            }
            self.courseTableView.reloadData()
        })
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
        if searchStatus == .isSearching || searchStatus == .receivedEmptyResult || searchStatus == .receivedError {
            return 1
        } else {
            return searchTextField.text?.isEmpty == false ? filterCourses.count : userCourses.count
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
            let courseCell = tableView.dequeueReusableCell(withIdentifier: "UserCoursesTVCell", for: indexPath) as! UserCoursesTVCell
            courseCell.configureCell(filterCourses[indexPath.row], userJoinedCourses: userCourses)
            courseCell.delegate = self
            return courseCell
        case .notSearching:
            let courseCell = tableView.dequeueReusableCell(withIdentifier: "UserCoursesTVCell", for: indexPath) as! UserCoursesTVCell
            courseCell.configureCell(userCourses[indexPath.row], userJoinedCourses: userCourses)
            courseCell.delegate = self
            return courseCell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchStatus == .receivedError {
            searchCourse(text: searchTextField.text ?? "", page:0)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
        if (!noMoreData && !isMoreDataLoading && searchStatus != .notSearching) {
            // ... Code to load more results ...
            let scrollViewContentHeight = courseTableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - courseTableView.bounds.size.height
            
            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && courseTableView.isDragging) {
                isMoreDataLoading = true
                let frame = CGRect(x:0, y:courseTableView.contentSize.height, width:courseTableView.bounds.size.width, height:InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                
                // ... Code to load more results ...
                page += 1
                ServerConst.sharedInstance.searchCourse(searchTextField.text ?? "", limit: pageOffset, skip: page*pageOffset, completion: { (courseArr, error) in
                    if error != nil {
                        self.searchStatus = .receivedError
                    } else {
                        self.noMoreData = courseArr.count < self.pageOffset
                        self.filterCourses += courseArr
                        self.searchStatus = self.filterCourses.isEmpty ? .receivedEmptyResult : .receivedResult
                    }
                    self.isMoreDataLoading = false
                    self.loadingMoreView?.stopAnimating()
                    self.courseTableView.reloadData()
                })
            }
        }
    }
    
}
