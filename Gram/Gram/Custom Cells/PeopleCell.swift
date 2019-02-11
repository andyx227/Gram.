//
//  PeopleCell.swift
//  Gram
//
//  Created by Andy Xue on 2/10/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import Foundation
import UIKit

class PeopleCell: UITableViewCell {
    @IBOutlet weak var fullname: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var followingIcon: UIImageView!  // By default icon is hidden! This icon means that current logged-in user is following the given person
}
