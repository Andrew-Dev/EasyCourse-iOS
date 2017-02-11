//
//  TutorRegisterVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 1/30/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit

class TutorRegisterVC: UIViewController {

    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var courseTableView: UITableView!
    
    var courseArray:[Course] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        courseTableView.delegate = self
        courseTableView.dataSource = self

        let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.dismissVC))
        navigationItem.leftBarButtonItem = cancelBtn
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismissVC() {
        self.dismiss(animated: true, completion: nil)
    }

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoRegisterTutorDetail" {
            guard let vc = segue.destination as? TutorRegisterDetailTableVC else {
                return
            }
            vc.course = courseArray[courseTableView.indexPathForSelectedRow!.row]
        }
    }
 
    
    @IBAction func searchTextChanged(_ sender: UITextField) {
        if sender.text != nil && !sender.text!.isEmpty {
            SocketIOManager.sharedInstance.searchCourse(sender.text!, universityId: User.currentUser!.universityId!, limit: 20, skip: nil, completion: { (courseArray, error) in
                if error != nil {
                    self.courseArray = []
                } else {
                    self.courseArray = courseArray
                }
                self.courseTableView.reloadData()

            })

        }
    }
    

}

extension TutorRegisterVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return courseArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = courseArray[indexPath.row].coursename
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "gotoRegisterTutorDetail", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
