//
//  HomeViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 9/27/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import MaterialTB
import Modals3A
import Firebase
import MBProgressHUD

class HomeViewController: MaterialViewController {

    @IBOutlet weak var forestView: UIView!
    @IBOutlet weak var profileB: UIButton!
    @IBOutlet weak var tripB: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        Auth.auth().addStateDidChangeListener { auth, user in
            if user != nil {
                // User is signed in.
                // Save user
                User.withID(id: User.current?.uid ?? "nil", callback: {(user) in
                    if user == nil {
                        // Register data and save
                    } else {
                        User.current = user!
                        // Load Cache
                        // Reload view data
                        // Check for notifications
                        if let token = Firebase.Messaging.messaging().fcmToken {
                            User.current!.saveNotificationToken(token: token)
                        }
                        if User.current!.blocked ?? false {
                            Alert3A.show(withTitle: "Lo sentimos", body: "Tu cuenta ha sido bloqueada por seguridad.", accpetTitle: "Llamar a Trilly", confirmation: {() in
                                Trilly.call()
                            }, parent: MaterialTB.currentTabBar!, persistent: true)
                        }
                    }
                })
            } else {
                // No user is signed in.
                MaterialTB.currentTabBar!.performSegue(withIdentifier: "Login", sender: nil)
            }
            
            let _ = self.tripB.addGradientBackground(Trilly.UI.mainColor, Trilly.UI.secondColor, horizontal: true)
            
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        self.tripB.roundCorners(radius: Trilly.UI.lightRoundPx)
        self.tripB.bordered(color: Trilly.UI.mainColor)
    }
    

    @IBAction func goToProfile(_ sender: Any) {
        
    }
    
    @IBAction func startTrip(_ sender: Any) {
        TripViewController.startTrip()
    }
    
    override func refreshViewController() -> MaterialViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Home") as! MaterialViewController
    }
    
}
