//
//  FirstViewController.swift
//  Gram
//
//  Created by Andy Xue on 1/24/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit
import Firebase
import FirebaseCore
import FirebaseDatabase

class FirstViewController: UIViewController {
    var email:String?
    @IBOutlet weak var nameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let theEmail = email else {
            print("Can't unwrap")
            return
        }
        //nameLabel?.text = theEmail
        
        let db = Firestore.firestore()
        
        db.collection("users").whereField("email", isEqualTo: theEmail)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
//                    guard let qs = querySnapshot else {
//                        return
//                    }
//                    for document in qs.documents {
//                        guard let theName = document.get("name") else {
//                            print("can't unwrap")
//                            return
//                        }
//                        print("name is ", theName as! String)
//                    }
                }
        }

        
    }


}

