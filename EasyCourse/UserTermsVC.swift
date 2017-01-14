//
//  UserTermsVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/13/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import JGProgressHUD

class UserTermsVC: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var termsWebView: UIWebView!
    
    let hud = JGProgressHUD()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        termsWebView.delegate = self
        
        hud.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        hud.square = true
        
        hud.show(in: self.view)
        let url = URL (string: "http://www.easycourse.io/docs/terms");
        let requestObj = URLRequest(url: url!);
        termsWebView.loadRequest(requestObj)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hud.dismiss()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        hud.indicatorView = JGProgressHUDErrorIndicatorView()
        hud.textLabel.text = "Network error! Please visit www.easycourse.io/docs/terms"
        hud.tapOutsideBlock = { (hu) in
            self.hud.dismiss()
        }
        hud.tapOnHUDViewBlock = { (hu) in
            self.hud.dismiss()
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        hud.dismiss()
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
