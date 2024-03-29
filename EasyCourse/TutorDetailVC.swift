//
//  TutorDetailVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 1/30/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class TutorDetailVC: UIViewController {

    @IBOutlet weak var tutorTableView: UITableView!
    
    var tutor:Tutor?
    var tutorUser:User?
    var pendingStudents = [TutorStudent]()
    var currentStudents = [TutorStudent]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tutorTableView.delegate = self
        tutorTableView.dataSource = self
        tutorTableView.estimatedRowHeight = 64
        tutorTableView.rowHeight = UITableViewAutomaticDimension
        tutorTableView.tableFooterView = UIView()
        
        if tutor != nil {
            SocketIOManager.sharedInstance.getUserInfo(tutor!.tutorId, loadType: .cacheElseNetwork, completion: { (user, error) in
                self.tutorUser = user
            })
        }
        
        if tutor!.tutorId == User.currentUser!.id {
            let editBtn = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(self.editBtnPressed))
            navigationItem.rightBarButtonItem = editBtn
            SocketIOManager.sharedInstance.getTutorStudents(tutor!.tutorId, limit: 10, skip: 0, pending: true, completion: {(tutorStudents, error) in
                self.pendingStudents = tutorStudents
                print(tutorStudents)
            })
        } else {
            setupBottomView()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupBottomView() {
        let bottomView = TutorDetailBottomView()
        view.addSubview(bottomView)
        bottomView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        bottomView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0).isActive = true
        bottomView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.priceLabel.text = "$" + String(tutor!.price ?? 0 ) + "/h"
        bottomView.messageBtn.addTarget(self, action: #selector(self.messageBtnPressed), for: .touchUpInside)
        bottomView.signUpBtn.addTarget(self, action: #selector(self.signUpBtnPressed), for: .touchUpInside)

    }
    
    func editBtnPressed() {
        let vc = UIStoryboard(name: "Resource", bundle: nil).instantiateViewController(withIdentifier: "tutorEditDetails") as! TutorRegisterDetailTableVC
        let navi = UINavigationController(rootViewController: vc)
        vc.tutor = tutor
        present(navi, animated: true, completion: nil)
    }
    
    func signUpBtnPressed() {
        if tutorUser != nil {
            SocketIOManager.sharedInstance.applyTutor(tutor!.tutorId, completion: {(success,error) in
                print("success: " + String(success))
            })
        }
    }
    
    func messageBtnPressed() {
        if tutorUser != nil {
            let vc = UIStoryboard(name: "Room", bundle: nil).instantiateViewController(withIdentifier: "RoomsDialogVC") as! RoomsDialogVC
            let realm = try! Realm()
            if let room = realm.object(ofType: Room.self, forPrimaryKey: self.tutor?.tutorId) {
                vc.localRoomId = room.id
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                try! realm.write({
                    let room = Room()
                    room.id = self.tutor?.tutorId
                    room.isToUser = true
                    realm.add(room, update: true)
                    vc.localRoomId = room.id
                    self.navigationController?.pushViewController(vc, animated: true)
                })
            }
        } else {
            return
        }
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }
 

}

extension TutorDetailVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tutor!.tutorId == User.currentUser!.id && pendingStudents.count > 0 {
            return 3
        } else if tutor!.tutorId == User.currentUser!.id && currentStudents.count > 0 {
            return 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 && pendingStudents.count > 0 {
            return pendingStudents.count
        }
        return currentStudents.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 && pendingStudents.count > 0 {
            return "Awaiting Approval"
        } else if section != 0 {
            return "My Students"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        } else {
            return 38
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 200
        } else {
            return 64
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TutorDetailInfoTVCell", for: indexPath) as! TutorDetailInfoTVCell
            cell.configureCell(tutor: tutor!)
            return cell
        } else if indexPath.section == 1 && pendingStudents.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StudentTutorDetailTVCell", for: indexPath) as! StudentTutorDetailTVCell
            cell.configureCell(user: pendingStudents[indexPath.row].user, pending: true, accepted: false)
            return cell
        } else if currentStudents.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StudentTutorDetailTVCell", for: indexPath) as! StudentTutorDetailTVCell
            cell.configureCell(user: pendingStudents[indexPath.row].user, pending: true, accepted: false)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section > 0 {
            let cell = tableView.cellForRow(at: indexPath) as! StudentTutorDetailTVCell
            let studentUser = cell.user!
            print(studentUser)
        }
    }
    
}
