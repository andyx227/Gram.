//
//  PostPhotoViewController.swift
//  Gram
//
//  Created by Andy Xue on 2/22/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit
import MultilineTextField
import NVActivityIndicatorView

class PostPhotoViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var caption: MultilineTextField!
    @IBOutlet weak var photoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var loadingIndicator: NVActivityIndicatorView!
    @IBOutlet weak var postButton: UIButton!
    var photo: UIImage?
    var photoUrl: URL?
    var tags: [String]?
    

    override func viewWillAppear(_ animated: Bool) {
        changeStatusBarColor(forView: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboard()
        
        // Load photo into ImageView
        if let photo = photo {
            // Scale photos before displaying them in UIImageView
            let ratio = photo.getCropRatio()
            photoHeightConstraint.constant = UIScreen.main.bounds.width / ratio
            imageView.image = photo
        }
        
        caption.delegate = self
    }
    
    @IBAction func btnBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnPost(_ sender: Any) {
        guard let _ = photoUrl else {
            presentAlertPopup(withTitle: "Something went wrong!", withMessage: "Could not upload your photo. Please try again.")
            return
        }
        guard let photoToPost = photo else {
            presentAlertPopup(withTitle: "Something went wrong!", withMessage: "Could not upload your photo. Please try again.")
            return
        }
        guard let photoCaption = caption else {
            presentAlertPopup(withTitle: "Something went wrong!", withMessage: "Could not upload your photo. Please try again.")
            return
        }
        
        loadingIndicator.isHidden = false // Show loading indicator
        loadingIndicator.startAnimating()
        postButton.isEnabled = false  // Don't allow user to press "Post" button again
        postButton.alpha = 0.5
        
        let compressedPhoto = photoToPost.jpegData(compressionQuality: 0.1)  // Compress photo
        guard let compressedPhotoData = compressedPhoto else {
            loadingIndicator.isHidden = true // HIde loading indicator
            loadingIndicator.stopAnimating()
            postButton.isEnabled = true  // Allow user to press "Post" button again
            postButton.alpha = 1.0
            presentAlertPopup(withTitle: "Something went wrong!", withMessage: "Could not upload your photo. Please try again.")
            return
        }
        
        guard let compressedPhotoToPost = UIImage(data: compressedPhotoData) else {
            loadingIndicator.isHidden = true // HIde loading indicator
            loadingIndicator.stopAnimating()
            postButton.isEnabled = true  // Allow user to press "Post" button again
            postButton.alpha = 1.0
            presentAlertPopup(withTitle: "Something went wrong!", withMessage: "Could not upload your photo. Please try again.")
            return
        }
        
        // Get a temp url to compressed photo
        guard let urlWhereCompressedImageIsSaved = compressedPhotoToPost.saveToTempDir(compressedPhotoData) else {
            loadingIndicator.isHidden = true // HIde loading indicator
            loadingIndicator.stopAnimating()
            postButton.isEnabled = true  // Allow user to press "Post" button again
            postButton.alpha = 1.0
            presentAlertPopup(withTitle: "Something went wrong!", withMessage: "Could not upload your photo. Please try again.")
            return
        }
        
        let tags = extractTags(caption.text)  // Get tags from the photo caption
        
        // Format the date (want something like [Jan 2, 2019])
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "MMM dd, yyyy"
        let formattedDate = format.string(from: date)

        let photoCard = PhotoCard.init(profilePhoto: UIImage(named: "A")!,  // Won't be using profilePhoto so this won't matter
                                       username: user!.username,
                                       date: formattedDate,  // Don't need to pass in date, Firebase will take care of that
                                       photo: compressedPhotoToPost,
                                       caption: photoCaption.text,
                                       tags: tags,
                                       liked: false,
                                       likeCount: 0,
                                       photoID: "null")  // photoID will be updated from Api call down below!
        
        Api.postPhoto(path: urlWhereCompressedImageIsSaved, photo: photoCard) { (photoID, error) in
            if let _ = error {
                self.presentAlertPopup(withTitle: "Something went wrong!", withMessage: "Could not upload your photo. Please try again.")
            }
            if let photoID = photoID {
                var uploadedPhotoCard = photoCard
                uploadedPhotoCard.photoID = photoID  // Save the photo ID
                if ProfileDataCache.photosNoYetFetched == false {  // Photos have been fetched and saved in cache, so prepend uploaded photo into the "loadedPhotos" array in cache
                    ProfileDataCache.loadedPhotos!.insert(uploadedPhotoCard, at: 0)  // Prepend PhotoCard to array saved in cache
                }
            }
            
            self.navigationController?.popViewController(animated: true)
            // Finally, remove compressed image from user's phone
            let fm = FileManager()
            do {
                try fm.removeItem(at: urlWhereCompressedImageIsSaved)
            } catch {
                print("Error — Could not delete compressed image from user's phone!")
            }
        }
    }
    
    /**** Helper Functions Below ****/
    
    private func extractTags(_ caption: String) -> [String] {
        var tags = [String]()
        // Tokenize photo caption, delimited by whitespace
        let tokenized_caption = caption.components(separatedBy: " ")

        for token in tokenized_caption {
            if token.contains("#") {  // Hashtags should be in blue
                var tag = token
                tag.remove(at: token.startIndex)  // Remove hashtag symbol at beginning of tag word
                tags.append(tag)
            }
        }
        
        return tags
    }

}
