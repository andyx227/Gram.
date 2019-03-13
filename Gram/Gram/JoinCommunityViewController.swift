//
//  ChooseCommunityViewController.swift
//  Gram
//
//  Created by Andy Xue on 3/12/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit

class JoinCommunityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var communitiesJoinedTableView: UITableView!
    @IBOutlet weak var viewNoCommunities: UILabel!
    
    @IBAction func addCommunity(_ sender: Any) {
        let alert = UIAlertController(title: "Join a Community", message: "Enter the name of the community you wish to join!", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "e.g. beach"
        }
        
        alert.addAction(UIAlertAction(title: "Join", style: .default, handler: { [weak alert] (_) in
            let textField = alert!.textFields![0] // Force unwrapping because we know it exists.
            if var community = textField.text {
                if !community.isEmpty {
                    if community.first! == "#" { community.removeFirst() }  // Remove hashtag symbol
                    community = community.lowercased()  // No capital letters!
                    
                    if ProfileDataCache.CommunitiesJoined!.contains(community) {  // Do not allow joining of same community
                        let errorAlert = UIAlertController(title: "Already Joined", message: "You've already joined the community \"\(community)\".", preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        self.present(errorAlert, animated: true, completion: nil)
                    } else {
                        ProfileDataCache.CommunitiesJoined!.append(community)  // Update array in cache
                        self.communitiesJoinedTableView.insertRows(at: [IndexPath(row: ProfileDataCache.CommunitiesJoined!.count - 1, section: 0)], with: .automatic)
                    }
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeStatusBarColor(forView: self)
        
        communitiesJoinedTableView.delegate = self
        communitiesJoinedTableView.dataSource = self
        
        ProfileDataCache.CommunitiesJoined = ["flowers", "beach", "nature"]
        ProfileDataCache.CommunitiesJoined!.sort()

        if ProfileDataCache.CommunitiesJoined!.isEmpty {
            communitiesJoinedTableView.isHidden = true
            viewNoCommunities.isHidden = false
        } else {
            communitiesJoinedTableView.isHidden = false
            viewNoCommunities.isHidden = true
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ProfileDataCache.CommunitiesJoined!.isEmpty {
            return 0
        } else {
            return ProfileDataCache.CommunitiesJoined!.count
        }
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "communityCell", for: indexPath) as UITableViewCell

        cell.textLabel!.text = "#" + ProfileDataCache.CommunitiesJoined![indexPath.row]
        return cell
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            ProfileDataCache.CommunitiesJoined?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
}
