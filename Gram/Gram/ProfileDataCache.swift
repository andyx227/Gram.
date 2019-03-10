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
    static var photosNoYetFetched: Bool = true // Initially, photos not yet fetched from Firebase
    static var userIDToUsername: [String: String]?
    static var userIDToProfilePhoto: [String: UIImage]?
}
