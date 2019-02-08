//
//  Api.swift
//  Gram
//
//  Created by Jacob Morris on 2/6/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct Api {
    static var db = Firestore.firestore()
    
    struct profileInfo {
        var firstName : String
        var lastName : String
        var email : String
    }
    
    static func signupUser(user:profileInfo, completion: @escaping ApiCompletion) {
        let docData: [String:Any] = [
            "firstName" : user.firstName,
            "lastName" : user.lastName,
            "email" : user.email,
            "profilePhoto" : "",
            "communities" : []
        ]
        
        db.collection("users").document().setData(docData) { err in
            if let err = err as? String {
                completion(nil, err)
            }
            
            completion(["response": "good"], nil)
        }
    }
    
    /**
     takes two userIDs, the logged in user and the user to
     follow. maybe check if already following and if so
     unfollow the user to follow
    */
    static func followUser(follower: String, following: String, completion: @escaping ApiCompletion) {
        //TODO: potentially store doc ID (that is, our UserID)
        //for the users queried in the search as well as
        //the primary user
    }
    
    /**
     take a search string as arguement, like match equivalent
     for the search string used
     Returns a list of user structs? should contain user info
    */
    static func searchUsers(name: String, completion: @escaping ApiCompletionList) {
        //TODO: use array contains function to check if
        //supplied name is a substring
        let docRef = db.collection("users")
        let query = docRef.whereField("username", isGreaterThan: name).whereField("username", isLessThan: name + "z").order(by: "username", descending: true)
        
        query.getDocuments { (querySnapshot, error) in
            if let documents = querySnapshot?.documents {
                var allDocs : [[String : Any]] = []
                dump(documents)
                dump(allDocs)
                for document in documents {
                    allDocs.append(document.data().mapValues { String.init(describing: $0)
                        
                    })
                } //add all documents to a dictionary of dictionaries
                //key is the name of the document (good for iterating through location
                completion(allDocs, nil)
            } else {
                print("error type:")
                dump(error!)
                completion(nil, "Collection does not exist")
            }

        }
    }
    
    
    typealias ApiCompletion = ((_ response: [String: Any]?, _ error: String?) -> Void)
    typealias ApiCompletionList = ((_ response: [[String: Any]]?, _ error: String?) -> Void)
}
