//
//  NewsfeedViewController.swift
//  Gram
//
//  Created by Andy Xue on 2/9/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit

class NewsfeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UITabBarControllerDelegate, photoCardCellDelegate {
   
    @IBOutlet weak var searchBarPeople: UISearchBar!
    @IBOutlet weak var newsfeedTableView: UITableView!
    @IBOutlet weak var searchPeopleTableView: UITableView!
    @IBOutlet weak var viewNoPhotos: UIView!
    var people = [Api.userInfo]()
    var photos = [PhotoCard]()
    var imageURL: URL?
    var previouslySelectedTabIndex = 0
    var showLoadingCell = true
    var pullToRefresh: PullToRefresh?
    
    var tableViewRefreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = .white
        refreshControl.tintColor = .clear
        refreshControl.addTarget(self, action: #selector(refreshNewsfeed), for: .valueChanged)
        return refreshControl
    }()
    
    
    override func viewWillAppear(_ animated: Bool) {
        changeStatusBarColor(forView: self)
    }
    
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
        
        // Set up RefreshControl for NewsfeedTableView
        newsfeedTableView.refreshControl = tableViewRefreshControl
        getRefereshView()
        
        newsfeedTableView.setShouldShowInfiniteScrollHandler { _ -> Bool in
            return false  // Assume that all photos will be loaded on first load!
        }
        
        newsfeedTableView.addInfiniteScroll { (tableView) in
            self.getNewsfeedPhotos(false)  // NOTE: This block of code will actually never run because setShouldShowInfiniteScrollHandler returns false always!
        }

