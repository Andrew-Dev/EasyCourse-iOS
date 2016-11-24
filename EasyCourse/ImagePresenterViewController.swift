//
//  ImagePresenterViewController.swift
//  ImagePresenterView
//
//  Created by Andrew Arpasi on 9/29/16.
//  Copyright © 2016 Andrew Arpasi. All rights reserved.
//

import UIKit
import RealmSwift
import ImageScrollView
import MXPagerView

class ImagePresenterViewController: UIViewController, MXPagerViewDelegate, MXPagerViewDataSource {

    private var pagerView: MXPagerView!
    private var pageLabel: UILabel = UILabel()
    private var saveBtn: UIButton = UIButton()
    
    var liveImageMessage:Results<(Message)>!
    var startImageIndex: Int = 0
    var currentIndex: Int = 0
    var singleTapDismiss: Bool = true
    
    private var uiTimer: Timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        currentIndex = startImageIndex
        self.view.isUserInteractionEnabled = true
        
        pagerView = MXPagerView(frame: self.view.frame)
        pageLabel = UILabel(frame: CGRect(x: 30, y: 30, width: view.frame.size.width - 60, height: 32))
        saveBtn = UIButton(frame: CGRect(x: view.frame.size.width - 40, y: view.frame.size.height - 40, width: 32, height: 32))
        //saveBtn.setImage(UIImage(named: "download.png")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate) , for: UIControlState.normal)
        saveBtn.imageView?.tintColor = UIColor.white
        pageLabel.text = String(currentIndex+1) + " of " + String(liveImageMessage.count)
        pageLabel.textAlignment = .center
        pageLabel.textColor = UIColor.white
        self.view.addSubview(pageLabel)
        self.view.addSubview(pagerView)
        self.view.addSubview(saveBtn)
        self.view.bringSubview(toFront: pageLabel)
        self.view.bringSubview(toFront: saveBtn)
        pageLabel.isUserInteractionEnabled = true
        saveBtn.isUserInteractionEnabled = true
        pagerView.dataSource = self
        pagerView.delegate = self
        
        let tap = UITapGestureRecognizer(target:self, action:#selector(ImagePresenterViewController.handleTap(sender:)))
        
        tap.numberOfTapsRequired = 1
        let doubleTap = UITapGestureRecognizer(target:self, action:nil)
        doubleTap.numberOfTapsRequired = 2
        tap.require(toFail: doubleTap)
        self.view.addGestureRecognizer(tap)
        self.view.addGestureRecognizer(doubleTap)

        pagerView.isUserInteractionEnabled = true
        
        for v in view.subviews {
            v.isUserInteractionEnabled = true
        }
        
        pagerView.reloadData()
        
        pagerView.showPage(at: currentIndex, animated: false)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        pagerView.frame = self.view.frame
    }
    
    func handleTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            // handling code
            if singleTapDismiss == true {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func handleTouchDown(sender: UIGestureRecognizer) {
        fadeInUI()
        uiTimer.invalidate()
        uiTimer = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(ImagePresenterViewController.fadeOutUI), userInfo: nil, repeats: false)
    }
    
    func fadeOutUI() {
        UIView.animate(withDuration: 0.5, delay: 0.5, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.pageLabel.alpha = 0.0
        }, completion: nil)
    }
    
    func fadeInUI() {
        UIView.animate(withDuration: 0.5, delay: 0.5, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.pageLabel.alpha = 1.0
            }, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //pagerView.reloadData()
        print("Current Index:" + String(currentIndex))
        //pagerView.showPage(at: currentIndex, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Pager view delegate
    
    func goToPage(index: Int) {
        pagerView.showPage(at: index, animated: false)
    }
    
    func pagerView(_ pagerView: MXPagerView, willMoveToPageAt index: Int) {
        let imageScrollView = pagerView.page(at: currentIndex)?.viewWithTag(1) as! ImageScrollView
        imageScrollView.refresh()
        pageLabel.text = String(format: "%li of %li", index+1, liveImageMessage.count)
    }
    
    func pagerView(_ pagerView: MXPagerView, didMoveToPageAt index: Int) {
        currentIndex = index
    }
    
    // MARK: - Pager view data source
    
    public func numberOfPages(in pagerView: MXPagerView) -> Int {
        return liveImageMessage.count
    }
    
    func pagerView(_ pagerView: MXPagerView, viewForPageAt index: Int) -> UIView? {
        
        let imageScrollView: ImageScrollView! = ImageScrollView()
        
        var image = UIImage(color: .black, size: CGSize(width: 800, height: 600))
        
        let result = liveImageMessage[index]
        /*if result.imageData != nil {
            image = UIImage(data: result.imageData!)!
        } else {
            asynchronouslyLoadImageIntoView(imageScrollView: imageScrollView, imageUrl: result.imageUrl!)
        }*/
        asynchronouslyLoadImageIntoView(imageScrollView: imageScrollView, imageUrl: result.imageUrl!)
        
        //var image = pvImages[index]
        imageScrollView.isUserInteractionEnabled = true
        imageScrollView.tag = 1
        imageScrollView.display(image: image!)
        
        return imageScrollView
    }

    func asynchronouslyLoadImageIntoView(imageScrollView: ImageScrollView, imageUrl: String) {
        ServerHelper.sharedInstance.getNetworkImage(imageUrl, completion: { (image, error) in
            if image != nil {
                imageScrollView.display(image: image!)
            } else {
                //TODO: deal with no picture
            }
            
        })
    
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

public extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
