//
//  Api.swift
//  Gram
//
//  Created by Jacob Morris on 2/6/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

var user: Api.profileInfo?

struct Api {
    static var db = Firestore.firestore()
    static var storage = Storage.storage()
    
    struct profileInfo {
        var firstName : String
        var lastName : String
        var username : String
        var email : String
        var summary : String
        var userID : String
        var profilePhoto: String?
    }
    
    struct userInfo {
        var firstName : String
        var lastName : String
        var userName : String
        var userID : String
        var following : Bool
        var summary : String
        var profilePhoto: String?
    }
    
    struct photoURL {
        var URL : String
        var userID : String
        var datePosted : String
        var caption : String
        var tags : [String]?
        var liked : Bool
        var likeCount : Int
        var photoID : String
    }
    
    struct comment {
        var datePosted : String
        var userID : String
        var message : String
        var photoID : String
        var commentID : String
    }
    
    static func checkUserExists(username: String, completion: @escaping ApiCompletionURL) {
        let userNameCheck = db.collection("users").whereField("username", isEqualTo: username)
        userNameCheck.getDocuments { (querySnapshot, err) in
            if querySnapshot?.count != 0 {
                completion(nil, "username already exist")
            } else {
                completion("success", nil)
            }
        }
    }
    
    static func checkEmailExists(email: String, completion: @escaping ApiCompletionURL) {
        let emailCheck = db.collection("users").whereField("email", isEqualTo: email)
        emailCheck.getDocuments { (querySnapshot, err) in
            if querySnapshot?.count != 0 {
                completion(nil, "email already exist")
            } else {
                completion("success", nil)
            }
        }
    }
    
    static func signupUser(completion: @escaping ApiCompletionURL) {
        guard let user = user else {
            completion(nil,"Global user not set")
            return
        }
        let docData: [String:Any] = [
            "firstName" : user.firstName,
            "lastName" : user.lastName,
            "email" : user.email,
            "username" : user.username,
            "profilePhoto" : "",
            "communities" : []
        ]
        
        db.collection("users").document().setData(docData) { err in
            if let err = err as? String {
                completion(nil, err)
            }
            
            completion("success", nil)
        }
    }
    
    /**
     Takes in an authenticated user's email and sets up the appropriate global user variable
    */
    static func setUserWithEmail(email: String, completion: @escaping ApiCompletionURL) {
        
        let docRef = db.collection("users")
        let query = docRef.whereField("email", isEqualTo: email)
        
        query.getDocuments { (querySnapshot, error) in
            if let documents = querySnapshot?.documents {
                dump(documents)
                
                var docData = documents[0].data().mapValues { String.init(describing: $0)}
                let loadedProfile = Api.profileInfo.init(firstName: docData["firstName"] ?? "", lastName: docData["lastName"] ?? "", username: docData["username"] ?? "", email: docData["email"] ?? "", summary: docData["summary"] ?? "", userID: documents[0].documentID, profilePhoto: nil)
                user = loadedProfile
                Api.getProfilePhoto(completion: { (url, err) in
                    if err != nil {
                        print("Error setting profile photo url: \(err ?? "null")")
                    } else {
                        user?.profilePhoto = url
                    }
                })
                completion("success", nil)
            } else {
                completion(nil, "Error on retrieving user data")
            }
        }
    }
    
