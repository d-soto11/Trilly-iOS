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
import Modals3A

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
        marker.icon = GMSMarker.markerImage(with: Trilly.UI.mainColor)
        
        if Trilly.Network.offline {
            Alert3A.show(withTitle: "Sin conexión", body: "No tienes conexión disponible para mostrarte la ubicación y que Trilly te lleve. Intenta regresar más tarde.", accpetTitle: "Entendido", confirmation: {
                self.back(self)
            })
        } else {
            GMSGeocoder().reverseGeocodeCoordinate(self.location!, completionHandler: { (response, error) in
                if error != nil {
                    print("Error getting hashtag from MAPS")
                } else {
                    if let address = response?.firstResult() {
                        DispatchQueue.main.async {
                            MBProgressHUD.hide(for: self.overlay, animated: true)
                            marker.snippet = (address.lines ?? ["Dirección recibida"])[0]
                            marker.title = self.locationHint
                            marker.map = self.mapView
                            self.mapView.selectedMarker = marker
                        }
                    } else {
                        print("Error getting hashtag from MAPS")
                    }
                    
                }
            })
        }
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
        
        TripViewController.startTrip(location: self.location, locationText: self.locationHint, onViewController: self)
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
