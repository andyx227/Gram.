//
//  ProfileDataCache.swift
//  Gram
//
//  Created by Andy Xue on 2/23/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import Foundation
import UIKit

struct ProfileDataCache {
    static var profilePhoto: UIImage?
    static var loadedPhotos: [PhotoCard]?  // Photos of logged-in user
    static var clean: Bool = false  // Assume cache is dirty first
}
