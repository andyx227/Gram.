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
            return 0
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
}
