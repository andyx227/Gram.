//
//  SecondViewController.swift
//  Gram
//
//  Created by Andy Xue on 1/24/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit

class CommunityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, photoCardCellDelegate, CommentViewControllerDelegate {
    
    
    @IBOutlet weak var viewNoPhotos: UILabel!
    @IBOutlet weak var communityTableView: UITableView!
    @IBOutlet weak var communitySearchBar: UISearchBar!
    var photos = [PhotoCard]()
    var showLoadingCell = true
    var pullToRefresh: PullToRefresh?
    var tagSearched = ""
    var photosProcessed = 0
    
    var tableViewRefreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = .white
        refreshControl.tintColor = .clear
        refreshControl.addTarget(self, action: #selector(refreshCommunityFeed), for: .valueChanged)
        return refreshControl
    }()
    
    @IBAction func editCommunityJoined(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let joinCommunityVC = storyboard.instantiateViewController(withIdentifier: "joinCommunityViewController") as! JoinCommunityViewController
        self.navigationController?.pushViewController(joinCommunityVC, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboard()
        communityTableView.delegate = self
        communityTableView.dataSource = self
        communitySearchBar.delegate = self
        communitySearchBar.autocapitalizationType = .none
        
        // Set up RefreshControl for NewsfeedTableView
        communityTableView.refreshControl = tableViewRefreshControl
        getRefereshView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        changeStatusBarColor(forView: self)
        
        if ProfileDataCache.CommunitiesJoined!.isEmpty {  // User has not joined any communities
            communityTableView.isHidden = true
            viewNoPhotos.isHidden = false
            return
        }
        
        communityTableView.isHidden = false
        viewNoPhotos.isHidden = true

        if ProfileDataCache.loadedCommunityPhotos == nil || ProfileDataCache.communityChanged {
            photos.removeAll()
            showLoadingCell = true
            communityTableView.reloadData()
            getJoinedCommunityPhotos(false)
            ProfileDataCache.communityChanged = false
        }
    }
    
    func getRefereshView() {
        if let objOfRefreshView = Bundle.main.loadNibNamed("PullToRefreshView", owner: self, options: nil)?.first as? PullToRefresh {
            pullToRefresh = objOfRefreshView
            pullToRefresh!.frame = tableViewRefreshControl.frame
            tableViewRefreshControl.addSubview(pullToRefresh!)
        }
    }
    
    @objc func refreshCommunityFeed() {
        if let pullToRefresh = pullToRefresh {
            pullToRefresh.startAnimation()
            
            if communitySearchBar.text!.isEmpty {  // User is not searching for community, so fetch photos from own community
                getJoinedCommunityPhotos(true)
            } else {
                getCommunityPhotos(tagSearched, true)  // Search for photos from a specific community
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if photos.isEmpty && showLoadingCell {
            return 1  // Display the loading cell only, so return 1 cell
        } else if photos.isEmpty {
            viewNoPhotos.isHidden = false  // Show message
            return 0
        } else {
            viewNoPhotos.isHidden = true  // Hide message
            return photos.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if photos.count == 0 && showLoadingCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "loadingCell", for: indexPath) as! LoadingCell
            cell.loadingIndicator.startAnimating()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "photoCardCell", for: indexPath) as! PhotoCardCell
            cell.delegate = self
            cell.photoID = photos[indexPath.row].photoID
            cell.username.text = photos[indexPath.row].username
            cell.date.text = photos[indexPath.row].date
            if let caption = photos[indexPath.row].caption {
                cell.caption.text = "@\(photos[indexPath.row].username) " + caption
            }
            
            // Set profile photo to be round
            cell.profilePhoto.image = photos[indexPath.row].profilePhoto
            cell.profilePhoto.layer.cornerRadius = cell.profilePhoto.frame.height / 2
            cell.profilePhoto.clipsToBounds = true
            
            // Set up like button
            if photos[indexPath.row].liked {
                cell.btnLike.setImage(UIImage(named: "icon_heart_filled"), for: .normal)
            } else {
                cell.btnLike.setImage(UIImage(named: "icon_heart_empty"), for: .normal)
            }
            
            let likeCount = photos[indexPath.row].likeCount
            let commentCount = photos[indexPath.row].commentCount
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
            let photo = photos[indexPath.row].photo
            let ratio = photo.getCropRatio()
            cell.photoHeightConstraint.constant = UIScreen.main.bounds.width / ratio
            cell.photo.image = photos[indexPath.row].photo
            
            return cell
        }
    }
    
    func likePressed(_ sender: PhotoCardCell) {
        guard let tappedIndexPath = self.communityTableView.indexPath(for: sender) else { return }
        // Toggle between "like" and "unlike" icons when pressed
        if sender.btnLike.imageView!.image == UIImage(named: "icon_heart_empty") {
            photos[tappedIndexPath.row].liked = true
            photos[tappedIndexPath.row].likeCount += 1
        } else {
            photos[tappedIndexPath.row].liked = false
            photos[tappedIndexPath.row].likeCount -= 1
        }
        
        Api.likePost(postID: sender.photoID, postType: "photo") { (response, error) in
            if let _ = error {
                print("Error — An error occurred when liking post with photoID: \(sender.photoID ?? "null")")
            }
            if let _ = response {
                // Next few lines of code makes sure that when reloading, the table don't auto scroll to top
                let lastScrollOffset = self.communityTableView.contentOffset
                self.communityTableView.beginUpdates()
                self.communityTableView.reloadRows(at: [tappedIndexPath], with: .none)
                self.communityTableView.endUpdates()
                self.communityTableView.layer.removeAllAnimations()
                self.communityTableView.setContentOffset(lastScrollOffset, animated: false)
            }
        }
    }
    
    func commentPressed(_ sender: PhotoCardCell) {  // User pressed comment button; navigate them to CommentVC
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let commentVC = storyboard.instantiateViewController(withIdentifier: "commentViewController") as! CommentViewController
        commentVC.photoID = sender.photoID  // Pass the photoID to CommentViewController
        commentVC.indexPathOfPhotoCard = communityTableView.indexPath(for: sender)
        commentVC.delegate = self
        self.navigationController?.pushViewController(commentVC, animated: true)
    }
    
    func commentPosted(_ indexPath: IndexPath) {
        photos[indexPath.row].commentCount += 1
        let lastScrollOffset = self.communityTableView.contentOffset
        self.communityTableView.beginUpdates()
        self.communityTableView.reloadRows(at: [indexPath], with: .none)
        self.communityTableView.endUpdates()
        self.communityTableView.layer.removeAllAnimations()
        self.communityTableView.setContentOffset(lastScrollOffset, animated: false)
    }
    
    @IBAction func searchCommunity(_ sender: Any) {
        var searchText = communitySearchBar.text ?? ""
        
        if searchText.isEmpty && photos.isEmpty {  // No photos to show and there is no search text
            viewNoPhotos.isHidden = false // Show "no photos" message
            return
        } else if searchText.isEmpty {  // No search text, so don't do anything
            return
        }
        
        if searchText.first! == "#" { searchText.removeFirst() }  // Remove hashtag symbol
        searchText = searchText.lowercased()  // No capital letters!
        tagSearched = searchText  // Save the tag the user is searching for
        
        viewNoPhotos.isHidden = true
        showLoadingCell = true
        photos.removeAll()
        self.communityTableView.isHidden = false
        self.communityTableView.reloadData()  // Show loading cell by reloading table
        self.communityTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)  // Auto scroll to top of CommunityTableVIew
        
        // Search for community photos
        getCommunityPhotos(searchText, false)
    }
    
