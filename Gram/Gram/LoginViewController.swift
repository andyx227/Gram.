//
//  LoginViewController.swift
//  Gram
//
//  Created by Andy Xue on 1/26/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit
import TextFieldEffects
import FirebaseAuth
import GoogleSignIn

class LoginViewController: UIViewController, UITextFieldDelegate, GIDSignInUIDelegate {
    @IBOutlet weak var labelAppName: UILabel!  // "Gram."
    @IBOutlet weak var textUsername: KaedeTextField!
    @IBOutlet weak var textPassword: KaedeTextField!
    @IBOutlet weak var googleLoginButton: UIButton!
    var userEmail = ""

    override func viewWillAppear(_ animated: Bool) {
        GIDSignIn.sharedInstance()?.signInSilently()
        changeStatusBarColor(forView: self)
        let _ = setBackgroundImage("background_login")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fadeInAnimation(labelAppName, duration: 2.2)
        hideKeyboard()  // Make sure user can hide keyboard when screen is tapped

        // Google sign in
        GIDSignIn.sharedInstance()?.signInSilently()
        GIDSignIn.sharedInstance().uiDelegate = self
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

    @IBAction func loginWithGoogle(_ sender: Any) {
        // In viewDidLoad(), user should have been signed-in silently. If that didn't work
        // for some reason, prompt the user to sign in via Google if they wish.
        if Auth.auth().currentUser == nil {
            GIDSignIn.sharedInstance()?.signIn()
        }
        
        googleAuthentication()
    }

    private func authenticate(email: String, password: String) {
        let alert = UIAlertController(title: nil, message: "Logging in...", preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating()

        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)

        DispatchQueue.main.async {
            Auth.auth().signIn(withEmail: email, password: password) {
                user, error in

                if error == nil && user != nil {
                    print("Login successful!")
                    // move to next view controller
                    self.userEmail = email
                    Api.setUserWithEmail(email: email, completion: { (reponse, error) in
                        if let _ = error {
                            let errorAlert = UIAlertController.init(title: "Login Error",
                                                                    message: "An error occurred getting user info",
                                                                    preferredStyle: .alert)
                            errorAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                                               style: .default,
                                                               handler: { _ in NSLog("Login failed alert occured.")}))
                            return
                        }
                        self.dismiss(animated: true, completion: nil)
                        self.transitionToNewsfeedView()
                    })

                } else {
                    let errorAlert = UIAlertController.init(title: "Login Error",
                                                            message: "Your username or password was incorrect.",
                                                            preferredStyle: .alert)

                    errorAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                                       style: .default,
                                                       handler: { _ in NSLog("Login failed alert occured.")}))

                    DispatchQueue.main.async {
                        self.dismiss(animated: true, completion: {
                            self.present(errorAlert, animated: true, completion: nil)
                        })

                        print("FirebaseAuth failed.")
                    }
                }
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
    
    /**
     * Gets a Google authentication listener to retrieve currently logged-in user's
     * info, and checks if against our database to see if that user already exists.
     * When everything checks out, it will automatically transition to NewsfeedViewController.
     * Otherwise, authentication has failed and function will return.
     */
    private func googleAuthentication() {
        // Use if-let to prevent the create of multiple listeners!
        if let _ = AuthenticationListeners.googleAuthenticationListener {
            return
        }
        
        AuthenticationListeners.googleAuthenticationListener = Auth.auth().addStateDidChangeListener({ (auth: Auth, user: User?) in
            if let user = user {  // User has a Google account!
                self.googleLoginButton.isEnabled = false  // Prevent user from pressing button multiple times!
                self.googleLoginButton.alpha = 0.5
                /*let alert = UIAlertController(title: nil, message: "Logging in...", preferredStyle: .alert)
                 
                 let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                 loadingIndicator.hidesWhenStopped = true
                 loadingIndicator.style = UIActivityIndicatorView.Style.gray
                 loadingIndicator.startAnimating()
                 
                 alert.view.addSubview(loadingIndicator) */
                //self.present(alert, animated: true, completion: nil)
                
                Api.checkEmailExists(email: user.email!, completion: { (response, error) in
                    if let _ = error {  // Email already exists, sign user in immediately
                        Api.setUserWithEmail(email: user.email!, completion: { (response, error) in
                            if let _ = error {
                                print("Error — Api could not set up user via setUserWithEmail()")
                                self.googleLoginButton.isEnabled = true  // Re-enable Google login button
                                self.googleLoginButton.alpha = 0.75
                                Auth.auth().removeStateDidChangeListener(AuthenticationListeners.googleAuthenticationListener!)
                                AuthenticationListeners.googleAuthenticationListener = nil
                                return
                            }
                            if let _ = response {
                                Auth.auth().removeStateDidChangeListener(AuthenticationListeners.googleAuthenticationListener!)
                                AuthenticationListeners.googleAuthenticationListener = nil
                                self.googleLoginButton.isEnabled = true  // Re-enable Google login button
                                self.googleLoginButton.alpha = 0.75
                                self.transitionToNewsfeedView()
                                return
                            }
                        }) // Api.setUserWithEmail()
                        return
                    }
                    if let _ = response {  // Email doesn't exist, so bring user to PickUsernameViewController
                        self.googleLoginButton.isEnabled = true
                        self.googleLoginButton.alpha = 0.75
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let pickUsernameVC = storyboard.instantiateViewController(withIdentifier: "pickUsernameViewController") as! PickUsernameViewController
                        self.navigationController?.pushViewController(pickUsernameVC, animated: true)
                        Auth.auth().removeStateDidChangeListener(AuthenticationListeners.googleAuthenticationListener!)
                        AuthenticationListeners.googleAuthenticationListener = nil
                        return
                    }
                })  // Api.checkEmailExists()
                //self.dismiss(animated: true, completion: nil)
            } else {  // There was an error signing in using Google...
                print("Error — Google sign-in failed.")
                Auth.auth().removeStateDidChangeListener(AuthenticationListeners.googleAuthenticationListener!)
                AuthenticationListeners.googleAuthenticationListener = nil
                self.googleLoginButton.isEnabled = true
                self.googleLoginButton.alpha = 0.75
            }
        })
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

    func fadeInAnimation(_ view: UIView, duration:Float) {
        if view.alpha == 0.0 {
            UIView.animate(withDuration: TimeInterval(duration), delay: 0.2, options: .curveEaseOut, animations: {
                view.alpha = 1.0
            })
        }
    }
    
    func transitionToNewsfeedView() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = storyboard.instantiateViewController(withIdentifier: "tabBarController")
        self.navigationController?.pushViewController(tabBarController, animated: true)
    }
    
    func changeStatusBarColor(forView viewController: UIViewController?) {
        if let viewController = viewController {
            if viewController is NewsfeedViewController {
                // Change status bar color to RGB value -> 247, 245, 233
                let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
                if statusBar.responds(to:#selector(setter: UIView.backgroundColor)) {
                    statusBar.backgroundColor = UIColor(red: 247/255, green: 245/255, blue: 233/255, alpha: 1)
                }
            } else if viewController is ProfileTableViewController {
                let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
                if statusBar.responds(to:#selector(setter: UIView.backgroundColor)) {
                    statusBar.backgroundColor = UIColor.white
                }
            } else {  // Use clear background by default
                let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
                if statusBar.responds(to:#selector(setter: UIView.backgroundColor)) {
                    statusBar.backgroundColor = UIColor.clear
                }
            }
        }
    }
    
    func presentAlertPopup(withTitle title: String, withMessage message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}
