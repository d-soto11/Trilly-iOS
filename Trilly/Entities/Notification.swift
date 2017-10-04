//
//  Notification.swift
//  Trilly
//
//  Created by Daniel Soto on 9/27/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation

class Notification: TrillyObject {
    public override init(_ dict: [String : AnyObject]) {
        super.init(dict)
        
        if let type = dict["type"] {
            self.type = (type as? Int)
        }
    }
    
    var type: Int?
    
}
