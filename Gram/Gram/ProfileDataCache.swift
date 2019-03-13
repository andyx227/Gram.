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
    static var CommunitiesJoined: [String]?
    static var loadedCommunityPhotos: [PhotoCard]?  // User's community photos
    static var communityChanged = false  // Set to true when user joins/deletes a community
}
