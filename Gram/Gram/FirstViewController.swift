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
    var userEmail:String?
    @IBOutlet weak var nameLabel: UILabel!
    
    override func viewDidLoad() {
        guard let userEmail = userEmail else {
            print("Can't unwrap")
            return
        }
        print("email: ", userEmail)
        
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: userEmail)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    guard let qs = querySnapshot else {
                        return
                    }
                    let document = qs.documents[0]
                    var docData = document.data().mapValues { String.init(describing: $0)}
                    user = Api.profileInfo.init(firstName: docData["firstName"] ?? "", lastName: docData["firstName"] ?? "", username: docData["firstName"] ?? "", email: docData["email"] ?? "", userID: document.documentID)
                    self.nameLabel?.text = user?.firstName
                    self.fadeInAnimation(self.nameLabel, duration:1.5)
                }
               super.viewDidLoad()
        }
    }
}