        newsfeedTableView.reloadData()  // Display the "Loading Cell" (shows the loading indicator)
        getListOfFollowing()  // This funtion will in turn call getNewsfeedPhotos(), which will populate NewsfeedTableView
    }
    
    // Allow user to choose photo from album to post
    @IBAction func btnPost(_ sender: UIButton) {
        self.photoLibrary()
        changeStatusBarColor(forView: nil)
    }
    
    // Allow user to take a picture using camera, then post
    @IBAction func btnCamera(_ sender: Any) {
        self.camera()
    }
    
    func likePressed(_ sender: PhotoCardCell) {
        guard let tappedIndexPath = self.newsfeedTableView.indexPath(for: sender) else { return }
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
                let lastScrollOffset = self.newsfeedTableView.contentOffset
                self.newsfeedTableView.beginUpdates()
                self.newsfeedTableView.reloadRows(at: [tappedIndexPath], with: .none)
                self.newsfeedTableView.endUpdates()
                self.newsfeedTableView.layer.removeAllAnimations()
                self.newsfeedTableView.setContentOffset(lastScrollOffset, animated: false)
            }
        }
    }
    
    func commentPressed(_ sender: PhotoCardCell) {  // User pressed comment button; navigate them to CommentVC
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let commentVC = storyboard.instantiateViewController(withIdentifier: "commentViewController") as! CommentViewController
        commentVC.photoID = sender.photoID  // Pass the photoID to CommentViewController
        self.navigationController?.pushViewController(commentVC, animated: true)
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController is NewsfeedViewController {
            let newsfeedVC = viewController as! NewsfeedViewController
            newsfeedVC.searchBarPeople.text = ""
            newsfeedVC.searchPeopleTableView.isHidden = true
            newsfeedVC.newsfeedTableView.isHidden = false
            
            if photos.count > 0 {  // If there are no cells, no need to auto-scroll to top
                newsfeedTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)  // Auto scroll to top of NewsfeedTableView
                viewNoPhotos.isHidden = true
            } else {
                viewNoPhotos.isHidden = false
            }
            
            previouslySelectedTabIndex = 0
            
        } else if viewController is ProfileTableViewController {
            let profileVC = self.tabBarController?.viewControllers![2] as! ProfileTableViewController
            changeStatusBarColor(forView: profileVC)
            profileVC.profile = [user!]
            profileVC.firstTimeLoadingView = true
            
            if ProfileDataCache.loadedPhotos == nil {
                ProfileDataCache.loadedPhotos = [PhotoCard]()  // Initialize
                profileVC.getUserPhotos()  // First time loading own profile, so fetch photos from Firebase (will be saved in cache)
            } else {
                profileVC.photos = ProfileDataCache.loadedPhotos!
                profileVC.profileTableView.reloadData()  // Only reload table if we are coming to profile tab from another tab
            }
            
            profileVC.profileTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)  // Auto scroll to top of ProfileTableView
            previouslySelectedTabIndex = 2
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {  // If user is not searching anything...
            self.searchPeopleTableView.isHidden = true  // Hide People Search TableView
            
            if photos.count == 0 {
                self.viewNoPhotos.isHidden = false
                self.newsfeedTableView.isHidden = false  // Show Newsfeed (allows users to pull down to refresh table)
            } else {
                self.viewNoPhotos.isHidden = true
                self.newsfeedTableView.isHidden = false  // Show Newsfeed
            }
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
                self.viewNoPhotos.isHidden = true
                self.searchPeopleTableView.isHidden = false
                self.searchPeopleTableView.reloadData()
            } else {
                self.searchPeopleTableView.isHidden = true  // Hide People Search TableView
                self.newsfeedTableView.isHidden = false  // Show Newsfeed
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
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
            if showLoadingCell {
                return 1
            }
            if photos.count > 0 {
                self.searchPeopleTableView.isHidden = true
                self.newsfeedTableView.isHidden = false
                self.viewNoPhotos.isHidden = true
            } else {
                self.searchPeopleTableView.isHidden = true
                self.newsfeedTableView.isHidden = false  // Still show empty NewsfeedView because we want to allow users to refresh (pull-down-to-refresh)
                self.viewNoPhotos.isHidden = false
            }
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
            if photos.count == 0 && showLoadingCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "loadingCell", for: indexPath) as! LoadingCell
                cell.loadingIndicator.startAnimating()
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "photoCardCell", for: indexPath) as! PhotoCardCell
                cell.delegate = self
                cell.photoID = photos[indexPath.row].photoID
                
                // Set profile photo to be round
                cell.profilePhoto.image = photos[indexPath.row].profilePhoto
                cell.profilePhoto.layer.cornerRadius = cell.profilePhoto.frame.height / 2
                cell.profilePhoto.clipsToBounds = true
                
                let username = photos[indexPath.row].username
                cell.username.text = username
                cell.date.text = photos[indexPath.row].date
                
                // Set up like button
                if photos[indexPath.row].liked {
                    cell.btnLike.setImage(UIImage(named: "icon_heart_filled"), for: .normal)
                } else {
                    cell.btnLike.setImage(UIImage(named: "icon_heart_empty"), for: .normal)
                }
                
                // Set like count
                let likeCount = photos[indexPath.row].likeCount
                cell.likeCount = likeCount
                
                if likeCount == 0 {
                    cell.lblNumLikes.isHidden = true  // Don't show "number of likes" label if photo has no likes
                } else {
                    cell.lblNumLikes.isHidden = false
                    cell.lblNumLikes.text = likeCount > 1 ? "\(likeCount) likes" : "1 like"
                }
                
                // Scale photos before displaying them in UIImageView
                let photo = photos[indexPath.row].photo
                let ratio = photo.getCropRatio()
                cell.photoHeightConstraint.constant = UIScreen.main.bounds.width / ratio
                cell.photo.image = photos[indexPath.row].photo
                
                // Format caption before displaying
                if let caption = photos[indexPath.row].caption {
                    cell.caption.enabledTypes = [.hashtag, .mention]
                    cell.caption.attributedText = NSAttributedString(string: "@\(username) " + caption)
                    // TODO: taps on hashtags (#) and mentions (@)
                    cell.caption.handleHashtagTap { hashtag in
                        print("Note — Pressed hashtag: \(hashtag)")
                    }
                    cell.caption.handleMentionTap{ mention in
                        print("Note — Pressed mention: \(mention)")
                    }
                    
                }
                return cell
            }
        } else {  // This case should never be reached!
            let cell = tableView.dequeueReusableCell(withIdentifier: "ShouldNeverDequeueCellHere!")
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.newsfeedTableView { return }
        
        let selectedUser = [Api.profileInfo.init(firstName: people[indexPath.row].firstName,
                                                 lastName: people[indexPath.row].lastName,
                                                 username: people[indexPath.row].userName,
                                                 email: "",
                                                 summary: people[indexPath.row].summary,  // TODO: userInfo should include a summary field too, using empty string for now
                                                 userID: people[indexPath.row].userID,
                                                 profilePhoto: people[indexPath.row].profilePhoto)
        ]

        let profileTab = self.tabBarController?.viewControllers![2] as! ProfileTableViewController
        ProfileTableViewController.profileInfo = selectedUser
        profileTab.following = people[indexPath.row].following
        profileTab.firstTimeLoadingView = true
        self.tabBarController?.selectedViewController = profileTab
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
    
    
    private func getNewsfeedPhotos(_ firstTimeLoad: Bool) {
        Api.getFollowerPhotos { (photoList, error) in
            if let _ = error {
                self.showLoadingCell = false
            }
            if let photoList = photoList {
                self.photos.removeAll()  // Start loading photos from clean slate
                
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
                    
                    // Format upload date for this photo
                    var date = photo.datePosted
                    if let rangeToRemove = date.range(of: " at") {  // Remove the time part of date (Only want [MM DD, YYYY] part)
                        date.removeSubrange(rangeToRemove.lowerBound ..< date.endIndex)
                    }
                    
                    // Get username
                    let username = ProfileDataCache.userIDToUsername![photo.userID] ?? "A"
                    
                    // Get profile photo
                    let profilePhoto = ProfileDataCache.userIDToProfilePhoto![photo.userID] ?? UIImage(named: "A")!
                    
                    // Construct PhotoCard object
                    self.photos.append(PhotoCard.init(profilePhoto: profilePhoto,
                                                      username: username,
                                                      date: date,
                                                      photo: photoToDisplay,
                                                      caption: photo.caption,
                                                      tags: photo.tags,
                                                      liked: photo.liked,
                                                      likeCount: photo.likeCount,
                                                      photoID: photo.photoID))
                }
                
                self.showLoadingCell = false
                self.newsfeedTableView.reloadData()
                self.newsfeedTableView.finishInfiniteScroll()
                
                if !firstTimeLoad {
                    self.tableViewRefreshControl.endRefreshing()
                }
            }
        }
    }
    
    func getRefereshView() {
        if let objOfRefreshView = Bundle.main.loadNibNamed("PullToRefreshView", owner: self, options: nil)?.first as? PullToRefresh {
            pullToRefresh = objOfRefreshView
            pullToRefresh!.frame = tableViewRefreshControl.frame
            tableViewRefreshControl.addSubview(pullToRefresh!)
        }
    }
    
    @objc func refreshNewsfeed() {
        if let pullToRefresh = pullToRefresh {
            pullToRefresh.startAnimation()
            getNewsfeedPhotos(false)
        }
    }
    
    private func getListOfFollowing() {
        if ProfileDataCache.userIDToUsername == nil { ProfileDataCache.userIDToUsername = [String: String]() }  // Initialize
        if ProfileDataCache.userIDToProfilePhoto == nil { ProfileDataCache.userIDToProfilePhoto = [String: UIImage]() }  // Initialize
        
        Api.findFollowers { (followingList, error) in
            if let _ = error {
                print("Error — Error when retrieving list of userIDs that the logged-in user is following.")
            }
            if let followingList = followingList {
                let listLength = followingList.count
                var usernamesFetched = 0
                var profilePhotosFetched = 0
                
                DispatchQueue.global(qos: .userInitiated).async {
                    while usernamesFetched + profilePhotosFetched < 2 * listLength { continue }  // Busy wait in background thread until all usernames & profile photos have been fetched
                    self.getNewsfeedPhotos(true)
                }
                
               
                for userID in followingList {
                    Api.getUserName(userID: userID, completion: { (username) in
                        ProfileDataCache.userIDToUsername![userID] = username
                        usernamesFetched = usernamesFetched + 1
                        
                        Api.getProfilePhotoWithUID(userID: userID, completion: { (url, error) in
                            if let _ = error {
                                print("Error — Error when retrieving profile photo url for userID: \(userID)")
                                ProfileDataCache.userIDToProfilePhoto![userID] = UIImage(named: String(username.capitalized.first!))
                                profilePhotosFetched = profilePhotosFetched + 1
                            }
                            if let url = url {
                                if url == "" {
                                    ProfileDataCache.userIDToProfilePhoto![userID] = UIImage(named: String(username.capitalized.first!))
                                    profilePhotosFetched = profilePhotosFetched + 1
                                } else {
                                    do {
                                        let url = URL(string: url)
                                        let data = try Data(contentsOf: url!)
                                        ProfileDataCache.userIDToProfilePhoto![userID] = UIImage(data: data)
                                        profilePhotosFetched = profilePhotosFetched + 1
                                    } catch {
                                        ProfileDataCache.userIDToProfilePhoto![userID] = UIImage(named: String(username.capitalized.first!))
                                        profilePhotosFetched = profilePhotosFetched + 1
                                    }
                                }
                            }
                        })
                    })
                }
            }
        }
    }
}

extension NewsfeedViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // https://hackernoon.com/swift-access-ios-camera-and-photo-library-dc1dbe0cdd76
    func camera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self;
            myPickerController.sourceType = .camera
            present(myPickerController, animated: true, completion: nil)
        }
    }
    
    func photoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self;
            myPickerController.sourceType = .photoLibrary
            present(myPickerController, animated: true, completion: nil)
        }
    }
    
    // https://stackoverflow.com/questions/28255789/getting-url-of-uiimage-selected-from-uiimagepickercontroller
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imgURL = (info[UIImagePickerController.InfoKey.imageURL] as? URL) {
            print("img url: ",imgURL)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let postPhotoVC = storyboard.instantiateViewController(withIdentifier: "postPhotoViewController") as! PostPhotoViewController
            // Pass photo to PostPhotoViewController
            let photo = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            postPhotoVC.photo = photo
            postPhotoVC.photoUrl = imgURL
            self.navigationController?.pushViewController(postPhotoVC, animated: true)
        }
        dismiss(animated: true, completion: nil)
    }
}
