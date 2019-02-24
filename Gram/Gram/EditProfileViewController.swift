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
    var currentlySelectedTextField: UITextField?
    var profileTableViewDelegate: ProfileTableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboard()
        
        textFirstName.text = user?.firstName
        textLastName.text = user?.lastName
        textUsername.text = user?.username
        textBio.text = user?.summary
        
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
        guard let firstName = textFirstName.text else { return }
        guard let lastName = textLastName.text else { return }
        guard let username = textUsername.text else { return }
        guard let bio = textBio.text else { return }
        
        if firstName.isEmpty || lastName.isEmpty || username.isEmpty {
            self.presentAlertPopup(withTitle: "Empty Fields!", withMessage: "First Name, Last Name, and Username fields cannot be blank.")
            return
        }
        
        // Update user with newly updated fields
        user?.firstName = firstName
        user?.lastName = lastName
        user?.username = username
        user?.summary = bio
        
        Api.updateUser { (response, error) in
            if let _ = error {
                self.presentAlertPopup(withTitle: "Something went wrong!",
                                       withMessage: "We could not update your profile at this time. Please try again later.")
            }
            if let _ = response {
                self.profileTableViewDelegate?.profile = [user!]
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func btnChangePhoto(_ sender: Any) {
        // TODO: Implement logic for choosing profile photo
        print("Warning — 'Change Photo' button in EditProfileViewController not yet implemented.")
    }
}

