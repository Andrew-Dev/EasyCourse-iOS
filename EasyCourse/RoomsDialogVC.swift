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

protocol popUpImageProtocol : NSObjectProtocol {
    func  popUpImage(_ imageView:UIImageView, message:Message) -> Void
}

class RoomsDialogVC: UIViewController, UITableViewDelegate, UITableViewDataSource, cellTableviewProtocol {
    
    @IBOutlet weak var messageTableView: UITableView!
    
    @IBOutlet weak var inputTextView: UITextView!
    
    @IBOutlet weak var sendBtn: UIButton!
    
    @IBOutlet weak var accessoryBtn: UIButton!
    
    @IBOutlet weak var accessoryView: UIView!
    
    
    @IBOutlet weak var accImgBtn: UIButton!
    
    
    @IBOutlet weak var inputViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var inputBottomConstraint: NSLayoutConstraint!
    
    //Data
    var liveMessage:Results<(Message)>!
    var liveImageMessage:Results<(Message)>!
    var localRoom:Room!
    var msgPage = 0
    var msgOffset = 10
    
    //UI
    var placeholderLabel:UILabel!
    var goToBottomAtFirst = true
    var accessoryViewShow = false
    let transition = PopAnimator()
    var selectedImageView:UIImageView?
    var tappedUserId:String?

    //Notif
    var messageUpdateNotif: NotificationToken? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Load data
        liveMessage = localRoom.getMessage()
        liveImageMessage = localRoom.getMessageContainsImage()
        
        //UI
        let customTitleView = LDONavigationSubtitleView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        customTitleView.subtitle = "\(localRoom.memberCounts.value!) people"
        customTitleView.title = localRoom.roomname!
        self.navigationItem.titleView = customTitleView
        
        messageTableView.delegate = self
        messageTableView.dataSource = self
        messageTableView.estimatedRowHeight = 120
        messageTableView.rowHeight = UITableViewAutomaticDimension
        messageTableView.tableFooterView = UIView()
        
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
        
        inputBottomConstraint.constant = 0
        accessoryView.isHidden = true
        
        accImgBtn.layer.cornerRadius = 12
        accImgBtn.layer.borderWidth = 1
        accImgBtn.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        accImgBtn.layer.masksToBounds = true
        accImgBtn.backgroundColor = UIColor(white: 0.98, alpha: 1)
        
        //Navigation
        let detailButton = UIBarButtonItem(title: "More", style: UIBarButtonItemStyle.done, target: self, action: #selector(self.gotoDetail))
        self.navigationItem.rightBarButtonItem = detailButton
        
        //Notification
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyboardWasShown(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyboardWillDisappear(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        messageUpdateNotif = liveMessage.addNotificationBlock({ (result) in
            print("get message notif")
            self.loadMessage()
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.gobackToLastView), name: Constant.NotificationKey.RoomDelete, object: nil)
        
    }
    
    deinit {
        messageUpdateNotif?.stop()
        NotificationCenter.default.removeObserver(self)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let cnt = min((msgPage+1) * msgOffset, liveMessage.count)
        return cnt
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellCnt = min((msgPage+1) * msgOffset, liveMessage.count)
        
        let msgIndex = liveMessage.count - (cellCnt - indexPath.row)
//        print("indexpath: \(indexPath.row) || msgIndex: \(msgIndex)")
        if liveMessage[msgIndex].senderId == User.currentUser?.id {
            if liveMessage[msgIndex].imageUrl != nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MessageOutgoingImageCell", for: indexPath) as! MessageOutgoingImageCell
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
                cell.delegate = self
                cell.configureCell(liveMessage[msgIndex], lastMessage: lastMessage)
                return cell
                
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MessageIncomingTextCell", for: indexPath) as! MessageIncomingTextCell
                var lastMessage:Message?
                if msgIndex != 0 {
                    lastMessage = liveMessage[msgIndex - 1]
                }
                cell.delegate = self
                cell.configureCell(liveMessage[msgIndex], lastMessage: lastMessage)
                return cell
                
            }
            
        }
    }
    
    func scrollToBottom(_ animated: Bool) {
        if liveMessage.count > 1 {
            let cellCnt = min((msgPage+1) * msgOffset, liveMessage.count)
//            print("message count = \(liveMessage.count) || \((msgPage+1) * msgOffset)")
//            print("scroll: \(cellCnt - 1)")
//            self.messageTableView.scrollToRowAtIndexPath(IndexPath(forRow: cellCnt - 1, inSection: 0), atScrollPosition: .Bottom, animated: animated)
            
            
            
            self.messageTableView.scrollToRow(at: IndexPath(row: cellCnt - 1, section: 0), at: .bottom, animated: animated)
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
            if scrollView.contentOffset.y < 0 {
                if ((msgPage+1)*msgOffset < liveMessage.count) {
                    print("get top add page \(msgPage) -> \(msgPage+1)")
                    msgPage += 1
                    messageTableView.reloadData()
                    if (msgPage + 1) * msgOffset > liveMessage.count {
                        let row = liveMessage.count - msgPage * msgOffset
                        print("row is \(row)")
                        messageTableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .top, animated: false)

                    } else {
                        messageTableView.scrollToRow(at: IndexPath(row: msgOffset, section: 0), at: .top, animated: false)

                    }
                }
            }
            
        }
    }
    
    
    
