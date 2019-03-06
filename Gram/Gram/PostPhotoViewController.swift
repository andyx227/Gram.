//
//  PostPhotoViewController.swift
//  Gram
//
//  Created by Andy Xue on 2/22/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit
import MultilineTextField

class PostPhotoViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var caption: MultilineTextField!
    @IBOutlet weak var photoHeightConstraint: NSLayoutConstraint!
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
        guard let imgUrl = photoUrl else {
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
        
        let tags = extractTags(caption.text)  // Get tags from the photo caption
        
        // Format the date (want something like [Jan 2, 2019])
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "MMM dd, yyyy"
        let formattedDate = format.string(from: date)

        let photoCard = PhotoCard.init(profilePhoto: UIImage(named: "A")!,  // Won't be using profilePhoto so this won't matter
                                       username: user!.username,
                                       date: formattedDate,  // Don't need to pass in date, Firebase will take care of that
                                       photo: photoToPost,
                                       caption: photoCaption.text,
                                       tags: tags)
        
        if ProfileDataCache.loadedPhotos == nil {
            ProfileDataCache.loadedPhotos = [PhotoCard]()  // Initialize
        }
        ProfileDataCache.loadedPhotos!.insert(photoCard, at: 0)  // Prepend PhotoCard to array saved in cache
        ProfileDataCache.newPost = true
        
        Api.postPhoto(path: imgUrl, photo: photoCard) { (url, error) in
            if let _ = error {
                self.presentAlertPopup(withTitle: "Something went wrong!", withMessage: "Could not upload your photo. Please try again.")
                return
            }
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    /**** Helper Functions Below ****/

    private func formatCaption(_ caption: String) -> NSAttributedString {
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
        
        // Set attribute to actual caption
        let attributedCaptionString = NSMutableAttributedString()
        
        // Tokenize photo caption, delimited by whitespace
        let tokenized_caption = caption.components(separatedBy: " ")
        var attributedToken: NSAttributedString
        for token in tokenized_caption {
            if token.contains("#") {  // Hashtags should be in blue
                attributedToken = NSAttributedString(string: token, attributes: hashtagAttributes)
                if tags == nil { tags = [] }  // Initialize "tags" array if nil
                tags!.append(token)  // Save tags (NOTE: each tag includes the # symbol!)
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
