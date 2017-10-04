//
//  TripViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 9/28/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import GoogleMaps
import MaterialTB
import Modals3A
import CoreLocation
import MBProgressHUD

class TripViewController: UIViewController, TripListener {

    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var hashtagLabel: UILabel!
    @IBOutlet weak var endTripB: UIButton!
    @IBOutlet weak var overlay: UIView!
    @IBOutlet weak var infoBackground: UIView!
    @IBOutlet weak var kmLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    private var trackingPolyline: GMSPolyline!
    private var overlayAdded: Bool = false
    
    private var hud: MBProgressHUD?
    
    public class func startTrip() {
        let st = UIStoryboard(name: "Trip", bundle: nil)
        let vc = st.instantiateViewController(withIdentifier: "Trip") as! TripViewController
        MaterialTB.currentTabBar!.show(vc, sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 16)
        mapView.animate(to: camera)
        mapView.animate(toViewingAngle: 45)
        mapView.isMyLocationEnabled = true
        
        trackingPolyline = GMSPolyline()
        trackingPolyline.strokeColor = Trilly.UI.mainColor
        trackingPolyline.strokeWidth = 10
        
        if TripManager.current != nil {
            TripManager.current!.registerTripListener(self)
        } else {
            TripManager.start(self)
        }
    }
    
    override func viewDidLayoutSubviews() {
        self.infoBackground.addNormalShadow()
        
        if !overlayAdded {
            overlayAdded = true
            self.overlay.addGradientBackground(UIColor(white: 1, alpha: 0), .white, start: 0.5)
            self.overlay.addGradientBackground(.white, UIColor(white: 1, alpha: 0), start: 0.07, end: 0.5)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        TripManager.current!.clearTripListener()
    }
    
    @IBAction func endTrip(_ sender: Any) {
        TripManager.current!.stop()
        self.showAlert(title: "Felicitaciones", message: "Hemos guardado tu viaje de hoy en bici. Estamos procesando tu información para que veas cuánto has aportado al medio ambiente y a tu ciudad.", closeButtonTitle: "Genial")
    }
    
    // Tracking
    func tripUpdated(path: GMSPath) {
        mapView.clear()
        trackingPolyline.path = path
        trackingPolyline.map = mapView
        self.mapView.animate(toLocation: TripManager.current!.location!)
        self.kmLabel.text = String(format: "%.0f Km", path.length(of: GMSLengthKind.rhumb)/1000)
        
        if hud != nil {
            UIView.animate(withDuration: 0.3, animations: {
                self.infoBackground.alpha = 1
            }, completion: { (comp) in
                self.hud!.hide(animated: true)
            })
        }
        
    }
    
    func headingUpdated(heading: CLLocationDirection) {
        self.mapView.animate(toBearing: heading)
    }
    
    func noLocation() {
        hud?.hide(animated: true)
        hud = nil
        self.showAlert(title: "Lo sentimos", message: "No hemos podido recibir tu ubicación. Revisa que tengas el GPS prendido y que hayas autorizado a Trilly para usarlo.", closeButtonTitle: "OK")
    }
    
    func tripPaused(message: String, path: GMSPath) {
        Alert3A.show(withTitle: "Viaje en pausa", body: message, accpetTitle: "Continuar viaje", cancelTitle: "Terminar", confirmation: {
            TripManager.resume(self)
        }, cancelation: {
            // Save paused path to firebase and clean encoded path
            TripManager.clear()
        }, parent: self)
    }
    
    func tripStoped(message: String, path: GMSPath) {
        self.showAlert(title: "Viaje terminado", message: message, closeButtonTitle: "Aceptar")
    }
    
    func timeTick(_ time: Int) {
        self.timeLabel.text = String(format: "%02d:%02d:%02d", (time/3600), ((time%3600) / 60), (time%3600) % 60)
    }
    
    func hashtagUpdated(_ hashtag: String) {
        self.hashtagLabel.text = "\(hashtag.lowercased())"
    }

}
