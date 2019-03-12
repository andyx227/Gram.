//
//  CommentViewController.swift
//  Gram
//
//  Created by Andy Xue on 3/5/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit
import MultilineTextField

struct Comment {
    var date: String
    var username: String
    var comment: String
    var commentID: String
    var profilePhoto: UIImage
}

protocol CommentViewControllerDelegate {
    func commentPosted(_ indexPath: IndexPath)
}

class CommentViewController: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var commentTableView: UITableView!
    @IBOutlet weak var commentTextField: MultilineTextField!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var profilePhotoCurrentUser: UIImageView!
    @IBOutlet weak var btnPost: UIButton!
    var comments = [Comment]()
    var photoID: String?  // Photo id of photo to show comments for
    var showLoadingCell = true
    var delegate: CommentViewControllerDelegate?
    var indexPathOfPhotoCard: IndexPath!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Adjusts the TextView's frame based on its content
        let contentSize = self.commentTextField.sizeThatFits(self.commentTextField.bounds.size)
        var frame = self.commentTextField.frame
        frame.size.height = contentSize.height
        self.commentTextField.frame = frame
        let aspectRatioTextViewConstraint = NSLayoutConstraint(item: self.commentTextField,
                                                               attribute: .height,
                                                               relatedBy: .equal,
                                                               toItem: self.commentTextField,
                                                               attribute: .width,
                                                               multiplier: commentTextField.bounds.height/commentTextField.bounds.width,
                                                               constant: 1)
        self.commentTextField.addConstraint(aspectRatioTextViewConstraint)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeStatusBarColor(forView: self)
        hideKeyboard()
        commentTableView.delegate = self
        commentTableView.dataSource = self
        commentTextField.delegate = self
        
        // Disable the "Post" button initially
        btnPost.isEnabled = false
        btnPost.alpha = 0.5
        
        // Set profile photo to be round
        profilePhotoCurrentUser.layer.cornerRadius = profilePhotoCurrentUser.frame.height / 2
        profilePhotoCurrentUser.clipsToBounds = true
        profilePhotoCurrentUser.image = ProfileDataCache.profilePhoto!
        
        // Use dyanamic cell height
        commentTableView.rowHeight = UITableView.automaticDimension
        commentTableView.estimatedRowHeight = 200
        
        if let photoID = photoID {
            getComments(photoID)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            btnPost.isEnabled = false
            btnPost.alpha = 0.5
        } else {
            btnPost.isEnabled = true
            btnPost.alpha = 1.0
        }
    }
    

    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func postComment(_ sender: Any) {
        // Format the date (want something like [Jan 2, 2019])
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "MMM d, yyyy"
        let formattedDate = format.string(from: date)
        
        if let photoID = photoID, let comment = commentTextField.text {
            Api.postComment(message: comment, pid: photoID) { (response, error) in
                if let _ = error {
                    print("Error — Error when posting comment for photo with photoID: \(photoID)")
                }
                if let _ = response {
                    self.comments.append(Comment.init(date: formattedDate,
                                                 username: "@" + user!.username,
                                                 comment: comment,
                                                 commentID: "",
                                                 profilePhoto: ProfileDataCache.profilePhoto!))
                    
                    // Insert comment into CommentTableView
                    self.commentTableView.beginUpdates()
                    self.commentTableView.insertRows(at: [IndexPath(row: self.comments.count - 1, section: 0)], with: .automatic)
                    self.commentTableView.endUpdates()
                    // Auto scroll to bottom of table, where the new comment is located
                    self.commentTableView.scrollToRow(at: IndexPath(row: self.comments.count - 1, section: 0), at: .bottom, animated: true)
                    
                    self.commentTextField.text = ""  // Reset TextView
                    
                    // If we are updating photos cards in the ProfileViewController,
                    // then update the PhotoCards stored inside the cache directly
                    if self.delegate is ProfileTableViewController {
                        ProfileDataCache.loadedPhotos?[self.indexPathOfPhotoCard.row - 1].commentCount += 1
                    } else {
                        self.delegate?.commentPosted(self.indexPathOfPhotoCard)
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if comments.isEmpty && showLoadingCell {
            return 1  // Show loading cell so return 1 cell
        } else {
            return comments.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showLoadingCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "loadingCell", for: indexPath) as! LoadingCell
            cell.loadingIndicator.startAnimating()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! CommentCell
            
            // Make profile photo round
            cell.profilePhoto.layer.cornerRadius = cell.profilePhoto.frame.height / 2
            cell.profilePhoto.clipsToBounds = true
            cell.profilePhoto.image = comments[indexPath.row].profilePhoto
            
            cell.lblUsername.text = comments[indexPath.row].username
            cell.lblDate.text = comments[indexPath.row].date
            cell.lblComment.text = comments[indexPath.row].comment
            return cell
        }
    }
    
    private func getComments(_ photoID: String) {
        Api.getComments(pid: photoID) { (commentsList, error) in
            if let _ = error {
                print("Error — Error when retrieving comments for photo with photoID: \(photoID)")
            }
            if let commentsList = commentsList {
                var profilePhoto: UIImage?
                
                for comment in commentsList {
                    Api.getUserName(userID: comment.userID, completion: { (username) in
                        Api.getProfilePhotoWithUID(userID: comment.userID, completion: { (url, error) in
                            if let _ = error {
                                profilePhoto = UIImage(named: String(username.capitalized.first!))
                            }
                            if let url = url {
                                if url == "" {
                                    profilePhoto = UIImage(named: String(username.capitalized.first!))
                                } else {
                                    do {
                                        let url = URL(string: url)
                                        let data = try Data(contentsOf: url!)
                                        profilePhoto = UIImage(data: data)
                                    } catch {
                                        profilePhoto = UIImage(named: String(username.capitalized.first!))
                                    }
                                }
                            }
                            
                            // Format upload date for this photo
                            var commentDate = comment.datePosted
                            if let rangeToRemove = commentDate.range(of: " at") {  // Remove the time part of date (Only want [MM DD, YYYY] part)
                                commentDate.removeSubrange(rangeToRemove.lowerBound ..< commentDate.endIndex)
                            }
                            
                            // Construct comment object
                            self.comments.append(Comment.init(date: commentDate,
                                                              username: "@" + username,
                                                              comment: comment.message,
                                                              commentID: comment.commentID,
                                                              profilePhoto: profilePhoto!))
                        })
                    })
                }  // for()
                
                DispatchQueue.global(qos: .userInitiated).async {
                    while self.comments.count < commentsList.count { continue }  // Busy wait until all comments have been processed
                    
                    DispatchQueue.main.async {
                        self.showLoadingCell = false
                        self.commentTableView.reloadData()
                    }
                }
            }
        }
    }
}
