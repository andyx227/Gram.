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
    func didChangeFollowStatus(_ sender: ProfileInfoCell)
}

class ProfileInfoCell: UITableViewCell {
    
    @IBOutlet weak var profilePhoto: UIImageView!
    @IBOutlet weak var fullname: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var bio: UILabel!
    @IBOutlet weak var changeFollowStatus: UIButton!
    @IBOutlet weak var followingIcon: UIImageView!
    var userID: String = ""
    var isFollowing: Bool = false  // Always assume not following first
    var delegate: ProfileInfoCellDelegate?
    
    /**
     * Allows logged-in user to follow/unfollow another user.
     * This function is connected to a button that will only show up when viewing
     * another user's profile (i.e. you cannot follow/unfollow yourself).
     */
    @IBAction func changeFollowStatus(_ sender: Any) {
        delegate?.didChangeFollowStatus(self)
    }
}
