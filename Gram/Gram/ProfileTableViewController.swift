//
//  ProfileTableViewController.swift
//  Gram
//
//  Created by Andy Xue on 2/8/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit
import UIScrollView_InfiniteScroll
import NVActivityIndicatorView

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
    var tags: [String]?
}

class ProfileTableViewController: UITableViewController, ProfileInfoCellDelegate, UITabBarControllerDelegate {
    var profile: [Api.profileInfo] = [user!]
    var photos = [PhotoCard]()
    var following: Bool = false  // Assume false always (this var only used when viewing another user's profile)
    var firstTimeLoadingView = false  // Set to true when user clicks on a profile to view
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.setShouldShowInfiniteScrollHandler { _ -> Bool in
            if ProfileDataCache.clean {
                return false  // Do not retrieve photos if the cache is clean!
            } else {
                return true
            }
        }
        
        tableView.addInfiniteScroll { (tableView) in
            self.getUserPhotos()
        }
        
        getUserPhotos()
    }
    
    func didChangeFollowStatus(_ sender: ProfileInfoCell) {
        guard let _ = self.tableView.indexPath(for: sender) else { return }
        
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
        //self.tableView.reloadRows(at: [tappedIndexPath], with: .none)
        self.tableView.reloadData()
    }
    
    func navigateToEditProfileViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let editProfileVC = storyboard.instantiateViewController(withIdentifier: "editProfileViewController") as! EditProfileViewController
        editProfileVC.profileTableViewDelegate = self
        self.navigationController?.pushViewController(editProfileVC, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if photos.count == 0 {
            return profile.count + 1  // Plus 1 to load the "Loading Cell"
        } else {
            return profile.count + photos.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let firstLetterOfFirstName = String(profile.first!.firstName.first!)
        
        if indexPath.row == 0 {  // This cell displays the profile info
            let cell = tableView.dequeueReusableCell(withIdentifier: "profileInfoCell", for: indexPath) as! ProfileInfoCell

            cell.delegate = self
            // Set "Edit Profile" button style
            cell.changeFollowStatus.layer.cornerRadius = 10
            cell.changeFollowStatus.layer.borderColor = UIColor.black.cgColor
            
            // Set profile photo
            if profile[indexPath.row].userID != user?.userID {  // Viewing another user's profile
                if firstTimeLoadingView {
                    cell.profilePhoto.showAnimatedGradientSkeleton()
                    getProfilePhoto(cell)
                }
            } else {
                if let profilePhoto = ProfileDataCache.profilePhoto {  // Get profile photo from cache if possible
                    cell.profilePhoto.image = profilePhoto
                } else {  // Otherwise, make an api call to retreive profile photo from Firebase
                    cell.profilePhoto.showAnimatedGradientSkeleton()
                    getProfilePhoto(cell)
                }
            }
            
            cell.profilePhoto.layer.cornerRadius = cell.profilePhoto.frame.height / 2
            cell.profilePhoto.clipsToBounds = true
            // Set other profile information in its respective Labels
            cell.fullname.text = profile[indexPath.row].firstName + " " + profile[indexPath.row].lastName
            cell.username.text = "@" + profile[indexPath.row].username
            cell.bio.text = profile[indexPath.row].summary
            cell.userID = profile[indexPath.row].userID
            
            // Set number of followers and following if loading view for the first time
            if firstTimeLoadingView {
                self.getNumFollowersAndFollowing(forUserId: profile[indexPath.row].userID, displayInCell: cell)
                firstTimeLoadingView = false
            }
            
            cell.isFollowing = self.following
            
            if user?.userID != profile[indexPath.row].userID {  // Looking at another user's profile
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
                cell.changeFollowStatus.setTitle("Edit Profile", for: .normal)
                cell.changeFollowStatus.titleLabel?.textAlignment = .center
                cell.followingIcon.isHidden = true
            }
            
            return cell
        } else if photos.count == 0 {  // Cell to display loading icon
            let cell = tableView.dequeueReusableCell(withIdentifier: "loadingCell", for: indexPath) as! LoadingCell
            cell.loadingIndicator.startAnimating()
            return cell
        } else {  // The remaining cells are the "PhotoCard" cells
            let cell = tableView.dequeueReusableCell(withIdentifier: "photoCardCell", for: indexPath) as! PhotoCardCell
            
            // Set profile photo
            if let photo = ProfileDataCache.profilePhoto {
                cell.profilePhoto.image = photo
            } else {
                cell.profilePhoto.image = UIImage(named: firstLetterOfFirstName)
            }
            
            // Set profile photo to be round
            cell.profilePhoto.layer.cornerRadius = cell.profilePhoto.frame.height / 2
            cell.profilePhoto.clipsToBounds = true
            
            let username = photos[indexPath.row - 1].username
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
        if caption.isEmpty {return NSAttributedString(string: "")}
        
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
    
    private func getNumFollowersAndFollowing(forUserId userId: String?, displayInCell cell: ProfileInfoCell) {
        cell.numFollowers.alpha = 0.0
        cell.numFollowing.alpha = 0.0
        
        Api.followCounts(userID: userId) { (counts, error) in
            if let _ = error {
                UIView.performWithoutAnimation { cell.numFollowers.text = String(-1) }
                return
            }
            if let counts = counts as? [String: Int] {
                cell.numFollowers.text = String(counts["followers"]!)
                cell.numFollowing.text = String(counts["followed"]!)
                self.fadeInAnimation(cell.numFollowers, duration: 0.8)
                self.fadeInAnimation(cell.numFollowing, duration: 0.8)
                return
            }
        }
    }
    
    // TODO: Api.profileInfo should contain url for user profile photo.
    // Function can only use logged-in user's profile photo, even when
    // viewing another user's profile!
    private func getProfilePhoto(_ cell: ProfileInfoCell) {
        let firstLetterOfFirstName = String(profile.first!.firstName.first!)
        
        Api.getProfilePhoto { (photoUrl, error) in
            if let _ = error {  // Show default profile photo if error
                cell.profilePhoto.image = UIImage(named: firstLetterOfFirstName)
            }
            if let photoUrl = photoUrl {
                if photoUrl == "" {  // No URL for profile photo, so use default profile photo
                    cell.profilePhoto.image = UIImage(named: firstLetterOfFirstName)
                    cell.profilePhoto.hideSkeleton()
                    cell.profilePhoto.stopSkeletonAnimation()
                    return
                }
                
                do {
                    let url = URL(string: photoUrl)
                    let data = try Data(contentsOf: url!)
                    ProfileDataCache.profilePhoto = UIImage(data: data)  // Save image in cache
                    cell.profilePhoto.image = ProfileDataCache.profilePhoto
                } catch {  // Show default profile photo if error
                    cell.profilePhoto.image = UIImage(named: firstLetterOfFirstName)
                }
                cell.profilePhoto.hideSkeleton()
                cell.profilePhoto.stopSkeletonAnimation()
            }
            
            // Set profile photo to be round
            cell.profilePhoto.layer.cornerRadius = cell.profilePhoto.frame.height / 2
            cell.profilePhoto.clipsToBounds = true
        }
    }
    
    func getUserPhotos() {
        self.photos.removeAll()  // Load photos from clean slate
        self.tableView.reloadData()
        Api.getProfilePhotos(completion: { (photoList, error) in
            if let _ = error {
                return
            }
            if let photoList = photoList {
                while (ProfileDataCache.profilePhoto == nil) { continue }  // Busy wait until profile photo has been loaded
                
                for photo in photoList {
                    var photoToDisplayInPhotoCard: UIImage?
                    do {  // Attempt to extract the photo from the given photo url
                        let url = URL(string: photo.URL)
                        guard let photoURL = url else { continue }  // If cannot load url, skip this PhotoCard
                        let data = try Data(contentsOf: photoURL)
                        photoToDisplayInPhotoCard = UIImage(data: data)
                    } catch {  // If error, try loading another photo card (skip this one)
                        continue
                    }
                    guard let photoToDisplay = photoToDisplayInPhotoCard else { continue }  // If cannot load photo, skip this PhotoCard
                    
                    var date = photo.datePosted
                    if let rangeToRemove = date.range(of: " at") {  // Remove the time part of date (Only want [MM DD, YYYY] part)
                        date.removeSubrange(rangeToRemove.lowerBound ..< date.endIndex)
                    }
                    // Construct PhotoCard object
                    self.photos.append(PhotoCard.init(profilePhoto: ProfileDataCache.profilePhoto!,
                                                      username: user!.username,
                                                      date: date,
                                                      photo: photoToDisplay,
                                                      caption: photo.caption,
                                                      tags: photo.tags))
                }
                self.tableView.reloadData()
                self.tableView.finishInfiniteScroll()
                // Save photos in cache
                ProfileDataCache.loadedPhotos = self.photos
                ProfileDataCache.clean = true
            }
        })
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
