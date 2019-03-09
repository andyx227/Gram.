//
//  SecondViewController.swift
//  Gram
//
//  Created by Andy Xue on 1/24/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit

class CommunityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var viewNoPhotos: UILabel!
    @IBOutlet weak var communityTableView: UITableView!
    @IBOutlet weak var communitySearchBar: UISearchBar!
    var photos = [PhotoCard]()
    var showLoadingCell = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboard()
        communityTableView.delegate = self
        communityTableView.dataSource = self
        communityTableView.isHidden = true  // Hide table initially since no photos to show
        communitySearchBar.delegate = self
        communitySearchBar.autocapitalizationType = .none
        
        viewNoPhotos.isHidden = false  // Initially, show "no photos" message
    }
    
    override func viewWillAppear(_ animated: Bool) {
        changeStatusBarColor(forView: self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if photos.isEmpty && showLoadingCell {
            return 1  // Display the loading cell only, so return 1 cell
        } else if photos.isEmpty {
            communityTableView.isHidden = true  // Hide table
            viewNoPhotos.isHidden = false  // Show message
            return 0
        } else {
            communityTableView.isHidden = false  // Show table
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
            
            return cell
        }
    }
    
    @IBAction func searchCommunity(_ sender: Any) {
        var searchText = communitySearchBar.text ?? ""
        
        if searchText.isEmpty && photos.isEmpty {  // No photos to show and there is no search text
            communityTableView.isHidden = true  // Hide table
            viewNoPhotos.isHidden = false // Show "no photos" message
            return
        } else if searchText.isEmpty {  // No search text, so don't do anything
            return
        }
        
        if searchText.first! == "#" { searchText.removeFirst() }  // Remove hashtag symbol
        searchText = searchText.lowercased()  // No capital letters!
        
        communityTableView.isHidden = false
        viewNoPhotos.isHidden = true
        showLoadingCell = true
        photos.removeAll()
        self.communityTableView.reloadData()  // Show loading cell by reloading table
        
        // Search for community photos
        getCommunityPhotos(searchText)
    }
    
    // User clicked "Search" button on keyboard; has same behavior as clicking the "checkmark" button
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        var searchText = communitySearchBar.text ?? ""
        
        if searchText.isEmpty && photos.isEmpty {  // No photos to show and there is no search text
            communityTableView.isHidden = true  // Hide table
            viewNoPhotos.isHidden = false // Show "no photos" message
            return
        } else if searchText.isEmpty {  // No search text, so don't do anything
            return
        }
        
        if searchText.first! == "#" { searchText.removeFirst() }  // Remove hashtag symbol
        searchText = searchText.lowercased()  // No capital letters!
        
        communityTableView.isHidden = false
        viewNoPhotos.isHidden = true
        showLoadingCell = true
        photos.removeAll()
        self.communityTableView.reloadData()  // Show loading cell by reloading table
        
        // Search for community photos
        getCommunityPhotos(searchText)
        communitySearchBar.resignFirstResponder()  // Hide the keyboard
    }

    func getCommunityPhotos(_ tag: String) {
        Api.searchTags(tag: tag) { (photosInCommunity, error) in
            if let _ = error {
                print("Error — Error occurred when retrieving photos by hashtag: \(tag)")
            }
            if let photosInCommunity = photosInCommunity {
                self.photos.removeAll()  // Start from clean slate
                var photosProcessed = 0
                
                for photo in photosInCommunity {
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
                        photosProcessed += 1
                        
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
                                                          photoID: photo.photoID))
                    }
                }  // For()
                
                DispatchQueue.global(qos: .userInitiated).async {
                    while photosProcessed < photosInCommunity.count { continue }  // Busy wait until all photos processed (using Dispatch Group will hang program!)
                    self.showLoadingCell = false
                    DispatchQueue.main.async {
                        self.communityTableView.reloadData()
                    }
                }
            }
        }
    }

}

