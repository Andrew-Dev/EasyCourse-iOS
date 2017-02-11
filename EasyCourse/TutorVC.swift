//
//  TutorVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 1/30/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit

class TutorVC: UIViewController {

    var tutorArray:[Tutor] = []
    
    @IBOutlet weak var tutorTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tutorTableView.delegate = self
        tutorTableView.dataSource = self
        tutorTableView.tableFooterView = UIView()
        
        //Navigation
        let registerButton = UIBarButtonItem(title: "Register", style: UIBarButtonItemStyle.done, target: self, action: #selector(self.showRegisterTutor))
        self.navigationItem.rightBarButtonItem = registerButton
        
        SocketIOManager.sharedInstance.getTutor(20, skip: 0) { (tutors, error) in
            if error != nil {
                
            }
            self.tutorArray = tutors
            self.tutorTableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showRegisterTutor() {
        self.performSegue(withIdentifier: "showRegisterTutor", sender: self)
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoTutorDetail" {
            if let indexPath = tutorTableView.indexPathForSelectedRow {
                let vc = segue.destination as! TutorDetailVC
                vc.tutor = tutorArray[indexPath.row]
            }
        }
    }
 

}

extension TutorVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tutorArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TutorTVCell", for: indexPath) as! TutorTVCell
        cell.configureCell(tutor: tutorArray[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "gotoTutorDetail", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
