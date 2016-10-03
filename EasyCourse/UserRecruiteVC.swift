//
//  UserRecruiteVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/13/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import JGProgressHUD


class UserRecruiteVC: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var joinUsWebView: UIWebView!
    
    let hud = JGProgressHUD()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        joinUsWebView.delegate = self
        
        hud.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        hud.square = true
        
        if Reachability.isConnectedToNetwork() == true {
            hud.textLabel.text = "Loading"
            hud.show(in: self.view)
            let url = URL (string: "https://mtdtao.typeform.com/to/l9ZsMJ");
            let requestObj = URLRequest(url: url!);
            joinUsWebView.loadRequest(requestObj)
        } else {
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = "Network error! Please send your personal information to mtdtao@gmail.com"
            hud.show(in: self.navigationController?.view)
            hud.dismiss(afterDelay: 2, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hud.dismiss()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        hud.indicatorView = JGProgressHUDErrorIndicatorView()
        hud.textLabel.text = "Network error! Please send your personal information to mtdtao@gmail.com"
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
