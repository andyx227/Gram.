//
//  SignUpViewController.swift
//  Gram
//
//  Created by Andy Xue on 1/27/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit
import TextFieldEffects
import FirebaseAuth

class SignUpViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var textFirstName: KaedeTextField!
    @IBOutlet weak var textLastName: KaedeTextField!
    @IBOutlet weak var textEmail: KaedeTextField!
    @IBOutlet weak var textUsername: KaedeTextField!
    @IBOutlet weak var textPassword: KaedeTextField!
    @IBOutlet weak var textConfirmPassword: KaedeTextField!
    @IBOutlet weak var btnSignUp: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        let _ = setBackgroundImage("background_signup")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboard()  // Hides keyboard when user taps on screen
        
        // Set delegate for the TextFields
        textFirstName.delegate = self
        textLastName.delegate = self
        textEmail.delegate = self
        textUsername.delegate = self
        textPassword.delegate = self
        textConfirmPassword.delegate = self
        
        self.enableSignUp()
        errorLabel.isHidden = true  // Hide error message Label
    }
    
    
    @IBAction func signUpButtonPressed(_ sender: UIButton) {
        self.disableSignUp()
        self.errorLabel.isHidden = true
        
        if let theUsername = textUsername.text {
            if theUsername != "" {
                Api.checkUserExists(username: theUsername) { (_, error) in
                    if error == nil {
                        // works, user not exists
                        if let email = self.textEmail.text, let password = self.textPassword.text {
                            if password != self.textConfirmPassword.text {
                                self.errorLabel.text = "Password mismatch — please try again."
                                self.errorLabel.isHidden = false
                                self.enableSignUp()
                                return
                            }
                            
                            if email == "" || password == "" {
                                self.errorLabel.text = "Email/password cannot be empty"
                                self.errorLabel.isHidden = false
                                self.enableSignUp()
                                return
                            }
                            
                            if password.count < 6 {
                                self.errorLabel.text = "Password must be at least 6 characters"
                                self.errorLabel.isHidden = false
                                self.enableSignUp()
                                return
                            }
                            
                            guard let firstname = self.textFirstName.text, let lastname = self.textLastName.text else {
                                self.enableSignUp()
                                return
                            }
                            if firstname == "" || lastname == "" {
                                self.errorLabel.text = "Please enter your first and last name"
                                self.errorLabel.isHidden = false
                                self.enableSignUp()
                                return
                            }
                            
                            Auth.auth().createUser(withEmail: email, password: password, completion: { (user_response, error) in
                                guard let _ = user_response else {
                                    self.errorLabel.text = "Please enter a valid email address"
                                    self.errorLabel.isHidden = false
                                    self.enableSignUp()
                                    return
                                }
                                
                                // initialize user global var
                                let profile = Api.profileInfo.init(firstName: firstname,
                                                                   lastName: lastname,
                                                                   username: theUsername,
                                                                   email: email,
                                                                   summary: "",
                                                                   userID: "",
                                                                   tags: nil,
                                                                   profilePhoto: nil)
                                user = profile
                                
                                Api.signupUser(completion: { (response, error) in
                                    if error == nil {
                                        ProfileDataCache.profilePhoto = UIImage(named: String(firstname.capitalized.first!))
                                        self.transitionToNewsfeedView()
                                    }
                                    else {
                                        self.errorLabel.text = "An internal error has occurred. Please try again."
                                        self.errorLabel.isHidden = false
                                        self.enableSignUp()
                                    }
                                })
                            })
                        }
                    }
                    else {
                        self.errorLabel.text = "The username \"\(theUsername)\" already exists. Please choose another username"
                        self.errorLabel.isHidden = false
                        self.enableSignUp()
                    }
                }
            }
            else {
                errorLabel.text = "Username cannot be empty"
                self.errorLabel.isHidden = false
                self.enableSignUp()
            }
        }
    }
    
    @IBAction func cancelSignUp(_ sender: Any) {  // When user presses "Cancel", go back to login screen
        navigationController?.popViewController(animated: true)
    }

    
    /**************** Helper Functions Below *****************/
    
    /**
     * Once user presses "Sign Up" button, call this function
     * to prevent user from tapping "Sign Up" multiple times.
     *
     * Call enableSignUp() to undo.
     */
    private func disableSignUp() {
        self.loadingIndicator.isHidden = false
        self.loadingIndicator.startAnimating()
        self.btnSignUp.isEnabled = false
        self.btnSignUp.alpha = 0.5
    }
    
    private func enableSignUp() {
        self.loadingIndicator.isHidden = true
        self.loadingIndicator.stopAnimating()
        self.btnSignUp.isEnabled = true
        self.btnSignUp.alpha = 1.0
    }
    
    private func setBackgroundImage(_ imageName: String) -> UIImageView {
        let backgroundImageView = UIImageView(frame: UIScreen.main.bounds)
        backgroundImageView.image = UIImage(named: imageName)
        backgroundImageView.contentMode =  UIView.ContentMode.scaleAspectFill
        self.view.insertSubview(backgroundImageView, at: 0)
        
        return backgroundImageView
    }
}
