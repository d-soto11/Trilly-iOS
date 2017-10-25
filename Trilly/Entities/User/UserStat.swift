//
//  UserStat.swift
//  Trilly
//
//  Created by Daniel Soto on 10/25/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase

class HashtagPoints: TrillyObject {
    
    // Class variables
    static let collectionName = "hashtags"
    // Class methods
    
    // Type constructor
    class func withID(id: String, relativeTo user: String, callback: @escaping (_ s: HashtagPoints?)->Void) {
        let path = "\(User.collectionName)/\(user)/\(collectionName)/\(id)"
        Trilly.Database.ref().document(path).getDocument { (document, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else if document != nil && document!.exists {
                if let documentData = document?.data() {
                    callback(HashtagPoints(documentData))
                } else {
                    callback(nil)
                }
            } else {
                callback(nil)
            }
        }
    }
    
    class func pointsFromUser(userID: String, callback: @escaping (_ s: [HashtagPoints]?)->Void) {
        
        Trilly.Database.ref().collection(User.collectionName)
            .document(userID)
            .collection(collectionName)
            .getDocuments { (documents, error) in
                
                if error != nil {
                    print(error!.localizedDescription)
                } else if documents != nil {
                    var response: [HashtagPoints] = []
                    for document in documents!.documents {
                        if document.exists {
                            response.append(HashtagPoints(document.data()))
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
    public func saveToUser(_ id: String) {
        guard self.name != nil else { return }
        originalDictionary["name"] = self.name
        
        if self.points != nil {
            originalDictionary["points"] = self.points
        }
        if self.km != nil {
            originalDictionary["km"] = self.km
        }
        
        self.uid = self.name!
        
        super.save(route: "\(User.collectionName)/\(id)/\(HashtagPoints.collectionName)")
    }
}
