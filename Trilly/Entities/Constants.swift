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
    static let googleApiKey = "AIzaSyBmR69_Jqzy7Tyw68Qp4SBhdEKV_mhc94E"
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
        static let secondContrastColor: UIColor = UIColor(0xff6f89)
        static let roundPx: CGFloat = 20.0
        static let specialRoundPx: CGFloat = 15.0
        static let lightRoundPx: CGFloat = 5.0
    }
    
    struct Database {
        public static func ref() -> Firestore {
            return Firestore.firestore()
        }
        private static let storageURL: String = "gs://trilly-3a.appspot.com"
        public static func storageRef() -> StorageReference {
            return Storage.storage().reference(forURL: storageURL)
        }
        struct Local {
            private static var dataCache: NSCache<NSString, AnyObject> = NSCache<NSString, AnyObject>()
            
            public static func save(id: String, data: AnyObject) {
                dataCache.setObject(data as AnyObject, forKey: id as NSString)
            }
            
            public static func get(_ id: String) -> AnyObject? {
                return dataCache.object(forKey: id as NSString)
            }
            
            public static func clear(_ id: String) {
                dataCache.removeObject(forKey: id as NSString)
            }
            
            public static func delete() {
                dataCache.removeAllObjects()
            }
        }
    }
}
