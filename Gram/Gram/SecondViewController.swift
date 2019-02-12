//
//  SecondViewController.swift
//  Gram
//
//  Created by Andy Xue on 1/24/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
        if statusBar.responds(to:#selector(setter: UIView.backgroundColor)) {
            statusBar.backgroundColor = UIColor.white
        }
    }


}

