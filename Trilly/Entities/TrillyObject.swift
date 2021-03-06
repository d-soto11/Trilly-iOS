//
//  TrillyObject.swift
//  Trilly
//
//  Created by Daniel Soto on 9/27/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase

class TrillyObject: NSObject {
    
    // Trilly object fields
    var originalDictionary: [String:Any]
    var uid: String?
    
    // Constructor
    public init(_ dict: [String: Any]) {
        originalDictionary = dict
        
        if let uid = dict["id"] as? String {
            self.uid = uid
        }
    }
    
    public func save(route: String) {
        if uid == nil {
            let saving_ref = Trilly.Database.ref().collection(route).addDocument(data: originalDictionary)
            uid = saving_ref.documentID
            saving_ref.updateData(["lastUpdated": FieldValue.serverTimestamp(), "id": uid!])
        } else {
            originalDictionary["id"] = uid!
            Trilly.Database.ref().collection(route).document(uid!).setData(self.originalDictionary, options: SetOptions.merge())
            Trilly.Database.ref().collection(route).document(self.uid!).updateData(["lastUpdated": FieldValue.serverTimestamp()])
        }
    }
    
}
