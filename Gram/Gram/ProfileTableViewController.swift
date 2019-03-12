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
import FirebaseAuth
import GoogleSignIn

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
    var liked: Bool
    var likeCount: Int
    var commentCount: Int
    var photoID: String
}

class ProfileTableViewController: UIViewController, ProfileInfoCellDelegate, UITabBarControllerDelegate,
UITableViewDataSource, UITableViewDelegate, photoCardCellDelegate, CommentViewControllerDelegate {
    static var profileInfo: [Api.profileInfo]?
    var profile = [Api.profileInfo]()
    var photos = [PhotoCard]()
    var following: Bool = false  // Assume false always (this var only used when viewing another user's profile)
    var firstTimeLoadingView = false  // Set to true when user clicks on a profile to view
    var showLoadingCell = true
    var profilePhotoOfDifferentUser: UIImage?
    @IBOutlet weak var profileTableView: UITableView!
    
    override func viewWillDisappear(_ animated: Bool) {
        profilePhotoOfDifferentUser = nil  // Reset
    }
    
    override func viewWillAppear(_ animated: Bool) {
        changeStatusBarColor(forView: self)
        
        if let profileInfo = ProfileTableViewController.profileInfo {
            profile = profileInfo
        } else {
            profile = [user!]
        }

        if profile.first!.userID != user!.userID {  // Viewing another user's profile
            self.photos.removeAll()
            showLoadingCell = true
            profileTableView.reloadData()  // Reloading table will show loading cell
            let firstLetterOfFirstName = String(profile.first!.firstName.first!)
            getProfilePhotoOfDifferentUser(firstLetterOfFirstName: firstLetterOfFirstName)
            self.profileTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)  // Auto scroll to top when viewing a different profile
        }
        else if profile.first!.userID == user!.userID {  // Viewing own profile
            if ProfileDataCache.photosNoYetFetched {
                if ProfileDataCache.loadedPhotos == nil {
                    ProfileDataCache.loadedPhotos = [PhotoCard]()  // Initialize
                }
                getUserPhotos()  // Fetch user's own photos for the first time from Firebase (will be saved in cache)
                ProfileDataCache.photosNoYetFetched = false  // Photos fetched!
            } else {
                photos = ProfileDataCache.loadedPhotos!
                profileTableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileTableView.delegate = self
        profileTableView.dataSource = self
        
        profileTableView.setShouldShowInfiniteScrollHandler { _ -> Bool in
            return false  // Assume that all photos will be loaded on first load!
        }
        
        profileTableView.addInfiniteScroll { (tableView) in
            self.getUserPhotos()  // NOTE: This block of code will actually never run because setShouldShowInfiniteScrollHandler returns false always!
        }
        
        if let profileInfo = ProfileTableViewController.profileInfo {
            profile = profileInfo
        } else {
            profile = [user!]
        }
    }
    
    func likePressed(_ sender: PhotoCardCell) {
        guard let tappedIndexPath = self.profileTableView.indexPath(for: sender) else { return }
        // Toggle between "like" and "unlike" icons when pressed
        if sender.btnLike.imageView!.image == UIImage(named: "icon_heart_empty") {
            photos[tappedIndexPath.row - 1].liked = true
            photos[tappedIndexPath.row - 1].likeCount += 1
        } else {
            photos[tappedIndexPath.row - 1].liked = false
            photos[tappedIndexPath.row - 1].likeCount -= 1
        }
        
        // Update the cache
        ProfileDataCache.loadedPhotos = photos
        
        Api.likePost(postID: sender.photoID, postType: "photo") { (response, error) in
            if let _ = error {
                print("Error — An error occurred when liking post with photoID: \(sender.photoID ?? "null")")
            }
            if let _ = response {
                // Next few lines of code makes sure that when reloading, the table don't auto scroll to top
                let lastScrollOffset = self.profileTableView.contentOffset
                self.profileTableView.beginUpdates()
                self.profileTableView.reloadRows(at: [tappedIndexPath], with: .none)
                self.profileTableView.endUpdates()
                self.profileTableView.layer.removeAllAnimations()
                self.profileTableView.setContentOffset(lastScrollOffset, animated: false)
            }
        }
    }
    
    func commentPressed(_ sender: PhotoCardCell) {  // User pressed comment button; navigate them to CommentVC
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let commentVC = storyboard.instantiateViewController(withIdentifier: "commentViewController") as! CommentViewController
        commentVC.photoID = sender.photoID  // Pass the photoID to CommentViewController
        commentVC.indexPathOfPhotoCard = self.profileTableView.indexPath(for: sender)
        commentVC.delegate = self
        self.navigationController?.pushViewController(commentVC, animated: true)
    }
    
    func commentPosted(_ indexPath: IndexPath) {
        return  // Special case for ProfileVC: CommentVC should have already updated the PhotoCard in cache directly!
    }
    
    func didChangeFollowStatus(_ sender: ProfileInfoCell) {
        //guard let _ = self.profileTableView.indexPath(for: sender) else { return }
        
        if sender.isFollowing {
            Api.followUser(followingID: sender.userID, following: true) { (response, error) in
                if let _ = error {
                    print("Issue encountered when trying to UNFOLLOW a user with id: \(sender.userID).")
                }
                if let _ = response {
                    ProfileDataCache.userIDToUsername?.removeValue(forKey: sender.userID)  // Remove from cache
                    ProfileDataCache.userIDToProfilePhoto?.removeValue(forKey: sender.userID)  // Remove from cache
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
                    ProfileDataCache.userIDToUsername?[sender.userID] = sender.username.text?.replacingOccurrences(of: "@", with: "")
                    ProfileDataCache.userIDToProfilePhoto?[sender.userID] = sender.profilePhoto.image!
                    print("Successfully FOLLOWED user with id: \(sender.userID).")
                }
            }
            self.following = true
        }
        //self.tableView.reloadRows(at: [tappedIndexPath], with: .none)
        self.profileTableView.reloadData()
    }
    
    func navigateToEditProfileViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let editProfileVC = storyboard.instantiateViewController(withIdentifier: "editProfileViewController") as! EditProfileViewController
        editProfileVC.profileTableViewDelegate = self
        self.navigationController?.pushViewController(editProfileVC, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if photos.count == 0 && showLoadingCell {
            return profile.count + 1  // Plus 1 to load the "Loading Cell"
        } else {
            return profile.count + photos.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let firstLetterOfFirstName = String(profile.first!.firstName.first!)
        
        if indexPath.row == 0 {  // This cell displays the profile info
            let cell = tableView.dequeueReusableCell(withIdentifier: "profileInfoCell", for: indexPath) as! ProfileInfoCell

            if showLoadingCell {  // If loading uploaded photos, also show "skeleton" for profile photo while it's being fetched from Firebase
                DispatchQueue.main.async {
                    cell.profilePhoto.showAnimatedGradientSkeleton()
                    cell.profilePhoto.startAnimating()
                }
            }

            cell.delegate = self
            // Set button style
            cell.changeFollowStatus.layer.cornerRadius = 10
            cell.changeFollowStatus.layer.borderColor = UIColor.black.cgColor

            // Set profile photo and make it round
            if profile[indexPath.row].userID == user!.userID {  // Grab logged-in user's profile photo from cache
                cell.profilePhoto.image = ProfileDataCache.profilePhoto!
                cell.profilePhoto.hideSkeleton()
                cell.profilePhoto.stopSkeletonAnimation()
            } else {  // Grab a different user's profile photo
                cell.profilePhoto.image = profilePhotoOfDifferentUser
                cell.profilePhoto.hideSkeleton()
                cell.profilePhoto.stopSkeletonAnimation()
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
                cell.logout.isHidden = true  // Hide logout button when viewing another user's profile
                
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
                cell.logout.isHidden = false  // Show logout button when viewing own profile
                cell.changeFollowStatus.setTitle("Edit Profile", for: .normal)
                cell.changeFollowStatus.titleLabel?.textAlignment = .center
                cell.followingIcon.isHidden = true
            }
            
            return cell
        } else if photos.count == 0 && showLoadingCell {  // Cell to display loading icon
            let cell = tableView.dequeueReusableCell(withIdentifier: "loadingCell", for: indexPath) as! LoadingCell
            cell.loadingIndicator.startAnimating()
            return cell
        } else {  // The remaining cells are the "PhotoCard" cells
            let cell = tableView.dequeueReusableCell(withIdentifier: "photoCardCell", for: indexPath) as! PhotoCardCell
            cell.delegate = self
            cell.photoID = photos[indexPath.row - 1].photoID
            
            if profile.first!.userID == user!.userID {  // Current user
                if let photo = ProfileDataCache.profilePhoto {
                    cell.profilePhoto.image = photo
                } else {
                    cell.profilePhoto.image = UIImage(named: firstLetterOfFirstName)
                }
            } else {  // Different user
                cell.profilePhoto.image = profilePhotoOfDifferentUser
            }
            
            // Set profile photo to be round
            cell.profilePhoto.layer.cornerRadius = cell.profilePhoto.frame.height / 2
            cell.profilePhoto.clipsToBounds = true
            
            let username = profile.first!.username  // TODO: check username
            cell.username.text = username
            cell.date.text = photos[indexPath.row - 1].date
            
            // Set up like button and number of likes
            if photos[indexPath.row - 1].liked {
                cell.btnLike.setImage(UIImage(named: "icon_heart_filled"), for: .normal)
            } else {
                cell.btnLike.setImage(UIImage(named: "icon_heart_empty"), for: .normal)
            }
            
            let likeCount = photos[indexPath.row - 1].likeCount
            let commentCount = photos[indexPath.row - 1].commentCount
            cell.lblNumLikesNumComments.text = ""  // Reset
            
            if likeCount == 0 && commentCount == 0 {
                cell.lblNumLikesNumComments.isHidden = true  // Don't show label if photo has no likes and comments
            } else {
                cell.lblNumLikesNumComments.isHidden = false
            }
            
            if likeCount >= 1 {
                cell.lblNumLikesNumComments.text = likeCount > 1 ? "\(likeCount) likes" : "1 like"
            }
        
            if likeCount > 0 && commentCount > 0 {
                cell.lblNumLikesNumComments.text?.append(" • ")  // Use bullet point as separator
            }
            
            // Set comment count
            if commentCount == 1 {
                cell.lblNumLikesNumComments.text?.append("1 comment")
            } else if commentCount > 1 {
                cell.lblNumLikesNumComments.text?.append("\(commentCount) comments")
            }
            
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
    
    func getUserPhotos() {
        self.photos.removeAll()  // Load photos from clean slate
        
        Api.getProfilePhotos(userID: profile.first!.userID, completion: { (photoList, error) in
            if let _ = error {
                self.showLoadingCell = false
            }
            if let photoList = photoList {
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
                    
                    // Format upload date of photo
                    var date = photo.datePosted
                    if let rangeToRemove = date.range(of: " at") {  // Remove the time part of date (Only want [MM DD, YYYY] part)
                        date.removeSubrange(rangeToRemove.lowerBound ..< date.endIndex)
                    }
                    
                    // Extract profile photo
                    let profilePhoto: UIImage?
                    if self.profile.first!.userID == user!.userID {
                        profilePhoto = ProfileDataCache.profilePhoto
                    } else {
                        profilePhoto = self.profilePhotoOfDifferentUser
                    }
                    
                    let username = self.profile.first!.username
                    
                    // Construct PhotoCard object
                    self.photos.append(PhotoCard.init(profilePhoto: profilePhoto!,
                                                      username: username,
                                                      date: date,
                                                      photo: photoToDisplay,
                                                      caption: photo.caption,
                                                      tags: photo.tags,
                                                      liked: photo.liked,
                                                      likeCount: photo.likeCount,
                                                      commentCount: photo.commentCount,
                                                      photoID: photo.photoID))
                }  // for-loop
                
                self.showLoadingCell = false  // No photos so don't try loading any photos when reloading table view
                self.profileTableView.reloadData()
                self.profileTableView.finishInfiniteScroll()
                
                // Save photos in cache only for logged-in user
                if self.profile.first!.userID == user!.userID {
                    ProfileDataCache.loadedPhotos = self.photos
                }
            }
        })
    }
    
    /**
     * Retrieves the profile photo of a different user (i.e. not the logged-in user)
     * via the provided URL in the Api.profileInfo object. It does this in a background
     * queue, and then sets @profilePhotoOfDifferentUser to the loaded profile photo.
     *
     * On error, it will use the default profile photo (First letter of user's first name).
     */
    private func getProfilePhotoOfDifferentUser(firstLetterOfFirstName: String) {
        var execute = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let profilePhotoURL = self.profile.first!.profilePhoto {
                if profilePhotoURL == "" {
                    self.profilePhotoOfDifferentUser = UIImage(named: firstLetterOfFirstName)
                } else {
                    do {
                        let url = URL(string: profilePhotoURL)
                        let data = try Data(contentsOf: url!)
                        self.profilePhotoOfDifferentUser = UIImage(data: data)
                    } catch {
                        self.profilePhotoOfDifferentUser = UIImage(named: firstLetterOfFirstName)
                    }
                }
                execute = 1
            }
            DispatchQueue.global(qos: .userInitiated).async {
                while execute == 0 { continue }
                DispatchQueue.main.async {
                    self.getUserPhotos()
                }
            }
        }
    }
    
    func logout() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            user = nil
            
            // Purge the cache
            ProfileTableViewController.profileInfo = nil
            ProfileDataCache.loadedPhotos = nil
            ProfileDataCache.photosNoYetFetched = true
            ProfileDataCache.userIDToProfilePhoto = nil
            ProfileDataCache.userIDToUsername = nil
            ProfileDataCache.profilePhoto = nil
            
            self.navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
}

extension UIImage {
    func saveToTempDir(_ data: Data) -> URL? {
        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("img", isDirectory: false)
            .appendingPathExtension("jpeg")
        // Write to disk
        do {
            try data.write(to: url)
        } catch {
            return nil
        }
        return url
    }
    
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
