//
//  PhotoInfoCell.swift
//  Gram
//
//  Created by Andy Xue on 2/8/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import Foundation
import UIKit

protocol ProfileInfoCellDelegate {
    func navigateToEditProfileViewController()
    func didChangeFollowStatus(_ sender: ProfileInfoCell)
    func logout()
}

class ProfileInfoCell: UITableViewCell {
    
    @IBOutlet weak var profilePhoto: UIImageView!
    @IBOutlet weak var fullname: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var bio: UILabel!
    @IBOutlet weak var changeFollowStatus: UIButton!
    @IBOutlet weak var logout: UIButton!
    @IBOutlet weak var followingIcon: UIImageView!
    @IBOutlet weak var numFollowers: UILabel!
    @IBOutlet weak var numFollowing: UILabel!
    var userID: String = ""
    var isFollowing: Bool = false  // Always assume not following first
    var delegate: ProfileInfoCellDelegate?
    
    /**
     * When looking at user's own profile, pressing
     * the button will allow user to edit their profile.
     *
     * When looking at another user's profile, logged-in
     * user can follow/unfollow that user by pressing
     * the button.
     */
    @IBAction func buttonPressed(_ sender: Any) {
        if userID == user?.userID {  // Viewing our own profile
            delegate?.navigateToEditProfileViewController()
        } else {  // Viewing another user's profile
            delegate?.didChangeFollowStatus(self)
        }
    }
    @IBAction func logout(_ sender: Any) {
        delegate?.logout()
    }
}
