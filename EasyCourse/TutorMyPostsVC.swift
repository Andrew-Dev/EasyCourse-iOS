//
//  TutorMyStudentVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 2/12/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class TutorMyPostsVC: UIViewController, IndicatorInfoProvider {

    @IBOutlet weak var mainTableView: UITableView!
    
    var tutorArray:[Tutor] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainTableView.delegate = self
        mainTableView.dataSource = self
        
        SocketIOManager.sharedInstance.getTutors(20, skip: 0, postedByUserOnly: true) { (tutors, error) in
            if error != nil {
                
            }
            self.tutorArray = tutors
            self.mainTableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "My Posts")
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoMyTutorDetail" {
            if let indexPath = mainTableView.indexPathForSelectedRow {
                let vc = segue.destination as! TutorDetailVC
                vc.tutor = tutorArray[indexPath.row]
            }
        }
    }


}

extension TutorMyPostsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tutorArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TutorMyPostsTVCell", for: indexPath) as! TutorMyPostsTVCell
        cell.configureCell(tutor: tutorArray[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "gotoMyTutorDetail", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
