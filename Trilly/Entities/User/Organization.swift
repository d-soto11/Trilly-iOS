//
//  Organization.swift
//  Trilly
//
//  Created by Daniel Soto on 10/22/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase

class Organization: TrillyObject {
    
    // Class variables
    static let collectionName = "organizations"
    // Class methods
    
    // Type constructor
    class func withID(id: String, callback: @escaping (_ s: Organization?)->Void) {
        Trilly.Database.ref().collection(collectionName).document(id).getDocument { (document, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else if document != nil && document!.exists {
                if let documentData = document?.data() {
                    callback(Organization(documentData))
                } else {
                    callback(nil)
                }
            } else {
                callback(nil)
            }
        }
    }
    
    // Object fields
    var name: String?
    var users: [String]?
    var qr: String?
    // Cahce fields
    
    // Constructor
    public override init(_ dict: [String: Any]){
        super.init(dict)
        
        if let name = dict["name"] as? String {
            self.name = name
        }
        if let users = dict["users"] as? [String] {
            self.users = users
        }
        if let qr = dict["qr"] as? String {
            self.qr = qr
        }
    }
    
    // Reference functions
    public func reference() -> DocumentReference {
        return Trilly.Database.ref().collection(Organization.collectionName).document(uid!)
    }
    
    public func users(_ callback: @escaping ([User]?)->Void) {
        if self.users != nil {
            var max = self.users!.count
            var response: [User] = []
            for userID in self.users! {
                User.withID(id: userID, callback: { (user) in
                    if user != nil {
                        response.append(user!)
                        if response.count == max {
                            callback(response)
                        }
                    } else {
                        max = max - 1
                        self.users!.remove(object: userID)
                    }
                })
            }
        } else {
            callback(nil)
        }
    }
    
    // Saving functions
    public func save() {
        if self.name != nil {
            originalDictionary["name"] = self.name
        }
        if self.users != nil {
            originalDictionary["users"] = self.users
        }
        if self.qr != nil {
            originalDictionary["qr"] = self.qr
        }
        
        super.save(route: Organization.collectionName)
    }
}

