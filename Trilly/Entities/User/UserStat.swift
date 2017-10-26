//
//  UserStat.swift
//  Trilly
//
//  Created by Daniel Soto on 10/25/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase

class UserStat: TrillyObject {
    
    // Class variables
    static let collectionName = "stats"
    // Class methods
    
    // Type constructor
    class func statsFromUser(userID: String, callback: @escaping (_ s: [UserStat]?)->Void) {
        
        Trilly.Database.ref().collection(User.collectionName)
            .document(userID)
            .collection(collectionName)
            .getDocuments { (documents, error) in
                
                if error != nil {
                    print(error!.localizedDescription)
                } else if documents != nil {
                    var response: [UserStat] = []
                    for document in documents!.documents {
                        if document.exists {
                            response.append(UserStat(document.data()))
                        }
                    }
                    callback(response)
                } else {
                    callback(nil)
                }
        }
    }
    
    // Object fields
    var icon: String?
    var stat: Double?
    var descriptionT: String?
    
    // Constructor
    public override init(_ dict: [String: Any]){
        super.init(dict)
        
        if let icon = dict["icon"] as? String {
            self.icon = icon
        }
        if let stat = dict["stat"] as? Double {
            self.stat = stat
        }
        if let description = dict["description"] as? String {
            self.descriptionT = description
        }
    }
    
    // Saving functions
    public func saveToUser(_ id: String) {
        if self.icon != nil {
            originalDictionary["icon"] = self.icon
        }
        if self.stat != nil {
            originalDictionary["stat"] = self.stat
        }
        if self.descriptionT != nil {
            originalDictionary["description"] = self.descriptionT
        }
        
        super.save(route: "\(User.collectionName)/\(id)/\(UserStat.collectionName)")
    }
}