    // User clicked "Search" button on keyboard; has same behavior as clicking the "checkmark" button
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        var searchText = communitySearchBar.text ?? ""
        
        if searchText.isEmpty && photos.isEmpty {  // No photos to show and there is no search text
            viewNoPhotos.isHidden = false // Show "no photos" message
            return
        } else if searchText.isEmpty {  // No search text, so don't do anything
            return
        }
        
        if searchText.first! == "#" { searchText.removeFirst() }  // Remove hashtag symbol
        searchText = searchText.lowercased()  // No capital letters!
        tagSearched = searchText  // Save the tag the user is searching for
        
        viewNoPhotos.isHidden = true
        showLoadingCell = true
        photos.removeAll()
        self.communityTableView.isHidden = false
        self.communityTableView.reloadData()  // Show loading cell by reloading table
        self.communityTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)  // Auto scroll to top of CommunityTableVIew
        
        // Search for community photos
        getCommunityPhotos(searchText, false)
        communitySearchBar.resignFirstResponder()  // Hide the keyboard
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            if ProfileDataCache.loadedCommunityPhotos == nil {
                return
            } else {
                photos = ProfileDataCache.loadedCommunityPhotos!
                communityTableView.reloadData()
            }
        }
    }
    
    /// Retrieves the photos from communities that user has joined
    func getJoinedCommunityPhotos(_ pulledDownToRefresh: Bool) {
        Api.getUserTags { (communityPhotos, error) in
            if let _ = error {
                print("Error — Error occurred when retrieving photos from communities the user has joined.")
                self.communityTableView.isHidden = true
                self.viewNoPhotos.isHidden = false
            }
            if let communityPhotos = communityPhotos {
                self.photos.removeAll()  // Start from clean slate
                self.processPhotos(communityPhotos)
                
                DispatchQueue.global(qos: .userInitiated).async {
                    while self.photosProcessed < communityPhotos.count { continue }  // Busy wait until all photos processed (using Dispatch Group will hang program!)
                    self.photosProcessed = 0  // Reset
                    self.showLoadingCell = false
                    ProfileDataCache.loadedCommunityPhotos = self.photos  // Save fetched community photos in cache
                    DispatchQueue.main.async {
                        self.communityTableView.reloadData()
                        if self.photos.isEmpty {
                            self.viewNoPhotos.isHidden = false
                        }
                        if pulledDownToRefresh {
                            self.tableViewRefreshControl.endRefreshing()
                        }
                    }
                }
            }
        }
    }

    /// Retrieves photos of community that user searched for
    func getCommunityPhotos(_ tag: String, _ pulledDownToRefresh: Bool) {
        if tag.isEmpty { return }
        
        Api.searchTags(tag: tag) { (photosInCommunity, error) in
            if let _ = error {
                print("Error — Error occurred when retrieving photos by hashtag: \(tag)")
            }
            if let photosInCommunity = photosInCommunity {
                self.photos.removeAll()  // Start from clean slate
                self.processPhotos(photosInCommunity)
               
                DispatchQueue.global(qos: .userInitiated).async {
                    while self.photosProcessed < photosInCommunity.count { continue }  // Busy wait until all photos processed (using Dispatch Group will hang program!)
                    self.photosProcessed = 0  // Reset
                    self.showLoadingCell = false
                    DispatchQueue.main.async {
                        self.communityTableView.reloadData()
                        if pulledDownToRefresh {
                            self.tableViewRefreshControl.endRefreshing()
                        }
                    }
                }
            }
        }
    }
    
    private func processPhotos(_ communityPhotos: [Api.photoURL]) {
        for photo in communityPhotos {
            var errorProfilePhotoRetrieval = false
            var errorPhotoRetrieval = false
            var photoToDisplayInPhotoCard: UIImage?
            var profilePhoto: UIImage?
            var username: String?
            
            var tasksDone = 0
            DispatchQueue.global(qos: .userInitiated).async {
                do {  // Attempt to extract the photo from the given photo url
                    let url = URL(string: photo.URL)
                    guard let photoURL = url else {
                        errorPhotoRetrieval = true
                        tasksDone += 1
                        return
                    }
                    let data = try Data(contentsOf: photoURL)
                    photoToDisplayInPhotoCard = UIImage(data: data)
                } catch {
                    errorPhotoRetrieval = true
                }
                tasksDone += 1
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                Api.getUserName(userID: photo.userID, completion: { (usrname) in
                    username = usrname  // Grab username
                    
                    Api.getProfilePhotoWithUID(userID: photo.userID, completion: { (url, error) in
                        if let _ = error {
                            print("Error — Error when retrieving profile photo of user with ID: \(photo.userID)")
                            errorProfilePhotoRetrieval = true
                            tasksDone += 1
                            return
                        }
                        if let url = url {
                            if url == "" {
                                profilePhoto = UIImage(named: String(username!.capitalized.first!))!
                            } else {
                                do {  // Attempt to extract the photo from the given photo url
                                    let url = URL(string: url)
                                    guard let photoURL = url else {
                                        profilePhoto = UIImage(named: String(username!.capitalized.first!))!
                                        tasksDone += 1
                                        return
                                    }
                                    let data = try Data(contentsOf: photoURL)
                                    profilePhoto = UIImage(data: data)!
                                } catch {
                                    profilePhoto = UIImage(named: String(username!.capitalized.first!))!
                                }
                                tasksDone += 1
                            }
                        }
                    })  // Api.getProfilePhotoWithUID()
                })  // Api.getUserName()
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                while (tasksDone != 2) { continue }  // Busy wait until all tasks complete (using Dispatch Group will hang program!)
                self.photosProcessed += 1
                
                if errorPhotoRetrieval { return }  // If error when loading photo, try loading another photo card (skip this one)
                guard let photoToDisplay = photoToDisplayInPhotoCard else { return }  // If cannot load photo, skip this PhotoCard
                if errorProfilePhotoRetrieval { profilePhoto = UIImage(named: "A")! }
                
                // Format upload date for this photo
                var date = photo.datePosted
                if let rangeToRemove = date.range(of: " at") {  // Remove the time part of date (Only want [MM DD, YYYY] part)
                    date.removeSubrange(rangeToRemove.lowerBound ..< date.endIndex)
                }
                
                // Construct PhotoCard object
                self.photos.append(PhotoCard.init(profilePhoto: profilePhoto!,
                                                  username: username!,
                                                  date: date,
                                                  photo: photoToDisplay,
                                                  caption: photo.caption,
                                                  tags: photo.tags,
                                                  liked: photo.liked,
                                                  likeCount: photo.likeCount,
                                                  commentCount: photo.commentCount,
                                                  photoID: photo.photoID))
            }
        }  // For()
    }

}

