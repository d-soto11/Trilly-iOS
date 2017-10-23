//
//  Tree.swift
//  Trilly
//
//  Created by Daniel Soto on 10/22/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase

class Tree: TrillyObject {
    
    // Class variables
    static let collectionName = "trees"
    // Class methods
    
    // Type constructor
    class func withID(id: String, callback: @escaping (_ s: Tree?)->Void) {
        Trilly.Database.ref().collection(collectionName).document(id).getDocument { (document, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else if document != nil && document!.exists {
                if let documentData = document?.data() {
                    callback(Tree(documentData))
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
    var date: NSDate?
    // Cahce fields
    
    // Constructor
    public override init(_ dict: [String: Any]){
        super.init(dict)
        
        if let name = dict["name"] as? String {
            self.name = name
        }
        if let date = dict["date"] as? NSDate {
            self.date = date
        }
    }
    
    // Reference functions
    
    
    // Saving functions
    public func save() {
        if self.name != nil {
            originalDictionary["name"] = self.name
        }
        if self.date != nil {
            originalDictionary["date"] = self.date
        }
        
        super.save(route: Tree.collectionName)
    }
}
