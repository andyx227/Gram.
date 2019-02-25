//
//  EditProfileViewController.swift
//  Gram
//
//  Created by Andy Xue on 2/21/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit
import TextFieldEffects
import SkeletonView

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var textFirstName: HoshiTextField!
    @IBOutlet weak var textLastName: HoshiTextField!
    @IBOutlet weak var textUsername: HoshiTextField!
    @IBOutlet weak var textBio: HoshiTextField!
    @IBOutlet weak var profilePhoto: UIImageView!
    var currentlySelectedTextField: UITextField?
    var profileTableViewDelegate: ProfileTableViewController?
    
    override func viewWillAppear(_ animated: Bool) {
        if profilePhoto.isSkeletonActive {
            if let photo = ProfileDataCache.profilePhoto {
                profilePhoto.image = photo
            } else {
                let firstLetterOfFirstName = String(user!.firstName.first!)
                profilePhoto.image = UIImage(named: firstLetterOfFirstName)
            }
            
            profilePhoto.hideSkeleton()
            profilePhoto.stopSkeletonAnimation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboard()
        
        textFirstName.text = user?.firstName
        textLastName.text = user?.lastName
        textUsername.text = user?.username
        textBio.text = user?.summary
        
        // Set profile photo to be round
        if let photo = ProfileDataCache.profilePhoto {
            profilePhoto.image = photo
        } else {
            let firstLetterOfFirstName = String(user!.firstName.first!)
            profilePhoto.image = UIImage(named: firstLetterOfFirstName)
        }
        
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
        user?.firstName = firstName.capitalizingFirstLetter()
        user?.lastName = lastName.capitalizingFirstLetter()
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
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self;
            myPickerController.sourceType = .photoLibrary
            present(myPickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imgURL = (info[UIImagePickerController.InfoKey.imageURL] as? URL) {
            print("img url: ", imgURL)
            Api.uploadProfilePhoto(path: imgURL) { (response, error) in
                if let _ = error {
                    self.presentAlertPopup(withTitle: "An error has occurred",
                                           withMessage: "Could not successfully update your profile photo. Please try again.")
                    return
                }
            }
           
            ProfileDataCache.profilePhoto = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            ProfileDataCache.clean = false  // Mark cache as dirty since we just updated profile photo
            profilePhoto.showAnimatedGradientSkeleton()
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}


