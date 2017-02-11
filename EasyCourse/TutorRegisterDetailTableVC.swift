//
//  TutorRegisterDetailTableVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 1/30/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit
import JGProgressHUD

class TutorRegisterDetailTableVC: UITableViewController, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var gradeTextField: UITextField!
    
    @IBOutlet weak var descriptionTextView: UITextView!
    
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var registerBtnWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var priceTextField: UITextField!
    
    var placeholderLabel = UILabel()
    
    var course:Course?
    let gradeArray = ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-"]
    var choosedGrade:String?
    let priceArray = [5,10,15,25,30,35,40]
    var choosedPrice:Int?
    var tutorDescription: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        priceTextField.delegate = self
        gradeTextField.delegate = self
        descriptionTextView.delegate = self
        navigationItem.title = course?.coursename ?? "Tutor"
        
//        placeholderLabel = UILabel()
        placeholderLabel.text = "Why you can"
        placeholderLabel.font = UIFont.systemFont(ofSize: descriptionTextView.font!.pointSize)
        placeholderLabel.sizeToFit()
        descriptionTextView.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x: 0, y:0)
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.isHidden = !descriptionTextView.text.isEmpty
        
        descriptionTextView.textContainerInset = .zero
        descriptionTextView.textContainer.lineFragmentPadding = 0
        
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.backgroundColor = Design.color.lighterGreenMountainMead()
        registerButton.layer.cornerRadius = registerButton.frame.height/2
        registerButton.layer.masksToBounds = true
        registerBtnWidthConstraint.constant = UIScreen.main.bounds.width*0.6
        registerButton.addTarget(self, action: #selector(self.registerBtnPressed), for: .touchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func gradeTextFieldBeginEditing(_ sender: UITextField) {
        let gradePicker = UIPickerView()
        gradePicker.tag = 0
        gradePicker.dataSource = self
        gradePicker.delegate = self
        
        sender.inputView = gradePicker
        setupPickerInputAccView(sender: sender)
    }
    
    @IBAction func priceTextFieldBeginEditing(_ sender: UITextField) {
        let pricePicker = UIPickerView()
        pricePicker.tag = 1
        pricePicker.dataSource = self
        pricePicker.delegate = self
        
        sender.inputView = pricePicker
        setupPickerInputAccView(sender: sender)
    }
    
    func setupPickerInputAccView(sender:UITextField) {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 30))
        let doneBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 18))
        let attrTitle = NSAttributedString(string: "Done", attributes: [NSFontAttributeName:UIFont.boldSystemFont(ofSize: 17), NSForegroundColorAttributeName:self.view.tintColor])
        doneBtn.setAttributedTitle(attrTitle, for: .normal)
        doneBtn.addTarget(self, action: #selector(self.inputAccPressed), for: UIControlEvents.touchUpInside)
        view.addSubview(doneBtn)
        
        let alignRight = NSLayoutConstraint(item: doneBtn, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: -8)
        let alignCenter = NSLayoutConstraint(item: doneBtn, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([alignRight, alignCenter])
        
        doneBtn.translatesAutoresizingMaskIntoConstraints = false
        
        sender.inputAccessoryView = view
    }
    
    
    func inputAccPressed() {
        self.view.endEditing(true)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == gradeTextField || textField == priceTextField {
            return false
        } else {
            return true
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        tutorDescription = textView.text
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        self.view.endEditing(true)
    }
    
    func registerBtnPressed() {
        let hud = JGProgressHUD()
        hud.show(in: self.view)
        SocketIOManager.sharedInstance.registerTutor(course!.id!, grade: choosedGrade!, price: choosedPrice!, description: tutorDescription!) { (tutor, error) in
            if error != nil {
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = error?.description ?? "Error"
                hud.tapOutsideBlock = { (hu) in hud.dismiss() }
                hud.tapOnHUDViewBlock = { (hu) in hud.dismiss() }
            } else {
                self.dismiss(animated: true, completion: nil)
                hud.dismiss()
            }
        }
    }
    
    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 0
//    }

    
}

extension TutorRegisterDetailTableVC:UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 0 {
            return gradeArray.count
        } else if pickerView.tag == 1 {
            return priceArray.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            return gradeArray[row]
        } else if pickerView.tag == 1 {
            return "$\(priceArray[row])/h"
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 0 {
            choosedGrade = gradeArray[row]
            gradeTextField.text = gradeArray[row]
        } else if pickerView.tag == 1 {
            choosedPrice = priceArray[row]
            priceTextField.text = "$\(priceArray[row])/h"
        }
    }
    
}
