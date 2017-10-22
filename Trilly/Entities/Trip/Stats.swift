//
//  Stats.swift
//  Trilly
//
//  Created by Daniel Soto on 10/22/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation

class Stats: TrillyObject {
    
    // Class variables
    
    // Class methods
    
    // Object fields
    var km: Double?
    var co2: Double?
    var gas: Double?
    var cal: Double?
    
    // Constructor
    public override init(_ dict: [String: Any]){
        super.init(dict)
        
        if let km = dict["km"] as? Double {
            self.km = km
        }
        if let co2 = dict["co2"] as? Double {
            self.co2 = co2
        }
        if let gas = dict["gas"] as? Double {
            self.gas = gas
        }
        if let cal = dict["cal"] as? Double {
            self.cal = cal
        }
    }
    
    // Reference functions
    
    public func prepareForSave() -> [String:Any] {
        if self.km != nil {
            originalDictionary["km"] = self.km
        }
        if self.co2 != nil {
            originalDictionary["co2"] = self.co2
        }
        if self.gas != nil {
            originalDictionary["gas"] = self.gas
        }
        if self.cal != nil {
            originalDictionary["cal"] = self.cal
        }
        
        return originalDictionary
    }
}