    //MARK: - Button Action
    
    
    @IBAction func sendBtnPressed(_ sender: UIButton) {
        sendBtn.isEnabled = false
        let message = Message()
        message.initForCurrentUser(inputTextView.text, imageUrl: nil, image: nil, roomId: localRoom.id!)
        message.saveToDatabase()
        inputTextView.text = ""
        UIView.animate(withDuration: 0.2, animations: {
            self.inputViewHeightConstraint.constant = 49
            self.view.layoutIfNeeded()
        }) 
        SocketIOManager.sharedInstance.sendMessage(message)
        self.sendBtn.isEnabled = true
        
        
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
                    ServerConst.sharedInstance.uploadImage(image!, uploadType: .message, room: self.localRoom.id!, completion: { (imageUrl, progress, error) in
                        //TODO:
                        print("url: \(imageUrl) progress: \(progress) err: \(error)")
                        if imageUrl != nil {
                            let message = Message()
                            message.initForCurrentUser(nil, imageUrl: imageUrl!, image: image, roomId: self.localRoom.id!)
                            message.saveToDatabase()
                            SocketIOManager.sharedInstance.sendMessage(message)
                        }
                        
                    })
                })
                
            }
        }
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
            self.accessoryViewShow = true
            self.accessoryBtn.isEnabled = true
        }) 
    }
    
    
     // MARK: - Navigation
    func gotoDetail() {
        self.performSegue(withIdentifier: "gotoRoomDetailPage", sender: self)
    }
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoUserDetailPage" {
            let vc = segue.destination as! UserDetailTableVC
            vc.userId = tappedUserId
            
            tappedUserId = nil
            
        } else if segue.identifier == "gotoRoomDetailPage" {
            let vc = segue.destination as! RoomDetailTableVC
            vc.room = localRoom
        }
     }
 
    
    func gobackToLastView(_ notification: Notification) {
        if let deletedRoomID = notification.object as? String {
            if deletedRoomID == localRoom.id {
                self.navigationController?.popViewController(animated: true)
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
    //MARK: - Text View Delegate
    func textViewDidChange(_ textView: UITextView){
        placeholderLabel.isHidden = !textView.text.isEmpty
        sendBtn.isEnabled = !inputTextView.text.trimWhiteSpace().isEmpty
        
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        UIView.animate(withDuration: 0.2, animations: {
            self.inputViewHeightConstraint.constant = min(newSize.height, 120) + 16
            self.view.layoutIfNeeded()
            //            textView.setContentOffset(CGPointZero, animated: true)
        }) 
    }
    
    func keyboardWasShown(_ notification:Notification) {
        let dict:NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        let s:NSValue = dict.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let rect:CGRect = s.cgRectValue
        UIView.animate(withDuration: 0.2, animations: {
            self.inputBottomConstraint.constant = rect.height
            self.view.layoutIfNeeded()
        }, completion: { (finish) in
            self.accessoryView.isHidden = true
            self.accessoryViewShow = false
            //            self.pieDetailTableView.addGestureRecognizer(self.tapCancelKeyboard!)
        }) 
    }
    
    func keyboardWillDisappear(_ notification:Notification) {
        UIView.animate(withDuration: 0.2, animations: {
            self.inputBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }, completion: { (finish) in
            //            self.pieDetailTableView.removeGestureRecognizer(self.tapCancelKeyboard!)
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


extension RoomsDialogVC: UIViewControllerTransitioningDelegate, popUpImageProtocol {
    
    
    func popUpImage(_ imageView:UIImageView, message:Message) {
        let browser = MWPhotoBrowser(delegate: self)
        
        if let currentIndex = liveImageMessage.index(of: message) {
            browser?.setCurrentPhotoIndex(UInt(currentIndex))
        } else {
            return
        }
        
        //        browser.setCurrentPhotoIndex(UInt(currentIndex))
        browser?.displayActionButton = false
        browser?.enableSwipeToDismiss = false
        let nc = UINavigationController(rootViewController: browser!)

        selectedImageView = imageView
        nc.transitioningDelegate = self
        present(nc, animated: true, completion: nil)
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
}
