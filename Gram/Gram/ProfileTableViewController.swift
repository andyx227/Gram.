//
//  ProfileTableViewController.swift
//  Gram
//
//  Created by Andy Xue on 2/8/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit

struct ProfileInfo {
    var profilePhoto: UIImage
    var fullname: String
    var username: String
    var bio: String?
}

class ProfileTableViewController: UITableViewController {
    var profile = [ProfileInfo]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        profile = [ProfileInfo.init(profilePhoto: UIImage(named: "profile_photo")!, fullname: "Andy Xue", username: "@prestococo", bio: "I mountain climb in my spare time!")]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profile.count
    }
    

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "profileInfoCell", for: indexPath) as! ProfileInfoCell

        cell.profilePhoto.image = profile[indexPath.row].profilePhoto
        cell.profilePhoto.layer.cornerRadius = cell.profilePhoto.frame.height / 2
        cell.profilePhoto.clipsToBounds = true
        cell.fullname.text = profile[indexPath.row].fullname
        cell.username.text = profile[indexPath.row].username
        if let bio = profile[indexPath.row].bio {
            cell.bio.text = bio
        }

        return cell
    }
 

}
