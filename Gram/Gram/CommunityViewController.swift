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
        
        communityTableView.delegate = self
        communityTableView.dataSource = self
        
        viewNoPhotos.isHidden = false  // Initially, show "no photos" message
    }
    
    override func viewWillAppear(_ animated: Bool) {
        changeStatusBarColor(forView: self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if photos.isEmpty && showLoadingCell {
            return 1  // Display the loading cell only, so return 1 cell
        } else if photos.isEmpty {
            return 0
        } else {
            return photos.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showLoadingCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "loadingCell", for: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "photoCardCell", for: indexPath)
            return cell
        }
    }
    
    @IBAction func searchCommunity(_ sender: Any) {
        var searchText = communitySearchBar.text ?? ""
        
        if searchText.isEmpty && photos.isEmpty {
            viewNoPhotos.isHidden = false // Show "no photos" message
            return
        } else if searchText.isEmpty {
            return
        }
        
        if searchText.first! == "#" { searchText.removeFirst() }  // Remove hashtag symbol
        
        searchText = searchText.lowercased()  // No capital letters!
        
        self.communityTableView.reloadData()  // Show loading cell by reloading table
        
        // Search for community photos
        getCommunityPhotos(searchText)
    }

    func getCommunityPhotos(_ tag: String) {
        Api.searchTags(tag: tag) { (photos, error) in
            if let _ = error {
                print("Error — Error occurred when retrieving photos by hashtag: \(tag)")
            }
            if let photos = photos {
                self.photos.removeAll()  // Start from clean slate
                
                for photo in photos {
                    var errorProfilePhotoRetrieval = false
                    var errorPhotoRetrieval = false
                    var photoToDisplayInPhotoCard: UIImage?
                    var profilePhoto: UIImage?
                    var username: String?
                    
                    let group = DispatchGroup()
                    DispatchQueue.global(qos: .userInitiated).async {
                        group.enter()
                        do {  // Attempt to extract the photo from the given photo url
                            let url = URL(string: photo.URL)
                            guard let photoURL = url else {
                                errorPhotoRetrieval = true
                                group.leave()
                                return
                            }
                            let data = try Data(contentsOf: photoURL)
                            photoToDisplayInPhotoCard = UIImage(data: data)
                        } catch {
                            errorPhotoRetrieval = true
                        }
                        group.leave()
                    }
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        group.enter()
                        Api.getUserName(userID: photo.userID, completion: { (usrname) in
                            username = usrname  // Grab username
                            
                            Api.getProfilePhotoWithUID(userID: photo.userID, completion: { (url, error) in
                                if let _ = error {
                                    print("Error — Error when retrieving profile photo of user with ID: \(photo.userID)")
                                    errorProfilePhotoRetrieval = true
                                    group.leave()
                                    return
                                }
                                if let url = url {
                                    if url == "" {
                                        profilePhoto = UIImage(named: String(username!.capitalized.first!))!
                                    } else {
                                        do {  // Attempt to extract the photo from the given photo url
                                            let url = URL(string: url)
                                            guard let photoURL = url else {
                                                errorProfilePhotoRetrieval = true
                                                group.leave()
                                                return
                                            }
                                            let data = try Data(contentsOf: photoURL)
                                            profilePhoto = UIImage(data: data)!
                                        } catch {
                                            errorProfilePhotoRetrieval = true
                                        }
                                        group.leave()
                                    }
                                }
                            })  // Api.getProfilePhotoWithUID()
                        })  // Api.getUserName()
                    }
                    
                    group.wait()  // Wait until background tasks complete
                    
                    if errorPhotoRetrieval { continue }  // If error when loading photo, try loading another photo card (skip this one)
                    guard let photoToDisplay = photoToDisplayInPhotoCard else { continue }  // If cannot load photo, skip this PhotoCard
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
                
                self.showLoadingCell = false
                self.communityTableView.reloadData()
                
                if photos.isEmpty {
                    self.viewNoPhotos.isHidden = false
                }
            }
        }
    }

}

