//
//  RoomsDialogVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/8/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift
import DKImagePickerController
import MWPhotoBrowser
import LDONavigationSubtitleView
import JGProgressHUD
import Async

protocol popUpMessageProtocol : NSObjectProtocol {
    func popUpImage(_ imageView:UIImageView, message:Message) -> Void
    func popUpSharedRoom(_  message:Message) -> Void
    func popUpResend(_ message:Message) -> Void
}

class RoomsDialogVC: UIViewController, UITableViewDelegate, UITableViewDataSource, cellTableviewProtocol {
    
    @IBOutlet weak var messageTableView: UITableView!
    
    @IBOutlet weak var inputTextView: UITextView!
    
    @IBOutlet weak var sendBtn: UIButton!
    
    @IBOutlet weak var accessoryBtn: UIButton!
    
    @IBOutlet weak var accessoryView: UIView!
    
    
    @IBOutlet weak var accImgBtn: UIButton!
    
    @IBOutlet weak var accRoomBtn: UIButton!
    
    @IBOutlet weak var inputViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var inputBottomConstraint: NSLayoutConstraint!
    
    
    
    
    //Type: group chat or private chat
    var otherUser:User?
    
    //Data
    var liveMessage:Results<(Message)>!
    var liveImageMessage:Results<(Message)>!
    var localRoomId:String!
    var localRoom:Room {
        get {
            let realm = try! Realm()
            let room = realm.object(ofType: Room.self, forPrimaryKey: localRoomId)
            if room != nil {
                return room!
            } else {
                _ = self.navigationController?.popToRootViewController(animated: true)
                return Room()
            }
        }
    }
//    var msgPage = 0
    var msgHidePage = 0
    var msgOffset = 10
    var scrollLoadingMore = false
    
    //UI
    var placeholderLabel:UILabel!
    var goToBottomAtFirst = true
    var accessoryViewShow = false
    let transition = PopAnimator()
    var selectedImageView:UIImageView?
    var tappedUserId:String?

    var selectedMsg:Message?
    
    //Notif
    var messageUpdateNotif: NotificationToken? = nil
    var roomUpdateNotif: NotificationToken? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Load data
        liveMessage = localRoom.getMessage()
//        liveMessage = localRoom.messageList
        liveImageMessage = localRoom.getMessageContainsImage()
        
        msgHidePage = max(liveMessage.count / msgOffset - 1, 0)
        
        //UI
        if localRoom.isToUser {
            otherUser = try! Realm().object(ofType: User.self, forPrimaryKey: localRoom.id)
            self.navigationItem.title = otherUser?.username
        } else {
            let customTitleView = LDONavigationSubtitleView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
            if localRoom.memberCountsDescription != nil {
                customTitleView.subtitle = "\(localRoom.memberCountsDescription!) people"
            }
            customTitleView.title = localRoom.roomname!
            self.navigationItem.titleView = customTitleView
        }
        
        messageTableView.delegate = self
        messageTableView.dataSource = self
        messageTableView.estimatedRowHeight = 120
        messageTableView.rowHeight = UITableViewAutomaticDimension
        messageTableView.tableFooterView = UIView()
        messageTableView.backgroundColor = Design.color.backGroudColor
        
        
        inputTextView.delegate = self
        inputTextView.layer.cornerRadius = 4.0
        inputTextView.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        inputTextView.layer.borderWidth = 0.8
        
        sendBtn.isEnabled = false
        
