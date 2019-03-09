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

class CommentViewController: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var commentTableView: UITableView!
    @IBOutlet weak var commentTextField: MultilineTextField!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var profilePhotoCurrentUser: UIImageView!
    var comments = [Comment]()
    var photoID: String?  // Photo id of photo to show comments for
    var showLoadingCell = true
    
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
        
        profilePhotoCurrentUser.image = ProfileDataCache.profilePhoto!
        
        if let photoID = photoID {
            getComments(photoID)
        }
    }

    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
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
                            
                            // Construct comment object
                            self.comments.append(Comment.init(date: comment.datePosted,
                                                              username: username,
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
