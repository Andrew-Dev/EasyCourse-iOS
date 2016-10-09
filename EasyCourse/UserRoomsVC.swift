//
//  UserRoomsVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/13/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

@objc protocol cellTableviewProtocol : NSObjectProtocol {
    func reloadTableView()-> Void
    @objc optional func displayViews(_ id: String)->Void
}

class UserRoomsVC: UIViewController, cellTableviewProtocol {
    
    @IBOutlet weak var roomsTableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var searchView: UIView!
    
    let userRooms = try! Realm().objects(Room.self)
    var filterRooms:[Room] = []
//    var isSearching = false
    var notificationToken: NotificationToken? = nil
    
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
        self.navigationItem.title = "My rooms"
        
        roomsTableView.delegate = self
        roomsTableView.dataSource = self
        roomsTableView.tableFooterView = UIView()
        roomsTableView.register(UINib(nibName: "LoadingTVCell", bundle: nil), forCellReuseIdentifier: "LoadingTVCell")
        
        
        
        searchTextField.delegate = self
        searchTextField.becomeFirstResponder()
        
        let frame = CGRect(x: 0, y: roomsTableView.contentSize.height, width: roomsTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        roomsTableView.addSubview(loadingMoreView!)
        
        var insets = roomsTableView.contentInset;
        insets.bottom += InfiniteScrollActivityView.defaultHeight;
        roomsTableView.contentInset = insets
        
        notificationToken = userRooms.addNotificationBlock({ (result) in
            self.roomsTableView.reloadData()
        })
    }
    
    deinit {
        notificationToken?.stop()
    }
    
    override func viewWillLayoutSubviews() {
        searchView.layer.cornerRadius = searchView.frame.height/2
        searchView.layer.masksToBounds = true
        searchView.layer.borderWidth = 1
        searchView.layer.borderColor = UIColor.lightGray.cgColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func searchRoomTextChanged(_ sender: UITextField) {
        let text = sender.text ?? ""
        filterRooms = []
        page = 0
        noMoreData = false
        if !text.isEmpty {
            searchCourse(text: text, page: 0)
        } else {
            searchStatus = .notSearching
            self.roomsTableView.reloadData()
        }
    }
    
    func searchCourse(text:String, page:Int) {
        searchStatus = .isSearching
        roomsTableView.reloadData()
        
        SocketIOManager.sharedInstance.searchRoom(text, limit: pageOffset, skip: page) { (roomArr, error) in
            if error != nil {
                self.searchStatus = .receivedError
            } else {
                self.noMoreData = roomArr.count < self.pageOffset
                self.filterRooms = roomArr
                self.searchStatus = self.filterRooms.isEmpty ? .receivedEmptyResult : .receivedResult
            }
            self.roomsTableView.reloadData()
        }
    }
    
    func reloadTableView() {
        roomsTableView.reloadData()
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

extension UserRoomsVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }
}

extension UserRoomsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchStatus == .isSearching || searchStatus == .receivedEmptyResult || searchStatus == .receivedError {
            return 1
        } else {
            return searchTextField.text?.isEmpty == false ? filterRooms.count : userRooms.count
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
            let roomCell = tableView.dequeueReusableCell(withIdentifier: "UserRoomsTVCell", for: indexPath) as! UserRoomsTVCell
            roomCell.configureCell(filterRooms[indexPath.row], userJoinedRooms: userRooms)
            roomCell.delegate = self
            return roomCell
        case .notSearching:
            let roomCell = tableView.dequeueReusableCell(withIdentifier: "UserRoomsTVCell", for: indexPath) as! UserRoomsTVCell
            roomCell.configureCell(userRooms[indexPath.row], userJoinedRooms: userRooms)
            roomCell.delegate = self
            return roomCell
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
            let scrollViewContentHeight = roomsTableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - roomsTableView.bounds.size.height
            
            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && roomsTableView.isDragging) {
                isMoreDataLoading = true
                let frame = CGRect(x:0, y:roomsTableView.contentSize.height, width:roomsTableView.bounds.size.width, height:InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                
                // ... Code to load more results ...
                page += 1
                SocketIOManager.sharedInstance.searchRoom(searchTextField.text ?? "", limit: pageOffset, skip: page*pageOffset, completion: { (roomsArr, error) in
                    if error != nil {
                        self.searchStatus = .receivedError
                    } else  {
                        self.noMoreData = roomsArr.count < self.pageOffset
                        self.filterRooms += roomsArr
                        self.searchStatus = self.filterRooms.isEmpty ? .receivedEmptyResult : .receivedResult
                    }
                    self.isMoreDataLoading = false
                    self.loadingMoreView?.stopAnimating()
                    self.roomsTableView.reloadData()
                })
            }
        }
    }
}