        placeholderLabel = UILabel()
        placeholderLabel.text = "Send message..."
        placeholderLabel.font = UIFont.systemFont(ofSize: inputTextView.font!.pointSize)
        placeholderLabel.sizeToFit()
        inputTextView.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x: 5, y: 0)
        placeholderLabel.frame.size.height = inputTextView.frame.height
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.isHidden = !inputTextView.text.isEmpty
        
        
        accessoryView.isHidden = true
        
        accImgBtn.layer.cornerRadius = 12
        accImgBtn.layer.borderWidth = 1
        accImgBtn.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        accImgBtn.layer.masksToBounds = true
        accImgBtn.backgroundColor = UIColor(white: 0.98, alpha: 1)
        
        accRoomBtn.layer.cornerRadius = 12
        accRoomBtn.layer.borderWidth = 1
        accRoomBtn.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        accRoomBtn.layer.masksToBounds = true
        accRoomBtn.backgroundColor = UIColor(white: 0.98, alpha: 1)
        
        //Navigation
        let detailButton = UIBarButtonItem(title: "More", style: UIBarButtonItemStyle.done, target: self, action: #selector(self.gotoDetail))
        self.navigationItem.rightBarButtonItem = detailButton
        
        //Notification
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyboardWasShown(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyboardWillDisappear(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
//        messageUpdateNotif = liveMessage.addNotificationBlock({ (result) in
//            print("get message notif")
//            self.loadMessage()
//        })
        
        messageUpdateNotif = liveMessage.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.messageTableView else { return }
            switch changes {
            case .initial:
                tableView.reloadData()
                break
            case .update(_, let deletions, let insertions, let modifications):
                print("delete:\(deletions) || insert:\(insertions) || modifications:\(modifications)")
                if insertions.count > 0 {
                    let scrollToBottom = tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height)
                    tableView.reloadData()
                    for i in insertions {
                        if self!.liveMessage[i].senderId == User.currentUser!.id || scrollToBottom {
                            self!.scrollToBottom(true)
                            break
                        }
                    }
                }
                
                if let vRows = tableView.indexPathsForVisibleRows {
                    deletions.forEach({ (deleteIndex) in
                        let rowIndexPath = IndexPath(row: deleteIndex - self!.msgHidePage*self!.msgOffset, section: 0)
                        if vRows.contains(rowIndexPath) {
                            print("delete visible: \(rowIndexPath.row)")
                            tableView.deleteRows(at: [rowIndexPath], with: .none)
                        } else {
                            print("delete reloadData")
                            tableView.reloadData()
                        }
                    })
                    
                    modifications.forEach({ (modifyIndex) in
                        if self?.liveMessage[modifyIndex].successSent.value == false {
                            let rowIndexPath = IndexPath(row: modifyIndex - self!.msgHidePage*self!.msgOffset, section: 0)
                            if vRows.contains(rowIndexPath) {
                                print("modify visible: \(rowIndexPath.row)")
                                tableView.reloadRows(at: [rowIndexPath], with: .none)
                            } else {
                                print("modify reloadData")
                                tableView.reloadData()
                            }
                        }
                        
                    })
                }
                
                break
                
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
                break
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.gobackToLastView), name: Constant.NotificationKey.RoomDelete, object: nil)
        
    }
    
    func mapMsgIndexToCell(dbIndex:Int) -> Int {
        print("insert index=\(dbIndex - msgHidePage*msgOffset) || livemsg=\(liveMessage.count) || cellcnt=\(messageTableView.numberOfRows(inSection: 0))")
        return dbIndex - msgHidePage*msgOffset
    }
    
    
    
    deinit {
        messageUpdateNotif?.stop()
        roomUpdateNotif?.stop()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.endEditing(true)
        inputBottomConstraint.constant = 0
        turnOffAccessoryView()
        
        if try! Realm().object(ofType: Room.self, forPrimaryKey: localRoomId) == nil {
            _ = navigationController?.popToRootViewController(animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        try! Realm().write({ 
            localRoom.unread = 0
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if goToBottomAtFirst {
            messageTableView.reloadData()
            scrollToBottom(false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        goToBottomAtFirst = false
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadMessage() {
        messageTableView.reloadData()
        scrollToBottom(true)
    }
    
    // MARK: - TableView delegate -
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let cnt = min((msgPage+1) * msgOffset, liveMessage.count)
        let cnt = liveMessage.count - msgHidePage * msgOffset
        return cnt
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cellCnt = min((msgPage+1) * msgOffset, liveMessage.count)
//        
//        let msgIndex = liveMessage.count - (cellCnt - indexPath.row)
        
        let msgIndex = indexPath.row + msgHidePage * msgOffset
//        print("indexpath: \(indexPath.row) || msgIndex: \(msgIndex)")
        if liveMessage[msgIndex].senderId == User.currentUser?.id {
            if liveMessage[msgIndex].imageData != nil || liveMessage[msgIndex].imageUrl != nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MessageOutgoingImageCell", for: indexPath) as! MessageOutgoingImageCell
                var lastMessage:Message?
                if msgIndex != 0 {
                    lastMessage = liveMessage[msgIndex - 1]
                }
                cell.delegate = self
                cell.configureCell(liveMessage[msgIndex], lastMessage: lastMessage)
                return cell
            } else if liveMessage[msgIndex].sharedRoom != nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MessageOutgoingGroupCell", for: indexPath) as! MessageOutgoingGroupCell
                var lastMessage:Message?
                if msgIndex != 0 {
                    lastMessage = liveMessage[msgIndex - 1]
                }
                cell.delegate = self
                cell.configureCell(liveMessage[msgIndex], lastMessage: lastMessage)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MessageOutgoingTextCell", for: indexPath) as! MessageOutgoingTextCell
                var lastMessage:Message?
                if msgIndex != 0 {
                    lastMessage = liveMessage[msgIndex - 1]
                }
                cell.delegate = self
                cell.configureCell(liveMessage[msgIndex], lastMessage: lastMessage)
                return cell
            }
            
        } else {
            if liveMessage[msgIndex].imageUrl != nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MessageIncomingImageCell", for: indexPath) as! MessageIncomingImageCell
                var lastMessage:Message?
                if msgIndex != 0 {
                    lastMessage = liveMessage[msgIndex - 1]
                }
                cell.cellDelegate = self
                cell.popUpDelegate = self
                cell.configureCell(liveMessage[msgIndex], lastMessage: lastMessage)
                return cell
                
            } else if liveMessage[msgIndex].sharedRoom != nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MessageIncomingGroupCell", for: indexPath) as! MessageIncomingGroupCell
                var lastMessage:Message?
                if msgIndex != 0 {
                    lastMessage = liveMessage[msgIndex - 1]
                }
                cell.cellDelegate = self
                cell.popUpDelegate = self
                cell.configureCell(liveMessage[msgIndex], lastMessage: lastMessage)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MessageIncomingTextCell", for: indexPath) as! MessageIncomingTextCell
                var lastMessage:Message?
                if msgIndex != 0 {
                    lastMessage = liveMessage[msgIndex - 1]
                }
                cell.cellDelegate = self
                cell.configureCell(liveMessage[msgIndex], lastMessage: lastMessage)
                return cell
                
            }
            
        }
    }
    
    func scrollToBottom(_ animated: Bool) {
        if liveMessage.count > 1 {
//            print("to row: \(self.messageTableView.numberOfRows(inSection: 0) - 1)")
            self.messageTableView.scrollToRow(at: IndexPath(row: self.messageTableView.numberOfRows(inSection: 0) - 1, section: 0), at: .bottom, animated: animated)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.isKind(of: UITableView.self) {
            self.view.endEditing(true)
            if accessoryViewShow { turnOffAccessoryView() }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isKind(of: UITableView.self) {
            guard let vRows = messageTableView.indexPathsForVisibleRows else {
                return
            }
            if !scrollLoadingMore && scrollView.contentOffset.y < 0 && vRows.contains(IndexPath(row: 0, section: 0)) {
                
                scrollLoadingMore = true
                if liveMessage.count > self.messageTableView.numberOfRows(inSection: 0) {
                    if msgHidePage > 0 {
                        msgHidePage -= 1
                        messageTableView.reloadData()
                        messageTableView.scrollToRow(at: IndexPath(row: msgOffset, section: 0), at: .top, animated: false)
                        Async.background(after: 0.1, {
                            self.scrollLoadingMore = false
                        })
                        
                    }
                }
            }
            
        }
    }
    
    
    
    //MARK: - Button Action
    
    
    @IBAction func sendBtnPressed(_ sender: UIButton) {
        sendBtn.isEnabled = false
        let message = Message()
        message.initForCurrentUser(inputTextView.text, image: nil, sharedRoom: nil, toRoom: localRoom.id!, isToUser: localRoom.isToUser)
        message.saveToDatabase()
        inputTextView.text = ""
        UIView.animate(withDuration: 0.2, animations: {
            self.inputViewHeightConstraint.constant = 49
            self.inputTextView.layoutIfNeeded()
        }) 
        SocketIOManager.sharedInstance.sendMessage(message) { (success, error) in
            //TODO: message response
            self.messageTableView.reloadData()
            self.scrollToBottom(true)
            if error != nil {
                let hud = JGProgressHUD()
                hud.show(in: self.view)
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = error?.description ?? "Message sent fail"
                hud.dismiss(afterDelay: 2)
            }
        }
        
        
    }
    
    
    @IBAction func accessoryBtnPressed(_ sender: UIButton) {
        self.view.endEditing(true)
        accessoryBtn.isEnabled = false
        if accessoryViewShow {
            turnOffAccessoryView()
        } else {
            turnOnAccessoryView()
        }
    }
    
    @IBAction func accImgBtnPressed(_ sender: UIButton) {
        // MARK: Add Image
        turnOffAccessoryView()
        let pickerController = DKImagePickerController()
        pickerController.maxSelectableCount = 9
        pickerController.showsCancelButton = true
        pickerController.assetType = .allPhotos
        //            pickerController.defaultSelectedAssets = self.assets
        
        self.present(pickerController, animated: true, completion: nil)
        
        pickerController.didSelectAssets = { (assets: [DKAsset]) in
            print("didSelectAssets: \(assets.count) + \(assets)")
            self.scrollToBottom(true)
            for asset in assets {
                asset.fetchOriginalImageWithCompleteBlock({ (image, info) in
//                    let imageData = UIImageJPEGRepresentation(image!, 0)
                    
                    let message = Message()
                    message.initForCurrentUser(nil, image: image, sharedRoom: nil, toRoom: self.localRoom.id!, isToUser: self.localRoom.isToUser)
                    message.saveToDatabase()
                    SocketIOManager.sharedInstance.sendMessage(message, completion: { (success, error) in
                        //TODO: Message sent response
                        print("success send image: \(success) + \(error)")
                        if error != nil {
                            let hud = JGProgressHUD()
                            hud.show(in: self.view)
                            hud.indicatorView = JGProgressHUDErrorIndicatorView()
                            hud.textLabel.text = error?.description ?? "Message sent fail"
                            hud.dismiss(afterDelay: 2)
                        }
                    })
                })
                
            }
        }
    }
    
    
    @IBAction func accGroupBtnPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "openAccGroup", sender: self)
    }
    
    
    func turnOffAccessoryView() {
        UIView.animate(withDuration: 0.2, animations: {
            self.inputBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }, completion: { (finish) in
            self.accessoryView.isHidden = true
            self.accessoryViewShow = false
            self.accessoryBtn.isEnabled = true
        }) 
    }
    
    func turnOnAccessoryView() {
        accessoryView.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            self.inputBottomConstraint.constant = 100
            self.view.layoutIfNeeded()
        }, completion: { (finish) in
            self.scrollToBottom(true)
            self.accessoryViewShow = true
            self.accessoryBtn.isEnabled = true
        }) 
    }
    
    
     // MARK: - Navigation
    func gotoDetail() {
        if !localRoom.isToUser {
            self.performSegue(withIdentifier: "gotoRoomDetailPage", sender: self)
        } else {
            self.performSegue(withIdentifier: "gotoUserRoomDetailPage", sender: self)
        }
    }
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoUserDetailPage" {
            let vc = segue.destination as! UserDetailTableVC
            vc.userId = tappedUserId
            
            tappedUserId = nil
            
        } else if segue.identifier == "gotoRoomDetailPage" {
            let vc = segue.destination as! RoomDetailTableVC
            vc.room = localRoom
        } else if segue.identifier == "openAccGroup" {
            let navController = segue.destination as! UINavigationController
            let vc = navController.viewControllers[0] as! RoomsDialogAccGroupVC
            vc.toRoom = localRoom
        } else if segue.identifier == "gotoUserRoomDetailPage" {
            let vc = segue.destination as! UserRoomDetailTableVC
            vc.room = localRoom
            vc.user = otherUser
        }
     }
 
    
    func gobackToLastView(_ notification: Notification) {
        if let deletedRoomID = notification.object as? String {
            if deletedRoomID == localRoom.id {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    //MARK: - Cell table protocol
    func reloadTableView() {
        //
    }
    
    func displayViews(_ id:String) {
        tappedUserId = id
        self.performSegue(withIdentifier: "gotoUserDetailPage", sender: self)
    }
    
}

extension RoomsDialogVC: UITextViewDelegate {
    //MARK: - Text View Delegate -
    func textViewDidChange(_ textView: UITextView){
        placeholderLabel.isHidden = !textView.text.isEmpty
        sendBtn.isEnabled = !inputTextView.text.trimWhiteSpace().isEmpty

        let maxNumberOfLines:CGFloat = 3
        var maxHeight = CGFloat.greatestFiniteMagnitude
        if maxNumberOfLines > 0 {
            let font = inputTextView.font
            maxHeight = (ceil(font!.lineHeight) * maxNumberOfLines) + inputTextView.textContainerInset.top + inputTextView.textContainerInset.bottom + 16
        }
        
        let newSize:CGSize = inputTextView.sizeThatFits(CGSize(width: inputTextView.frame.width, height:CGFloat.greatestFiniteMagnitude))
        
        var expectedHeight:CGFloat = 44.0
        if newSize.height + 16 >= maxHeight {
            expectedHeight = maxHeight
            inputTextView.isScrollEnabled = true
        } else {
            expectedHeight = newSize.height + 16
            inputTextView.isScrollEnabled = false
        }
        let defaultHeight:CGFloat = 44
        
        UIView.animate(withDuration: 0.2, animations: {
            self.inputViewHeightConstraint.constant = expectedHeight < defaultHeight ? defaultHeight : expectedHeight
            self.view.layoutIfNeeded()
        })
        ensureCaretDisplaysCorrectly()
    }
    
    private func ensureCaretDisplaysCorrectly() {
        if let s = inputTextView.selectedTextRange {
            let rect = inputTextView.caretRect(for: s.end)
            UIView.performWithoutAnimation({ () -> Void in
                inputTextView.scrollRectToVisible(rect, animated: false)
            })
        }
    }
    
    func keyboardWasShown(_ notification:Notification) {
        let dict:NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        let s:NSValue = dict.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let rect:CGRect = s.cgRectValue
        
        UIView.animate(withDuration: 0.2, animations: {
            self.inputBottomConstraint.constant = rect.height
            self.view.layoutIfNeeded()
        }, completion: { (finish) in
            self.scrollToBottom(true)
            self.accessoryView.isHidden = true
            self.accessoryViewShow = false
        })
    }
    
    func keyboardWillDisappear(_ notification:Notification) {
        UIView.animate(withDuration: 0.2, animations: {
            self.inputBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }, completion: { (finish) in
            //
        }) 
    }
    
    func dismissKeyboard(_ sender: AnyObject?) {
        view.endEditing(true)
    }
    
   
}

extension RoomsDialogVC: MWPhotoBrowserDelegate {
    public func numberOfPhotos(in photoBrowser: MWPhotoBrowser!) -> UInt {
        return UInt(liveImageMessage.count)
    }
    
    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, photoAt index: UInt) -> MWPhotoProtocol! {
        let url = URL(string: liveImageMessage[Int(index)].imageUrl!)
        return MWPhoto(url: url)
    }

}


extension RoomsDialogVC: UIViewControllerTransitioningDelegate, popUpMessageProtocol {
    
    
    func popUpImage(_ imageView:UIImageView, message:Message) {
        selectedImageView = imageView
        
        print("total img cnt: \(liveImageMessage.count)")
        
        let imagePresenter = ImagePresenterViewController()

        
        if let currentIndex = liveImageMessage.index(of: message) {
            print("message index: " + String(currentIndex))
            imagePresenter.startImageIndex = currentIndex
        } else {
            return
        }
        
        imagePresenter.liveImageMessage = liveImageMessage
        
        let nc = UINavigationController(rootViewController: imagePresenter)
        nc.isNavigationBarHidden = true
        nc.transitioningDelegate = self
        present(nc, animated: true, completion:nil)
    }
    
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
                             source: UIViewController) ->
        UIViewControllerAnimatedTransitioning? {
            
            transition.originFrame = selectedImageView!.superview!.convert(selectedImageView!.frame, to: nil)
            transition.presenting = true
            
            return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.presenting = false
        return transition
    }
    
    func popUpSharedRoom(_ message: Message) {
        print("share room tapped")
        let hud = JGProgressHUD(style: .extraLight)
        hud?.textLabel.text = "Loading"
        hud?.show(in: self.navigationController?.view, animated: true)
        SocketIOManager.sharedInstance.getRoomInfo(message.sharedRoom!, refresh: false) { (room, error) in
            if room != nil {
                hud?.dismiss(animated: true)
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "RoomDetailTableVC") as! RoomDetailTableVC
                vc.room = room
                vc.viewFromPopUp = true
                let navVC = UINavigationController(rootViewController: vc)
                self.present(navVC, animated: true, completion: nil)
            } else {
                hud?.indicatorView = JGProgressHUDErrorIndicatorView()
                hud?.textLabel.text = error?.description
                hud?.dismiss(afterDelay: 2, animated: true)
            }
        }
        
    }
    
    func popUpResend(_ message: Message) {
        let alert = UIAlertController(title: "Resend message?", message: nil, preferredStyle: .alert)
        let delete = UIAlertAction(title: "Send", style: .default, handler: { (UIAlertAction) in
            try! Realm().write {
                message.createdAt = Date()
            }
            SocketIOManager.sharedInstance.sendMessage(message) { (success, error) in
                //TODO: message response
                self.messageTableView.reloadData()
                if error != nil {
                    let hud = JGProgressHUD()
                    hud.show(in: self.view)
                    hud.indicatorView = JGProgressHUDErrorIndicatorView()
                    hud.textLabel.text = error?.description ?? "Message sent fail"
                    hud.dismiss(afterDelay: 2)
                }
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(delete)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
}
