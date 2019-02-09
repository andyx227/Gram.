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
    var currentlySelectedTextField: UITextField?
    
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
        
        // Listen for keyboard events
        NotificationCenter.default.addObserver(self, selector: #selector(shiftScreenUpForKeyboard(notification:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shiftScreenUpForKeyboard(notification:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shiftScreenUpForKeyboard(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    deinit {
        // Stop listening for keyboard hide/show events
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "signupToTabController" {
            let barViewControllers = segue.destination as! UITabBarController
            let destinationViewController = barViewControllers.viewControllers?[0] as! FirstViewController
            destinationViewController.userEmail = user?.email
        }
    }
    
    @IBAction func signUpButtonPressed(_ sender: UIButton) {
        if let theUsername = textUsername.text {
            if theUsername != "" {
                print("username: ", theUsername)
                
                Api.checkUserExists(username: theUsername) { (_, error) in
                    if error == nil {
                        // works, user not exists
                        if let email = self.textEmail.text, let password = self.textPassword.text {
                            if password != self.textConfirmPassword.text {
                                self.errorLabel.text = "Confirm password doesn't match password"
                                return
                            }
                            
                            if email == "" || password == "" {
                                self.errorLabel.text = "Email/password cannot be empty"
                                return
                            }
                            
                            if password.count < 6 {
                                self.errorLabel.text = "Password has to be at least 6 chars"
                                return
                            }
                            
                            guard let firstname = self.textFirstName.text, let lastname = self.textLastName.text else {
                                return
                            }
                            if firstname == "" || lastname == "" {
                                self.errorLabel.text = "Please enter your first and last name"
                                return
                            }
                            
                            Auth.auth().createUser(withEmail: email, password: password, completion: { (user_response, error) in
                                guard let _ = user_response else {
                                    self.errorLabel.text = "login error"
                                    return
                                }
                                
                                // initialize user global var
                                let profile = Api.profileInfo.init(firstName: firstname, lastName: lastname, username: theUsername, email: email)
                                user = profile
                                
                                Api.signupUser(completion: { (response, error) in
                                    if error == nil {
                                        self.errorLabel.text = "Sign up success!"
                                        self.performSegue(withIdentifier: "signupToTabController", sender: self)
                                    }
                                    else {
                                        self.errorLabel.text = error
                                    }
                                })
                            })
                        }

                    }
                    else {
                        self.errorLabel.text = error
                    }
                }
            }
            
            else {
                errorLabel.text = "Username cannot be empty"
            }
            
        }
        
    }
    
    @IBAction func cancelSignUp(_ sender: Any) {  // When user presses "Cancel", go back to login screen
        navigationController?.popViewController(animated: true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentlySelectedTextField = textField
        
    }
    
    /**************** Helper Functions Below *****************/
    private func setBackgroundImage(_ imageName: String) -> UIImageView {
        let backgroundImageView = UIImageView(frame: UIScreen.main.bounds)
        backgroundImageView.image = UIImage(named: imageName)
        backgroundImageView.contentMode =  UIView.ContentMode.scaleAspectFill
        self.view.insertSubview(backgroundImageView, at: 0)
        
        return backgroundImageView
    }
    
    @objc private func shiftScreenUpForKeyboard(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {return}
        
        if  notification.name == UIResponder.keyboardWillShowNotification ||
            notification.name == UIResponder.keyboardWillChangeFrameNotification {

            if let currentlySelectedTextField = currentlySelectedTextField {
                if  currentlySelectedTextField == textUsername ||
                    currentlySelectedTextField == textPassword ||
                    currentlySelectedTextField == textConfirmPassword {
                    // Shift the screen up by the height of the keyboard
                    view.frame.origin.y = -keyboardRect.height
                }
            }
        } else {
            // Keyboard is dismissed so return screen back to original height
            view.frame.origin.y = 0
        }
    }
}
