//
//  ClassmatesVC.swift
//  EasyCourse
//
//  Created by Andrew Arpasi on 11/12/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class RoomDetailClassmatesVC: UIViewController {

    @IBOutlet weak var classmatesTableView: UITableView!
    
    var roomId:String!
    var room:Room!
    
    var userArray:[User] = []
    
    //Load more
    var pageOffset = 20
    var page = -1
    var noMoreData = false
    var isMoreDataLoading = false
    var loadingMoreView: InfiniteScrollActivityView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        classmatesTableView.delegate = self
        classmatesTableView.dataSource = self
        classmatesTableView.tableFooterView = UIView()
        
        let frame = CGRect(x: 0, y: classmatesTableView.contentSize.height, width: classmatesTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        classmatesTableView.addSubview(loadingMoreView!)
        
        var insets = classmatesTableView.contentInset;
        insets.bottom += InfiniteScrollActivityView.defaultHeight;
        classmatesTableView.contentInset = insets

        
        SocketIOManager.sharedInstance.getRoomMembers(roomId, limit: pageOffset, skip: (page+1)*pageOffset, refresh: true) { (users, error) in
            if error != nil {
                
            } else {
                self.page += 1
                self.noMoreData = users.count < self.pageOffset
                self.userArray = users
                self.classmatesTableView.reloadData()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

    

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "classmatesToUserDetail" {
            if let indexPath = classmatesTableView.indexPathForSelectedRow {
                let vc = segue.destination as! UserDetailTableVC
                vc.userId = userArray[indexPath.row].id
            }
            
        }
    }
 

}

extension RoomDetailClassmatesVC: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userArray.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "classmatesToUserDetail", sender: self)
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoomDetailClassmatesTVCell", for: indexPath) as! RoomDetailClassmatesTVCell
        
        cell.configureCell(user: userArray[indexPath.row])
        
        return cell
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
        if (!noMoreData && !isMoreDataLoading) {
            // ... Code to load more results ...
            let scrollViewContentHeight = classmatesTableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - classmatesTableView.bounds.size.height
            
            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && classmatesTableView.isDragging) {
                isMoreDataLoading = true
                let frame = CGRect(x:0, y:classmatesTableView.contentSize.height, width:classmatesTableView.bounds.size.width, height:InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                
                // ... Code to load more results ...
                
                SocketIOManager.sharedInstance.getRoomMembers(roomId, limit: pageOffset, skip: (page+1)*pageOffset, refresh: true, completion: { (users, error) in
                    if error != nil {
                        
                    } else {
                        self.page += 1
                        self.noMoreData = users.count < self.pageOffset
                        self.userArray += users
                    }
                    self.isMoreDataLoading = false
                    self.loadingMoreView?.stopAnimating()
                    self.classmatesTableView.reloadData()
                })
            }
        }
    }

}
