//
//  LoginViewController.swift
//  Gram
//
//  Created by Andy Xue on 1/26/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit
import DynamicBlurView
import TextFieldEffects
import FirebaseAuth

class LoginViewController: UIViewController {
    @IBOutlet weak var labelAppName: UILabel!  // "Gram."
    @IBOutlet weak var textUsername: UITextField!
    @IBOutlet weak var textPassword: KaedeTextField!
    @IBOutlet weak var buttonLogin: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        let backgroundImageView = setBackgroundImage("login_background")
        blurBackgroundImage(backgroundImageView)  // Blur the background image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fadeInAnimation(labelAppName)
        hideKeyboard()  // Make sure user can hide keyboard when screen is tapped
        
        // Listen for keyboard events
        NotificationCenter.default.addObserver(self, selector: #selector(shiftScreenUpForKeyboard(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shiftScreenUpForKeyboard(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shiftScreenUpForKeyboard(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    deinit {
        // Stop listening for keyboard hide/show events
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    

    @IBAction func loginPress(_ sender: Any) {
        
        guard let password = textPassword.text else {
            return
        }
        guard let email = textUsername.text else {
            return
        }
        authenticate(email: email, password: password)
    }
    private func authenticate(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) {
            user, error in
            if error == nil && user != nil {
                print("Login successful!")
            } else {
                let errorAlert = UIAlertController.init(title: "Login Error",
                                                        message: "Your username or password was incorrect.",
                                                        preferredStyle: .alert)
                
                errorAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                                   style: .default,
                                                   handler: { _ in
                                                    NSLog("Login failed alert occured.")
                }
                    )
                )
                self.present(errorAlert, animated: true, completion: nil)
                print("FirebaseAuth failed.")
            }
        }
    }
    
        /**************** Helper Functions Below *****************/
    private func setBackgroundImage(_ imageName: String) -> UIImageView {
        let backgroundImageView = UIImageView(frame: UIScreen.main.bounds)
        backgroundImageView.image = UIImage(named: imageName)
        backgroundImageView.contentMode =  UIView.ContentMode.scaleAspectFill
        self.view.insertSubview(backgroundImageView, at: 0)
        
        return backgroundImageView
    }
    
    private func blurBackgroundImage(_ backgroundImage: UIImageView) {
        let blurView = DynamicBlurView(frame: backgroundImage.bounds)
        blurView.blurRadius = 7
        backgroundImage.addSubview(blurView)
    }
    
    private func fadeInAnimation(_ view: UIView) {
        if view.alpha == 0.0 {
            UIView.animate(withDuration: 2.2, delay: 0.2, options: .curveEaseOut, animations: {
                view.alpha = 1.0
            })
        }
    }
    
    @objc private func shiftScreenUpForKeyboard(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else {return}
        
        if notification.name == UIResponder.keyboardWillShowNotification ||
            notification.name == UIResponder.keyboardWillChangeFrameNotification {
            // Shift the screen up by the height of the keyboard
            view.frame.origin.y = -keyboardRect.height
        } else {
            // Keyboard is dismissed so return screen back to original height
            view.frame.origin.y = 0
        }
    }
}

extension UIViewController {
    func hideKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {  // Dismisses the keyboard
        view.endEditing(true)
    }
}
