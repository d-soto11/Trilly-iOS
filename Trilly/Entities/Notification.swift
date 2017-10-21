//
//  Notification.swift
//  Trilly
//
//  Created by Daniel Soto on 9/27/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation

class Notification: TrillyObject {
    
    var type: Int?
    
    
    public override init(_ dict: [String : Any]) {
        super.init(dict)
        
        if let type = dict["type"] as? Int {
            self.type = type
        }
    }
    
    
    
}
