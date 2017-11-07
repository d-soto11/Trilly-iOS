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
import GoogleMaps

class HomeViewController: MaterialViewController {

    @IBOutlet weak var forestView: UIView!
    @IBOutlet weak var profileB: UIButton!
    @IBOutlet weak var tripB: UIButton!
    @IBOutlet weak var inboxB: UIButton!
    @IBOutlet weak var nextTree: UILabel!
    
    private var badge: UILabel?
    
    private var animationPercentaje = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        Auth.auth().addStateDidChangeListener { auth, user in
            if user != nil {
                // User is signed in.
                // Save user
                User.withID(id: user!.uid, callback: {(user) in
                    if user == nil {
                        // Register data and save
                    } else {
                        User.current = user!
                        // Load Cache
                        // Reload view data
                        self.reloadUserData()
                        // Check for notifications
                        if let token = Firebase.Messaging.messaging().fcmToken {
                            User.current!.saveNotificationToken(token: token)
                        }
                        if User.current!.blocked ?? false {
                            Alert3A.show(withTitle: "Lo sentimos", body: "Tu cuenta ha sido bloqueada por seguridad.", accpetTitle: "Llamar a Trilly", confirmation: {() in
                                Trilly.call()
                            }, persistent: true)
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
    
    override func viewDidAppear(_ animated: Bool) {
        if TripManager.current != nil {
            self.tripB.setTitle("Trilly está encendido", for: .normal)
        }
    }
    
    func reloadUserData() {
        User.current!.inbox { (inbox, count) in
            if inbox != nil && count > 0 {
                self.badge = UILabel()
                self.badge!.translatesAutoresizingMaskIntoConstraints = false
                self.badge!.backgroundColor = Trilly.UI.contrastColor
                self.badge!.text = "\(count)"
                self.badge!.textColor = .white
                self.badge!.textAlignment = .center
                self.badge!.roundCorners(radius: 10)
                self.inboxB.clipsToBounds = false
                self.inboxB.addSubview(self.badge!)
                
                let c1 = NSLayoutConstraint(item: self.badge!, attribute: .centerX, relatedBy: .equal, toItem: self.inboxB, attribute: .trailing, multiplier: 1, constant: 0)
                let c2 = NSLayoutConstraint(item: self.badge!, attribute: .centerY, relatedBy: .equal, toItem: self.inboxB, attribute: .top, multiplier: 1, constant: 0)
                let c3 = NSLayoutConstraint(item: self.badge!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
                let c4 = NSLayoutConstraint(item: self.badge!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
                
                self.inboxB.addConstraints([c1, c2, c3, c4])
            }
        }
        
        Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(animatePercentage), userInfo: nil, repeats: false)
        
//        let goal = Goal([:])
//        goal.achieved = false
//        goal.descriptionT = "Trilly junto con la alcaldía pintara esta calle para hacer un carril con prioridad para bicicletas. ¿Quiers hacer tu via más segura?"
//        goal.name = "Pintar la calle"
//        goal.points = 5000
//        goal.saveOnHashtag("bogota")
//        goal.saveOnHashtag("cupertino")
//
    }
    
    @objc public func animatePercentage() {
        if animationPercentaje < (User.current!.nextTree ?? 0) {
            animationPercentaje += 0.01
            self.nextTree.text = String(format: "%.0f%%", animationPercentaje*100)
            Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(animatePercentage), userInfo: nil, repeats: false)
        }
    }
    

    @IBAction func goToProfile(_ sender: Any) {
        ProfileViewController.showProfile()
    }
    
    @IBAction func goToInbox(_ sender: Any) {
        self.badge?.removeFromSuperview()
        self.badge = nil
        InboxViewController.showInbox(MaterialTB.currentTabBar!)
    }
    
    @IBAction func startTrip(_ sender: Any) {
        TripViewController.startTrip()
    }
    
    override func refreshViewController() -> MaterialViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Home") as! MaterialViewController
    }
    
}
