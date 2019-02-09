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

struct PhotoCard {
    var profilePhoto: UIImage
    var username: String
    var date: String
    var photo: UIImage
}

class ProfileTableViewController: UITableViewController {
    var profile = [ProfileInfo]()
    var photos = [PhotoCard]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        profile = [ProfileInfo.init(profilePhoto: UIImage(named: "profile_photo")!, fullname: "Andy Xue", username: "@prestococo", bio: "I mountain climb in my spare time!")]
        photos = [PhotoCard.init(profilePhoto: UIImage(named: "profile_photo")!, username: "prestococo", date: "February 27, 1996", photo: UIImage(named:"mountain")!)]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profile.count + photos.count
    }
    

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "profileInfoCell", for: indexPath) as! ProfileInfoCell

            // Set "Edit Profile" button style
            cell.btnEditProfile.layer.cornerRadius = 10
            cell.btnEditProfile.layer.borderColor = UIColor.black.cgColor
            // Set profile photo to be round
            cell.profilePhoto.image = profile[indexPath.row].profilePhoto
            cell.profilePhoto.layer.cornerRadius = cell.profilePhoto.frame.height / 2
            cell.profilePhoto.clipsToBounds = true
            // Set other profile information in its respective Labels
            cell.fullname.text = profile[indexPath.row].fullname
            cell.username.text = profile[indexPath.row].username
            if let bio = profile[indexPath.row].bio {
                cell.bio.text = bio
            }

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "photoCardCell", for: indexPath) as! PhotoCardCell
            
            // Set profile photo to be round
            cell.profilePhoto.image = photos[indexPath.row - 1].profilePhoto
            cell.profilePhoto.layer.cornerRadius = cell.profilePhoto.frame.height / 2
            cell.profilePhoto.clipsToBounds = true
            
            cell.username.text = photos[indexPath.row - 1].username
            cell.date.text = photos[indexPath.row - 1].date
            
            // Scale photos before displaying them in UIImageView
            let photo = photos[indexPath.row - 1].photo
            let ratio = photo.getCropRatio()
            
            //let width = cell.photo.frame.width

            cell.photoHeightConstraint.constant = UIScreen.main.bounds.width / ratio
            cell.photo.image = photos[indexPath.row - 1].photo
            
            return cell
            
        }
    }
}

extension UIImage {
    func getCropRatio() -> CGFloat {
        let width = self.size.width
        let height = self.size.height
        let ratio: CGFloat
        
        if width >= height {
            ratio = CGFloat(width / height)
        } else {
             ratio = CGFloat(height / width)
        }
        
        return ratio
    }
}
