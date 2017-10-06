//
//  Constants.swift
//  Trilly
//
//  Created by Daniel Soto on 9/25/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import Foundation
import Firebase
import Modals3A

struct Trilly {
    static let googleApiKey = "AIzaSyCaNTGg4ALjVFOxNqrLsOP1g-dYkyo5re8"
    static let newRelicKey = ""
    
    static func call() {
        guard let url = URL(string: "tel://\("3017303973")") else { return }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
            
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    struct UI {
        static let mainColor = UIColor(0x35ea93)
        static let alertColor: UIColor = UIColor(0xff0844)
        static let secondColor: UIColor = UIColor(0x1cdac6)
        static let contrastColor: UIColor = UIColor(0xffcd01)
        static let roundPx: CGFloat = 20.0
        static let specialRoundPx: CGFloat = 15.0
        static let lightRoundPx: CGFloat = 5.0
    }
    
    struct Database {
        public static func ref() -> DatabaseReference {
            return Firebase.Database.database().reference()
        }
        private static let storageURL: String = "gs://trilly-ab00c.appspot.com/"
        public static func storageRef() -> StorageReference {
            return Storage.storage().reference(forURL: storageURL)
        }
        struct Local {
            private static var data_cache: [String:Data] = [:]
            private static var model_cache: [String: AnyObject] = [:]
            
            public static func save(id: String, data: Data) {
                data_cache[id] = data
            }
            
            public static func getCache(_ id: String) -> Data? {
                return data_cache[id]
            }
            
            public static func saveModel(id: String, object: AnyObject) {
                model_cache[id] = object
            }
            
            public static func getModel(_ id: String) -> AnyObject? {
                return model_cache[id]
            }
            
            public static func clearModel(_ id: String) {
                model_cache.removeValue(forKey: id)
            }
        }
    }
}
