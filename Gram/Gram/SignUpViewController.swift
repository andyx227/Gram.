//
//  SignUpViewController.swift
//  Gram
//
//  Created by Andy Xue on 1/27/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit
import TextFieldEffects

class SignUpViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var textFirstName: KaedeTextField!
    @IBOutlet weak var textLastName: KaedeTextField!
    @IBOutlet weak var textEmail: KaedeTextField!
    @IBOutlet weak var textUsername: KaedeTextField!
    @IBOutlet weak var textPassword: KaedeTextField!
    @IBOutlet weak var textConfirmPassword: KaedeTextField!
    @IBOutlet weak var btnSignUp: UIButton!
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
    
    @IBAction func cancelSignUp(_ sender: Any) {  // When user presses "Cancel", go back to login screen
        var path : String = ""
        let resourcePath = Bundle.main.url(forResource: "image", withExtension: "jpg")
        
        Api.uploadProfilePhoto(path: resourcePath?.absoluteString ?? "test", username: "ghgd") { (response, error) in
            if error == nil {
                print("done")
            } else {
                print("error")
            }
        }
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
