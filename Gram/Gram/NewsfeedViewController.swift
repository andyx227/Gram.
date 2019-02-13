//
//  NewsfeedViewController.swift
//  Gram
//
//  Created by Andy Xue on 2/9/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit

class NewsfeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UITabBarControllerDelegate {
   
    @IBOutlet weak var searchBarPeople: UISearchBar!
    @IBOutlet weak var newsfeedTableView: UITableView!
    @IBOutlet weak var searchPeopleTableView: UITableView!
    var people = [Api.userInfo]()
    var photos = [PhotoCard]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboard()
        newsfeedTableView.delegate = self
        newsfeedTableView.dataSource = self
        searchPeopleTableView.delegate = self
        searchPeopleTableView.dataSource = self
        searchBarPeople.delegate = self
        searchBarPeople.autocapitalizationType = .none
        self.tabBarController?.delegate = self
        self.tabBarController?.selectedIndex = 0
        
        photos = [PhotoCard.init(profilePhoto: UIImage(named: "A")!,
                                 username: user!.username,
                                 date: "December 1, 2018",
                                 photo: UIImage(named:"mountain")!,
                                 caption: "How do I get down from here?! #mountainclimbing"),
                  
                  PhotoCard.init(profilePhoto: UIImage(named: "A")!,
                                 username: user!.username,
                                 date: "January 12, 2019",
                                 photo: UIImage(named: "tower")!,
                                 caption: "Paris is the best! #travel @mostrowski :)")
        ]
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController is NewsfeedViewController {
            let newsfeedVC = viewController as! NewsfeedViewController
            changeStatusBarColor(forView: newsfeedVC)
            newsfeedVC.searchBarPeople.text = ""
            newsfeedVC.searchPeopleTableView.isHidden = true
            newsfeedVC.newsfeedTableView.isHidden = false
            
        } else if viewController is ProfileTableViewController {
            let profileVC = viewController as! ProfileTableViewController
            changeStatusBarColor(forView: profileVC)
            profileVC.profile = [user!]
            profileVC.firstTimeLoadingView = true
            profileVC.tableView.reloadData()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {  // If user is not searching anything...
            self.searchPeopleTableView.isHidden = true  // Hide People Search TableView
            self.newsfeedTableView.isHidden = false  // Show Newsfeed
            return
        }
        
        Api.searchUsers(name: searchText) { (peopleList, error) in
            if let _ = error {
                self.searchPeopleTableView.isHidden = true  // Hide People Search TableView
                self.newsfeedTableView.isHidden = false  // Show Newsfeed
                return
            }
            
            if let peopleList = peopleList {
                self.people = peopleList
                self.newsfeedTableView.isHidden = true  // Hide newsfeed TableView in order to show the People Search TableView
                self.searchPeopleTableView.isHidden = false
                self.searchPeopleTableView.reloadData()
            } else {
                self.searchPeopleTableView.isHidden = true  // Hide People Search TableView
                self.newsfeedTableView.isHidden = false  // Show Newsfeed
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        self.searchPeopleTableView.isHidden = true
        self.newsfeedTableView.isHidden = false
        self.searchBarPeople.resignFirstResponder()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.searchPeopleTableView {
            if people.count == 0 {
                self.searchPeopleTableView.isHidden = true
                self.newsfeedTableView.isHidden = false
            }
            return people.count
        } else if tableView == self.newsfeedTableView {
            self.searchPeopleTableView.isHidden = true
            self.newsfeedTableView.isHidden = false
            return photos.count
        } else {  // Should NEVER reach this case!
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.searchPeopleTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "peopleCell", for: indexPath) as! PeopleCell
            cell.fullname.text = people[indexPath.row].firstName + " " + people[indexPath.row].lastName
            cell.username.text = "@" + people[indexPath.row].userName
            
            if people[indexPath.row].following {
                cell.followingIcon.isHidden = false  // Show the icon since user is following searched user
            } else {
                cell.followingIcon.isHidden = true  // Otherwise, hide the following icon
            }
            
            return cell
        } else if tableView == self.newsfeedTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "photoCardCell", for: indexPath) as! PhotoCardCell
            // TODO: Temporarily using the method below to retrieve username
            // Remove later!
            let username = user!.username
            
            // Set profile photo to be round
            let firstLetterOfFirstName = String(user!.firstName.first!)
            cell.profilePhoto.image = UIImage(named: firstLetterOfFirstName)
            cell.profilePhoto.layer.cornerRadius = cell.profilePhoto.frame.height / 2
            cell.profilePhoto.clipsToBounds = true
            
            cell.username.text = username
            cell.date.text = photos[indexPath.row].date
            
            // Scale photos before displaying them in UIImageView
            let photo = photos[indexPath.row].photo
            let ratio = photo.getCropRatio()
            cell.photoHeightConstraint.constant = UIScreen.main.bounds.width / ratio
            cell.photo.image = photos[indexPath.row].photo
            
            // Format caption before displaying
            if let caption = photos[indexPath.row].caption {
                cell.caption.attributedText = self.formatCaption(caption, user: username)
            }
            
            return cell
        } else {  // This case should never be reached!
            let cell = tableView.dequeueReusableCell(withIdentifier: "ShouldNeverDequeueCellHere!")
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = [Api.profileInfo.init(firstName: people[indexPath.row].firstName,
                                                 lastName: people[indexPath.row].lastName,
                                                 username: people[indexPath.row].userName,
                                                 email: "",
                                                 userID: people[indexPath.row].userID)
        ]

        let profileTab = self.tabBarController?.viewControllers![2] as! ProfileTableViewController
        profileTab.profile = selectedUser
        profileTab.following = people[indexPath.row].following
        profileTab.firstTimeLoadingView = true
        profileTab.tableView.reloadData()
        self.tabBarController?.selectedViewController = profileTab
        changeStatusBarColor(forView: profileTab)
        tableView.deselectRow(at: indexPath, animated: true)  // Deselect the row
    }
    
    /****** Helper Functions *****/
    private func formatCaption(_ caption: String, user username: String) -> NSAttributedString {
        let usernameAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Bold", size: 13)!
        ]
        let captionAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Light", size: 13)!
        ]
        let hashtagAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: UIColor(red: 51/255, green: 153/255, blue: 255/255, alpha: 1),
            NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Light", size: 13)!
        ]
        
        // Set attribute to username (font will be HelveticaNeue-Bold)
        let attributedUsername = NSAttributedString(string: username, attributes: usernameAttributes)
        
        // Set attribute to actual caption
        let attributedCaptionString = NSMutableAttributedString()
        attributedCaptionString.append(attributedUsername)  // First, include the username in the caption
        attributedCaptionString.append(NSAttributedString(string: " "))
        
        // Tokenize photo caption, delimited by whitespace
        let tokenized_caption = caption.components(separatedBy: " ")
        var attributedToken: NSAttributedString
        for token in tokenized_caption {
            if token.contains("#") {  // Hashtags should be in blue
                attributedToken = NSAttributedString(string: token, attributes: hashtagAttributes)
            } else if token.contains("@") {  // Tagged username should have bolded text
                attributedToken = NSAttributedString(string: token, attributes: usernameAttributes)
            } else {
                attributedToken = NSAttributedString(string: token, attributes: captionAttributes)
            }
            attributedCaptionString.append(attributedToken)
            attributedCaptionString.append(NSAttributedString(string: " "))
        }
        
        return attributedCaptionString
    }
}
