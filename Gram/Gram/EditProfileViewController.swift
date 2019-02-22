//
//  EditProfileViewController.swift
//  Gram
//
//  Created by Andy Xue on 2/21/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit
import TextFieldEffects

class EditProfileViewController: UIViewController {
    @IBOutlet weak var textFirstName: HoshiTextField!
    @IBOutlet weak var textLastName: HoshiTextField!
    @IBOutlet weak var textUsername: HoshiTextField!
    @IBOutlet weak var textBio: HoshiTextField!
    @IBOutlet weak var profilePhoto: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboard()
        
        textFirstName.text = user?.firstName
        textLastName.text = user?.lastName
        textUsername.text = user?.username
        
        // TODO: Retreive user bio/summary from Api.user object
        //textBio.text = "My bio"
        
        // TODO: Retrieve user profile photo through Api.user object
        // Set profile photo to be round
        let firstLetterOfFirstName = String(user!.firstName.first!)
        profilePhoto.image = UIImage(named: firstLetterOfFirstName)
        profilePhoto.layer.cornerRadius = profilePhoto.frame.height / 2
        profilePhoto.clipsToBounds = true
    }
    @IBAction func btnBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnDone(_ sender: Any) {
        // TODO: Save edited data to Firebase
        print("Warning — 'Done' button in EditProfileViewController not yet implemented.")
    }
    
    @IBAction func btnChangePhoto(_ sender: Any) {
        // TODO: Implement logic for choosing profile photo
        print("Warning — 'Change Photo' button in EditProfileViewController not yet implemented.")
    }
}
