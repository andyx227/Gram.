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
    var caption: String?
}

class ProfileTableViewController: UITableViewController, ProfileInfoCellDelegate {
    var profile = [Api.profileInfo]()
    var photos = [PhotoCard]()
    var following: Bool = false  // Assume false always (this var only used when viewing another user's profile
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*profile = [ProfileInfo.init(profilePhoto: UIImage(named: "profile_photo")!,
                                    fullname: "Andy Xue",
                                    username: "@prestococo",
                                    bio: "I mountain climb in my spare time!")
        ]*/
        
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
    
    func didChangeFollowStatus(_ sender: ProfileInfoCell) {
        guard let tappedIndexPath = self.tableView.indexPath(for: sender) else { return }
        
        if sender.isFollowing {
            Api.followUser(followingID: sender.userID, following: true) { (response, error) in
                if let _ = error {
                    print("Issue encountered when trying to UNFOLLOW a user with id: \(sender.userID).")
                }
                if let _ = response {
                    print("Successfully UNFOLLOWED user with id: \(sender.userID).")
                }
            }
            self.following = false
        } else {
            Api.followUser(followingID: sender.userID, following: false) { (response, error) in
                if let _ = error {
                    print("Issue encountered when trying to FOLLOW a user with id: \(sender.userID).")
                }
                if let _ = response {
                    print("Successfully FOLLOWED user with id: \(sender.userID).")
                }
            }
            self.following = true
        }
        self.getNumFollowed(forUserId: sender.userID, displayInCell: sender)  // Update number of followers
        self.tableView.reloadRows(at: [tappedIndexPath], with: .none)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profile.count + photos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let firstLetterOfFirstName = String(profile.first!.firstName.first!)
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "profileInfoCell", for: indexPath) as! ProfileInfoCell

            cell.delegate = self
            // Set "Edit Profile" button style
            cell.changeFollowStatus.layer.cornerRadius = 10
            cell.changeFollowStatus.layer.borderColor = UIColor.black.cgColor
            // Set profile photo to be round
            cell.profilePhoto.image = UIImage(named: firstLetterOfFirstName)
            cell.profilePhoto.layer.cornerRadius = cell.profilePhoto.frame.height / 2
            cell.profilePhoto.clipsToBounds = true
            // Set other profile information in its respective Labels
            cell.fullname.text = profile[indexPath.row].firstName + " " + profile[indexPath.row].lastName
            cell.username.text = "@" + profile[indexPath.row].username
            //if let bio = profile[indexPath.row].bio {
            cell.bio.text = "User will be allowed to edit their bio in future miletone."
            //}
            cell.userID = profile[indexPath.row].userID
            // Set number of followers and following
            self.getNumFollowing(forUserId: profile[indexPath.row].userID, displayInCell: cell)
            self.getNumFollowed(forUserId: profile[indexPath.row].userID, displayInCell: cell)
            
            cell.isFollowing = self.following
            
            if user?.userID != profile[indexPath.row].userID {  // Looking at another user's profile
                cell.changeFollowStatus.isHidden = false  // Show the follow/unfollow button
                if self.following {
                    UIView.performWithoutAnimation {
                        cell.changeFollowStatus.setTitle("Unfollow", for: .normal)
                        cell.changeFollowStatus.titleLabel?.textAlignment = .center
                        cell.followingIcon.isHidden = false
                    }
                } else {
                    UIView.performWithoutAnimation {
                        cell.changeFollowStatus.setTitle("Follow", for: .normal)
                        cell.changeFollowStatus.titleLabel?.textAlignment = .center
                        cell.followingIcon.isHidden = true
                    }
                }
            } else {  // Looking at our own profile
                cell.changeFollowStatus.isHidden = true  // Hide the follow/unfollow button
                cell.followingIcon.isHidden = true
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "photoCardCell", for: indexPath) as! PhotoCardCell
            
            // TODO: Temporarily using the method below to retrieve username
            // Remove later!
            let username = profile.first!.username
            
            // Set profile photo to be round
            cell.profilePhoto.image = UIImage(named: firstLetterOfFirstName)
            cell.profilePhoto.layer.cornerRadius = cell.profilePhoto.frame.height / 2
            cell.profilePhoto.clipsToBounds = true
            
            cell.username.text = username
            cell.date.text = photos[indexPath.row - 1].date
            
            // Scale photos before displaying them in UIImageView
            let photo = photos[indexPath.row - 1].photo
            let ratio = photo.getCropRatio()
            cell.photoHeightConstraint.constant = UIScreen.main.bounds.width / ratio
            cell.photo.image = photos[indexPath.row - 1].photo
            
            // Format caption before displaying
            if let caption = photos[indexPath.row - 1].caption {
                cell.caption.attributedText = formatCaption(caption, user: username)
            }
            
            return cell
        }
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
    
    private func getNumFollowed(forUserId userId: String?, displayInCell cell: ProfileInfoCell) {
        Api.numberFollowed(userID: userId) { (numFollowers, error) in
            if let _ = error {
                UIView.performWithoutAnimation { cell.numFollowers.text = String(-1) }
                return
            }
            if let followers = numFollowers {
                UIView.performWithoutAnimation { cell.numFollowers.text = String(followers) }
                return
            }
        }
    }
    
    private func getNumFollowing(forUserId userId: String?, displayInCell cell: ProfileInfoCell) {
        Api.numberFollowing(userID: userId) { (numFollowing, error) in
            if let _ = error {
                UIView.performWithoutAnimation { cell.numFollowing.text = String(-1) }
                return
            }
            if let following = numFollowing {
                UIView.performWithoutAnimation { cell.numFollowing.text = String(following) }
                return
            }
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
