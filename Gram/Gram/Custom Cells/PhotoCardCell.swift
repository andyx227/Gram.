//
//  PhotoCardCell.swift
//  Gram
//
//  Created by Andy Xue on 2/9/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import Foundation
import UIKit
import ActiveLabel

protocol photoCardCellDelegate {
    func likePressed(_ sender: PhotoCardCell)
    func commentPressed(_ sender: PhotoCardCell)
}

class PhotoCardCell: UITableViewCell {
    
    @IBOutlet weak var profilePhoto: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var photoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var caption: ActiveLabel!
    @IBOutlet weak var btnLike: UIButton!
    @IBOutlet weak var lblNumLikesNumComments: UILabel!
    var photoID: String!
    var likeCount: Int!
    
    var delegate: photoCardCellDelegate?
   
    @IBAction func likePhoto(_ sender: Any) {  // Or "unlike" if user already liked
        delegate?.likePressed(self)
    }
    
    @IBAction func commentPhoto(_ sender: Any) {
        delegate?.commentPressed(self)
    }
}
