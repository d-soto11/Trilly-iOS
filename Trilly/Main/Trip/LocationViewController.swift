//
//  LocationViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 10/25/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import GoogleMaps
import MaterialTB
import MBProgressHUD

class LocationViewController: UIViewController {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var overlay: UIView!
    @IBOutlet weak var startTripB: UIButton!
    @IBOutlet weak var backB: UIButton!
    
    public class func showLocation(location: CLLocationCoordinate2D, title: String = "Ubicación recibida", onViewController: UIViewController? = nil) {
        let lcVC = UIStoryboard(name: "Trip", bundle: nil).instantiateViewController(withIdentifier: "Location") as! LocationViewController
        lcVC.location = location
        lcVC.locationHint = title
        if onViewController == nil {
            MaterialTB.currentTabBar!.show(lcVC, sender: nil)
        } else {
            onViewController!.show(lcVC, sender: nil)
        }
        
    }
    
    private var location: CLLocationCoordinate2D!
    private var locationHint: String!
    
    private var overlayAdded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MBProgressHUD.showAdded(to: self.overlay, animated: true)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        mapView.animate(toZoom: 16)
        mapView.animate(toLocation: self.location)
        mapView.isMyLocationEnabled = true
        
        let marker = GMSMarker(position: self.location)
        marker.snippet = locationHint
        marker.map = self.mapView
        
        MBProgressHUD.hide(for: self.overlay, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        if !overlayAdded {
            overlayAdded = true
            self.overlay.addGradientBackground(UIColor(white: 1, alpha: 0), .white, start: 0.4, end: 0.8)
            self.overlay.addGradientBackground(.white, UIColor(white: 1, alpha: 0), start: 0.07, end: 0.5)
        }
        self.startTripB.addGradientBackground(Trilly.UI.mainColor, Trilly.UI.secondColor, horizontal: true)
        self.startTripB.addNormalShadow()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startTrip(_ sender: Any) {
        
        TripViewController.startTrip(location: self.location, onViewController: self)
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