    /**
     Given a path to an image stored locally, upload the image to the logged in user and set the profile photo field as the url of the photo uploaded
    */
    static func uploadProfilePhoto(path: URL, completion: @escaping ApiCompletion){
        guard var user = user else {
            completion(nil, "User has not been set")
            return
        }
        let storageRef = storage.reference()

        let profileRef = storageRef.child("images/profilePhotos/" + user.userID)
        // Upload the file to the path
        profileRef.putFile(from: path , metadata: nil) { metadata, error in
            
            // You can also access to download URL after upload.
            profileRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    completion(nil, "An error has occurred obtaining profile photo url")
                    print(error?.localizedDescription ?? "error")
                    return
                }
                
                user.profilePhoto = url?.absoluteString
                
                db.collection("users").document(user.userID).setData(["profilePhoto": downloadURL.absoluteString], merge:true, completion: { (error) in
                    if let _ = error {
                        completion(nil, "An error occurred on set profile photo url")
                    } else {
                        completion(["response" : "success"], nil)
                    }
                })
            }
        }
    }
    
    /**
     Returns the url of the profile photo for the logged in user
    */
    static func getProfilePhoto(completion: @escaping ApiCompletionURL){
        guard let user = user else {
            completion(nil,"Global user not set")
            return
        }
        
        let docRef = db.collection("users").document(user.userID)
        
        docRef.getDocument { (document, error) in
            if document != nil {
                let docData = document?.data()?.mapValues { String.init(describing: $0)}
                completion((docData?["profilePhoto"] ?? ""), nil)
            } else {
                completion(nil, "Error retrieving for profile photo")
            }
        }
    }
    
    static func getProfilePhotoWithUID(userID: String, completion: @escaping ApiCompletionURL) {
        let docRef = db.collection("users").document(userID)
        
        docRef.getDocument { (document, error) in
            if error !=  nil {
                print("Error retrieving profile photo for user: \(userID)")
                completion(nil, "Error retrieving profile photo for user: \(userID)")
            } else {
                let docData = document?.data()?.mapValues { String.init(describing: $0)}
                completion((docData?["profilePhoto"] ?? ""), nil)
            }
        }
    }
    
    /**
     Post a photo and return the url of the photo uploaded.
     Returns empty url string on error
    */
    static func postPhoto(path: URL, photo: PhotoCard, completion: @escaping ApiCompletionURL) {
        guard let user = user else {
            completion(nil,"Global user not set")
            return
        }
        
        var photoURL : URL?
        
        DispatchQueue.global(qos: .userInitiated).async {
            // upload photo to storage
            
            let storageRef = storage.reference()
            
            let profileRef = storageRef.child("images/photos/" + randomString(length:20))
            let group = DispatchGroup()
            
            // Upload the file to the path
            group.enter()
            profileRef.putFile(from: path , metadata: nil) { metadata, error in
                
                // You can also access to download URL after upload.
                profileRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        completion(nil, "An error has occurred obtaining profile photo url")
                        print(error?.localizedDescription ?? "error")
                        return
                    }
                    
                    photoURL = downloadURL
                    group.leave()
                }
            }
        
            group.wait()
            
            DispatchQueue.main.async {
                // create photo document
                db.collection("photos").addDocument(data: [
                    "UID" : user.userID,
                    "caption" : photo.caption ?? "null",
                    "datePosted" : Timestamp(date: Date()),
                    "url" : photoURL?.absoluteString ?? "",
                    "tags" : photo.tags!]) { err in
                        if let err = err {
                            print("Error creating photo document: \(err)")
                            completion(nil, err as? String);
                        }
                }
                
                completion(photoURL?.absoluteString, nil)
            }
        }
    }
    
    static func postComment(message: String, pid: String, completion: @escaping ApiCompletionURL) {
        guard let user = user else {
            print("Global user not filled")
            completion(nil, "Global user not filled")
            return
        }
        
        db.collection("comments").addDocument(data: [
            "UID" : user.userID,
            "message" : message,
            "datePosted" : Timestamp(date: Date()),
            "PID" : pid]) { err in
                if let err = err {
                    print("Error creating comment document: \(err)")
                    completion(nil, err as? String);
                }
        }
        
        completion("success", nil)
    }
    
    static func getComments(pid: String, completion: @escaping ApiCompletionComments) {
        let docRef = db.collection("comments")
        let query = docRef.whereField("PID", isEqualTo: pid).order(by: "datePosted", descending: true)
        
        query.getDocuments { (querySnapshot, error) in
            if let documents = querySnapshot?.documents {
                var comments : [comment] = []
                
                for document in documents {
                    var docData = document.data().mapValues { String.init(describing: $0)}
                    var comment = self.comment.init(datePosted: docData["datePosted"] ?? "",
                                                    userID: docData["UID"] ?? "",
                                                    message: docData["message"] ?? "",
                                                    photoID: docData["PID"] ?? "",
                                                    commentID: document.documentID)
                    
                    let start = comment.datePosted.index(comment.datePosted.startIndex, offsetBy: 22)
                    let end = comment.datePosted.index(comment.datePosted.endIndex, offsetBy: -23)
                    let range = start..<end
                    let sec = Double(String(comment.datePosted[range])) //get sec from substring
                    let interval = TimeInterval(exactly: sec ?? 0)// time interval of sec in seconds
                    let date = Date(timeIntervalSince1970: interval!) // get time from 1970
                    let dateString = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium) //make date nice and localized
                    comment.datePosted = dateString
                    
                    comments.append(comment)
                }
                
                completion(comments, nil)
            } else if error != nil{
                completion(nil, "Error occurred retrieving comments: \(error.debugDescription)")
            }
        }
    }
    
    /**
    Return the photos of the current logged in user in reverse chronological order
    */
    static func getProfilePhotos(userID: String, completion: @escaping ApiCompletionPhotos) {
        let docRef = db.collection("photos")
        let query = docRef.whereField("UID", isEqualTo: userID).order(by: "datePosted", descending: true)
        
        query.getDocuments { (querySnapshot, error) in
            if let documents = querySnapshot?.documents {
                var photos : [photoURL] = []
                for document in documents {
                    var docData = document.data().mapValues { String.init(describing: $0)}
                    var photo = photoURL(URL: docData["url"] ?? "",
                                         userID: docData["UID"] ?? "",
                                         datePosted: docData["datePosted"] ?? "",
                                         caption: docData["caption"] ?? "",
                                         tags: extractTags(text: docData["tags"] ?? ""),
                                         liked: false,
                                         likeCount: 0,
                                         photoID: document.documentID)
                    
                    let start = photo.datePosted.index(photo.datePosted.startIndex, offsetBy: 22)
                    let end = photo.datePosted.index(photo.datePosted.endIndex, offsetBy: -23)
                    let range = start..<end
                    let sec = Double(String(photo.datePosted[range])) //get sec from substring
                    let interval = TimeInterval(exactly: sec ?? 0)// time interval of sec in seconds
                    let date = Date(timeIntervalSince1970: interval!) // get time from 1970
                    let dateString = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium) //make date nice and localized
                    photo.datePosted = dateString
                    
                    photos.append(photo)
                }
                
                completion(photos, nil)
            } else if error != nil{
                completion(nil, "Error occurred retrieving profile photos: \(error.debugDescription)")
            }
        }
    }
    
    /**
     used to generate a unique string for an image
    */
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"  // No lower case 'L' or upper case "I" because it's ambiguous
        return String((0...length-1).map{ _ in letters.randomElement()! })
    }
    
    static func getUserName(userID: String, completion: @escaping ApiCompletionUserID) {
        let docRef = db.collection("users").document(userID)
        docRef.getDocument { (document, error) in
            guard let document = document else {
                return
            }
            
            let docData = document.data()?.mapValues { String.init(describing: $0)}
            completion(docData?["username"] ?? "")
        }
    }
    
    static func getFollowerPhotos(completion: @escaping ApiCompletionPhotos) {
        
        findFollowers { (users, error) in
            if error != nil {
                print("An error occurred finding followers")
                completion(nil, "An error occurred getting follower photos \(error ?? "nil")")
            }
            
            let docRef = db.collection("photos").order(by: "datePosted", descending: true)
            docRef.getDocuments(completion: { (querySnapshot, error) in
                if error != nil {
                    print("An error occurred retrieving all photos: \(error?.localizedDescription ?? "")")
                    completion(nil, "An error occurred retrieving all photos: \(error?.localizedDescription ?? "")")
                }
                
                var photos : [photoURL] = []
                if let documents = querySnapshot?.documents {
                    for document in documents {
                        var docData = document.data().mapValues { String.init(describing: $0)}
                        if users?.contains(docData["UID"] ?? "") ?? false {
                            var photo = photoURL(URL: docData["url"] ?? "",
                                                 userID: docData["UID"] ?? "",
                                                 datePosted: docData["datePosted"] ?? "",
                                                 caption: docData["caption"] ?? "",
                                                 tags: extractTags(text: docData["tags"] ?? ""),
                                                 liked: false,
                                                 likeCount: 0,
                                                 photoID: document.documentID)
                            
                            let start = photo.datePosted.index(photo.datePosted.startIndex, offsetBy: 22)
                            let end = photo.datePosted.index(photo.datePosted.endIndex, offsetBy: -23)
                            let range = start..<end
                            let sec = Double(String(photo.datePosted[range])) //get sec from substring
                            let interval = TimeInterval(exactly: sec ?? 0)// time interval of sec in seconds
                            let date = Date(timeIntervalSince1970: interval!) // get time from 1970
                            let dateString = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium) //make date nice and localized
                            photo.datePosted = dateString
                            
                            photos.append(photo)
                        }
                    }
                    
                    likeInfo(photos: photos, completion: completion)
                } else {
                    print("error type:")
                    dump(error!)
                    completion(nil, "Collection does not exist")
                }
                
            })
            
        }
    }
    
    static func extractTags(text: String) -> [String]{
        let tagString = String(text.replacingOccurrences(of: " ", with: "")
                                   .replacingOccurrences(of: " ", with: "")
                                   .replacingOccurrences(of: "(", with: "")
                                   .replacingOccurrences(of: ")", with: "")
                                   .replacingOccurrences(of: ",", with: "")
                                   .dropFirst().dropLast())
        let tags = tagString.components(separatedBy: "\n")
        
        return tags
    }
    
    /**
     takes userID as arguement, defaults to current user
     returns dictionary of number of users followed and following the specified user
     */
    static func followCounts(userID: String? = nil, completion: @escaping ApiCompletion) {
        var id = userID ?? ""
        if id == "" {
            id = user!.userID
        }
        
        let docRef = db.collection("followers")
        let query = docRef.whereField("followerID",isEqualTo: id)
        
        query.getDocuments { (querySnapshot, error) in
            if let followedDocuments = querySnapshot?.documents {
                let followedCount = followedDocuments.count
                
                let docRef = db.collection("followers")
                let query = docRef.whereField("followingID",isEqualTo: id)
                
                query.getDocuments { (querySnapshot, error) in
                    if let followersDocuments = querySnapshot?.documents {
                        let followersCount = followersDocuments.count
                        completion(["followed" : followedCount, "followers" : followersCount], nil)
                    } else {
                        print("error type:")
                        dump(error!)
                        completion(nil, "Collection does not exist")
                    }
                }
            } else {
                print("error type:")
                dump(error!)
                completion(nil, "Collection does not exist")
            }
        }
    }
    
    /**
     takes two userIDs, the logged in user and the user to
     follow. maybe check if already following and if so
     unfollow the user to follow
    */
    static func followUser(followingID: String, following : Bool, completion: @escaping ApiCompletion) {
        //TODO: potentially store doc ID (that is, our UserID)
        //for the users queried in the search as well as
        //the primary user
        let followerID = user!.userID
        if following {
            let docRef = db.collection("followers")
            //query where name starts with the input info
            let query = docRef.whereField("followerID",isEqualTo: followerID).whereField("followingID", isEqualTo: followingID)
            
            query.getDocuments { (querySnapshot, error) in
                if let documents = querySnapshot?.documents {
                    if documents.count == 0 {
                        completion(nil, "User was not following")
                    }
                    db.collection("followers").document(documents[0].documentID).delete()
                    completion(["response": "good"], nil)
                } else {
                    print("error type:")
                    dump(error!)
                    completion(nil, "Collection does not exist")
                }
            }
            
        } else {
            let docData = ["followerID": followerID, "followingID": followingID]
            db.collection("followers").document().setData(docData) { err in
                if let err = err as? String {
                    completion(nil, err)
                }
                
                completion(["response": "good"], nil)
            }
        }
        
    }
    
    /**
     take a search string as arguement, like match equivalent
     for the search string used
     takes userID of user doing search to determine if searched users are followed
     by the searchee
     Returns a list of user structs? should contain user info and whether or not
     they are being followed by user
    */
    static func searchUsers(name: String, completion: @escaping ApiCompletionUserList) {
        //TODO: use array contains function to check if
        //supplied name is a substring
        let docRef = db.collection("users")
        //query where name starts with the input info
        let query = docRef.whereField("username", isGreaterThan: name).whereField("username", isLessThan: name + "z").order(by: "username", descending: true)
        
        query.getDocuments { (querySnapshot, error) in
            if let documents = querySnapshot?.documents {
                var users : [userInfo] = []
                for document in documents {
                    var docData = document.data().mapValues { String.init(describing: $0)}
                    //unwrap into user object, potentially
                    //if if fields empty
                    let currUser = userInfo(firstName: docData["firstName"] ?? "", lastName: docData["lastName"] ?? "", userName: docData["username"] ?? "", userID: document.documentID, following: false, summary : docData["summary"] ?? "", profilePhoto : docData["profilePhoto"])
                    //append user object to list of
                    //users that satisfy search requirement
                    users.append(currUser)
                }
                
                findFollowers() { (userIDs, error) in
                    if let userIDs = userIDs {
                        for followingID in userIDs {
                            for index in 0 ..< users.count {
                                if users[index].userID == followingID {
                                    users[index].following = true
                                }
                            }
                        }
                        completion(users, nil)
                    } else {
                        dump(error)
                        completion(nil, "Error: could not operate on follower collection")
                    }
                }
            } else {
                print("error type:")
                dump(error!)
                completion(nil, "Collection does not exist")
            }

        }
    }
    /**
     Takes a userID as arguement
     returns all userIDs being followed by the given user
    */
    static func findFollowers(completion : @escaping ApiCompletionUserIDs) {
        let userID = user!.userID
        let docRef = db.collection("followers")
        let query = docRef.whereField("followerID", isEqualTo: userID)
        query.getDocuments { (querySnapshot, error) in
            if let documents = querySnapshot?.documents {
                dump(documents)
                var userIDs : [String] = []
                for document in documents {
                    var docData = document.data().mapValues { String.init(describing: $0)}
                    //unwrap into user object, potentially
                    //if if fields empty
                    if let followingID = docData["followingID"] {
                        userIDs.append(followingID)
                    }
                }
                completion(userIDs, nil)
            } else {
                print("error type:")
                dump(error!)
                completion(nil, "Collection does not exist")
            }
            
        }
    }
    
    static func likeInfo(photos: [photoURL], completion : @escaping ApiCompletionPhotos) {
        let group = DispatchGroup()
        var photos = photos
        // Upload the file to the path
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0 ..< photos.count {
                group.enter()
                likeCount(postID: photos[i].photoID, postType: "photo") { (likes, err) in
                    if let likes = likes {
                        photos[i].likeCount = likes
                    }
                    
                    group.leave()
                }
                
                group.enter()
                isLiked(postID: photos[i].photoID, postType: "photo") { (liked, err) in
                    if let liked = liked {
                        photos[i].liked = liked
                    }
                    
                    group.leave()
                }
            }
            print("waiting for the group")
            group.wait()
            print("leaving for completion")
            DispatchQueue.main.async {
                completion(photos, nil)
            }
        }
    }
    
    /**
     Creates a like entry with for a post, expecting the post id and post type (a string) as argument
     If a like between the user and post already exists, the like is deleted
    */
    static func likePost(postID : String, postType : String, completion : @escaping ApiCompletion) {
        let userID = user!.userID
        let docRef = db.collection("likes")
        let query = docRef.whereField("postID", isEqualTo: postID).whereField("postType", isEqualTo: postType).whereField("userID", isEqualTo: userID)
        query.getDocuments { (querySnapshot, error) in
            if let documents = querySnapshot?.documents {
                if documents.count == 0 {
                    let postData = ["postID" : postID, "postType" : postType, "userID" : userID]
                    docRef.document().setData(postData)
                    completion(["response" : "success"], nil)
                } else {
                    docRef.document(documents[0].documentID).delete()
                    completion(["response" : "success"], nil)
                }
            } else {
                print("error type:")
                dump(error!)
                completion(nil, "Collection does not exist")
            }
        }
    }
    
    
    
    /**
     Gets the total likes on a post, expecting the post id and post type (a string) as argument
     */
    static func likeCount(postID : String, postType : String, completion : @escaping ApiCompletionInt) {
        let docRef = db.collection("likes")
        let query = docRef.whereField("postID", isEqualTo: postID).whereField("postType", isEqualTo: postType)
        query.getDocuments { (querySnapshot, error) in
            if let documents = querySnapshot?.documents {
                completion(documents.count, nil)
            } else {
                print("error type:")
                dump(error!)
                completion(nil, "Collection does not exist")
            }
        }
    }
    
    /**
     Gets whether or not user has liked a post
    */
    static func isLiked(postID : String, postType : String, completion : @escaping ApiCompletionBool) {
        let userID = user!.userID
        let docRef = db.collection("likes")
        let query = docRef.whereField("postID", isEqualTo: postID).whereField("postType", isEqualTo: postType).whereField("userID", isEqualTo: userID)
        query.getDocuments { (querySnapshot, error) in
            if let documents = querySnapshot?.documents {
                if documents.count == 0 {
                    completion(false, nil)
                } else {
                    docRef.document(documents[0].documentID).delete()
                    completion(true, nil)
                }
            } else {
                print("error type:")
                dump(error!)
                completion(nil, "Collection does not exist")
            }
        }
    }
    
    
    /**
     Updates the firestore user object with changable fields
     (not including profile photo)
     Expects that the global user object is being changed and
     uses it for the update
    */
    static func updateUser(completion : @escaping ApiCompletion) {
        guard let user = user else {
            completion(nil,"Global user not set")
            return
        }
        
        let docData: [String:Any] = [
            "firstName" : user.firstName,
            "lastName" : user.lastName,
            "username" : user.username,
            "summary" : user.summary
        ]
        
        let docRef = db.collection("users").document(user.userID)
        
        docRef.updateData(docData) { err in
            if let _ = err {
                completion(nil, "Could not update data")
            } else {
                completion(["response" : "success"], nil)
            }
            
        }
    }
    
    /**
     Takes a string as arguement and returns photos that have a tag
     that matches the input string
     */
    static func searchTags(tag: String, completion: @escaping ApiCompletionPhotos) {
        
        let docRef = db.collection("photos").order(by: "datePosted", descending: true).whereField("tags", arrayContains: tag)
        docRef.getDocuments { (querySnapshot, error) in
            if error != nil {
                print("An error occurred retrieving all photos: \(error?.localizedDescription ?? "")")
                completion(nil, "An error occurred retrieving all photos: \(error?.localizedDescription ?? "")")
            }
            
            var photos : [photoURL] = []
            if let documents = querySnapshot?.documents {
                for document in documents {
                    var docData = document.data().mapValues { String.init(describing: $0)}
                    var photo = photoURL(URL: docData["url"] ?? "",
                                         userID: docData["UID"] ?? "",
                                         datePosted: docData["datePosted"] ?? "",
                                         caption: docData["caption"] ?? "",
                                         tags: extractTags(text: docData["tags"] ?? ""),
                                         liked: false,
                                         likeCount: 0,
                                         photoID: document.documentID)
                    
                    let start = photo.datePosted.index(photo.datePosted.startIndex, offsetBy: 22)
                    let end = photo.datePosted.index(photo.datePosted.endIndex, offsetBy: -23)
                    let range = start..<end
                    let sec = Double(String(photo.datePosted[range])) //get sec from substring
                    let interval = TimeInterval(exactly: sec ?? 0)// time interval of sec in seconds
                    let date = Date(timeIntervalSince1970: interval!) // get time from 1970
                    let dateString = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium) //make date nice and localized
                    photo.datePosted = dateString
                    
                    photos.append(photo)
                }
                
                likeInfo(photos: photos, completion: completion)
            } else {
                print("error type:")
                dump(error!)
                completion(nil, "Collection does not exist")
            }
        }
    }
    
    static func getUser(email : String, completion : @escaping ApiCompletion) {
        
    }
    
    typealias ApiCompletion = ((_ response: [String: Any]?, _ error: String?) -> Void)
    typealias ApiCompletionList = ((_ response: [[String: Any]]?, _ error: String?) -> Void)
    typealias ApiCompletionUserList = ((_ response: [userInfo]?, _ error: String?) -> Void)
    typealias ApiCompletionUserID = ((_ response: String) -> Void)
    typealias ApiCompletionUserIDs = ((_ response: [String]?, _ error: String?) -> Void)
    typealias ApiCompletionURL = ((_ response: String?, _ error: String?) -> Void)
    typealias ApiCompletionInt = ((_ response: Int?, _ error: String?) -> Void)
    typealias ApiCompletionPhotos = ((_ response: [photoURL]?, _ error: String?) -> Void)
    typealias ApiCompletionBool = ((_ response: Bool?, _ error: String?) -> Void)
    typealias ApiCompletionComments = ((_ response: [comment]?, _ error: String?) -> Void)
}

