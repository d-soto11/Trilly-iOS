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
    
    public init(_ dict: [String: AnyObject]) {
        original_dictionary = dict
        
        if let uid = dict["id"] {
            self.uid = (uid as? String)!
        }
        
    }
    
    public func save(route: String) {
        if uid == nil {
            let saving_ref = Trilly.Database.ref().child(route).childByAutoId()
            original_dictionary["id"] = saving_ref.key as AnyObject
            saving_ref.setValue(original_dictionary)
            uid = saving_ref.key
        } else {
            original_dictionary["id"] = uid as AnyObject
            Trilly.Database.ref().child(route).child(uid!).setValue(original_dictionary)
        }
    }
    
    var original_dictionary: [String:AnyObject]
    var uid: String?
    
}
