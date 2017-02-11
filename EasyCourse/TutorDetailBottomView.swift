//
//  TutorDetailBottomView.swift
//  EasyCourse
//
//  Created by ZengJintao on 2/4/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit

class TutorDetailBottomView: UIView {

    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var messageBtn: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    func setupView() {
        let view = Bundle.main.loadNibNamed("TutorDetailBottomView", owner: self, options: nil)!.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    @IBAction func messageBtnPressed(_ sender: UIButton) {
        
    }
    
}
