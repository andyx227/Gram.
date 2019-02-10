//
//  NewsfeedViewController.swift
//  Gram
//
//  Created by Andy Xue on 2/9/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit

class NewsfeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
   
    @IBOutlet weak var searchBarPeople: UISearchBar!
    @IBOutlet weak var newsfeedTableView: UITableView!
    @IBOutlet weak var searchPeopleTableView: UITableView!
    var people = [Api.userInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dismissKeyboard()
        newsfeedTableView.delegate = self
        newsfeedTableView.dataSource = self
        searchPeopleTableView.delegate = self
        searchPeopleTableView.dataSource = self
        searchBarPeople.delegate = self
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
            cell.username.text = people[indexPath.row].userName
            return cell
        } else {
            print("newsfeed cell")
            let cell = tableView.dequeueReusableCell(withIdentifier: "photoCardCell", for: indexPath) as! PhotoCardCell
            return cell
        }
    }
}
