//
//  UserContribution.swift
//  Trilly
//
//  Created by Daniel Soto on 10/22/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase

class UserContribution: TrillyObject {
    
    // Class variables
    static let collectionName = "users"
    // Class methods
    
    // Type constructor
    class func withID(id: String, relativeTo hashtag: String, callback: @escaping (_ s: UserContribution?)->Void) {
        let path = "\(Hashtag.collectionName)/\(hashtag.lowercased().folding(options: .diacriticInsensitive, locale: .current))/\(collectionName)/\(id)"
        Trilly.Database.ref().document(path).getDocument { (document, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else if document != nil && document!.exists {
                if let documentData = document?.data() {
                    callback(UserContribution(documentData))
                } else {
                    callback(nil)
                }
            } else {
                callback(nil)
            }
        }
    }
    
    class func usersFromHashtag(hashtagID: String, callback: @escaping (_ s: [UserContribution]?)->Void) {
        
        Trilly.Database.ref().collection(Hashtag.collectionName)
            .document(hashtagID.lowercased().folding(options: .diacriticInsensitive, locale: .current))
            .collection(collectionName)
            .order(by: "points", descending: true)
            .getDocuments { (documents, error) in
                
                if error != nil {
                    print(error!.localizedDescription)
                } else if documents != nil {
                    var response: [UserContribution] = []
                    for document in documents!.documents {
                        if document.exists {
                            response.append(UserContribution(document.data()))
                        }
                    }
                    callback(response)
                } else {
                    callback(nil)
                }
        }
    }
    
    // Object fields
    var name: String?
    var points: Double?
    var km: Double?
    // Constructor
    public override init(_ dict: [String: Any]){
        super.init(dict)
        
        if let name = dict["name"] as? String {
            self.name = name
        }
        if let points = dict["points"] as? Double {
            self.points = points
        }
        if let km = dict["km"] as? Double {
            self.km = km
        }
    }
    
    // Saving functions
    public func saveOnHashtag(_ id: String) {
        guard self.name != nil else { return }
        if self.name != nil {
            originalDictionary["name"] = self.name
        }
        if self.points != nil {
            originalDictionary["points"] = self.points
        }
        if self.km != nil {
            originalDictionary["km"] = self.km
        }
        
        super.save(route: "\(Hashtag.collectionName)/\(id.lowercased().folding(options: .diacriticInsensitive, locale: .current))/\(UserContribution.collectionName)")
    }
}
