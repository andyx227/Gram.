//
//  PickUsernameViewController.swift
//  Gram
//
//  Created by Andy Xue on 2/10/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit
import TextFieldEffects
import FirebaseAuth

class PickUsernameViewController: UIViewController {
    @IBOutlet weak var username: KaedeTextField!
    @IBOutlet weak var confirmUsername: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let _ = setBackgroundImage("background_login")
        self.hideKeyboard()
        self.loadingIndicator.isHidden = true
        self.errorLabel.isHidden = true
    }
    
    
    @IBAction func confirmUsername(_ sender: Any) {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        confirmUsername.isEnabled = false
        
        if let username = username.text {
            if username == "" {
                errorLabel.text = "Please enter a username"
                self.loadingIndicator.isHidden = true
                self.loadingIndicator.stopAnimating()
                self.confirmUsername.isEnabled = true
                return
            }
            
            Api.checkUserExists(username: username) { (response, error) in
                if let _ = error {
                    self.errorLabel.text = "\"\(username)\" already exists. Please try again."
                    self.loadingIndicator.isHidden = true
                    self.loadingIndicator.stopAnimating()
                    self.confirmUsername.isEnabled = true
                    self.errorLabel.isHidden = false
                }
                if let _ = response {
                    let currentSignedInUser = Auth.auth().currentUser
                    guard let signedInUser = currentSignedInUser else {
                        print("Error — currently signed in user via social media is not found!")
                        self.navigationController?.popViewController(animated: true)
                        return
                    }
                    
                    user = self.extractUserInfo(signedInUser)  // Pass this info to the global Api.user variable
                    user?.username = username  // Last but not least, pass the username to Api.user
                    Api.signupUser(completion: { (response, error) in
                        if let _ = error {
                            print("Error — could not successfully sign up current user who is using social media sign-up!")
                            self.errorLabel.text = "An internal error has occured. Please try again."
                            self.loadingIndicator.isHidden = true
                            self.loadingIndicator.stopAnimating()
                            self.confirmUsername.isEnabled = true
                            self.errorLabel.isHidden = false
                        }
                        if let _ = response {  // Sign up successful! Segue to Newsfeed ViewController
                            self.transitionToNewsfeedView()
                        }
                    })
                }
            }
        }
    }
    
    /***** Helper Functions Below *****/
    private func extractUserInfo(_ user: User) -> Api.profileInfo {
        var profile: Api.profileInfo
        var userEmail: String = ""
        var firstname: String = ""
        var lastname: String = ""
        
        // Extract the first and last name of current user
        if let displayName = user.displayName {
            var fullname = [String]()  // First element is the first name, last element is the last name
            for name in displayName.components(separatedBy: " ") {
                fullname.append(name)
            }
            if let first = fullname.first { firstname = first }
            if let last = fullname.last { lastname = last }
        } else {
            print("Warning — User does not have a name!")
        }
        
        // Extract user's email
        if let email = user.email {
            userEmail = email
        } else {
            print("Warning — User does not have an email address!")
        }

        // Set up the profile for current user
        profile = Api.profileInfo.init(firstName: firstname,
                                       lastName: lastname,
                                       username: "",
                                       email: userEmail,
                                       userID: "")
        
        return profile
    }
    
    private func setBackgroundImage(_ imageName: String) -> UIImageView {
        let backgroundImageView = UIImageView(frame: UIScreen.main.bounds)
        backgroundImageView.image = UIImage(named: imageName)
        backgroundImageView.contentMode =  UIView.ContentMode.scaleAspectFill
        self.view.insertSubview(backgroundImageView, at: 0)
        
        return backgroundImageView
    }
}
