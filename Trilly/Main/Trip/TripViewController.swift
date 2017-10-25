//
//  TripViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 9/28/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import MaterialTB
import Modals3A
import CoreLocation
import MBProgressHUD

class TripViewController: UIViewController, TripListener, UITextFieldDelegate, GMSAutocompleteViewControllerDelegate {
    
    @IBOutlet weak var hashtagLabel: UILabel!
    @IBOutlet weak var endTripB: UIButton!
    @IBOutlet weak var overlay: UIView!
    @IBOutlet weak var infoBackground: UIView!
    @IBOutlet weak var kmLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var destinationTextField: UITextField!
    
    private var trackingPolyline: GMSPolyline!
    private var routePolyline: GMSPolyline?
    private var overlayAdded: Bool = false
    
    private var hud: MBProgressHUD?
    private var mapView: GMSMapView!
    private var paused = false
    
    public class func startTrip(location: CLLocationCoordinate2D? = nil, onViewController: UIViewController? = nil) {
        let st = UIStoryboard(name: "Trip", bundle: nil)
        let vc = st.instantiateViewController(withIdentifier: "Trip") as! TripViewController
        
        if onViewController != nil {
            onViewController!.show(vc, sender: nil)
        } else {
            MaterialTB.currentTabBar!.show(vc, sender: nil)
        }
        
        if location != nil {
            TripManager.current?.setDestination(location!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        guard mapView == nil else {
            TripManager.current!.registerTripListener(self)
            return
        }
        
        mapView = GMSMapView(frame: self.view.frame)
        self.view.insertSubview(mapView, belowSubview: overlay)
        
        let c1 = NSLayoutConstraint(item: mapView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0)
        let c2 = NSLayoutConstraint(item: mapView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
        let c3 = NSLayoutConstraint(item: mapView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)
        let c4 = NSLayoutConstraint(item: mapView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
        
        self.view.addConstraints([c1, c2, c3, c4])
        self.view.layoutIfNeeded()
        
        
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
            self.overlay.addGradientBackground(UIColor(white: 1, alpha: 0), .white, start: 0.4, end: 0.8)
            self.overlay.addGradientBackground(.white, UIColor(white: 1, alpha: 0), start: 0.07, end: 0.5)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        TripManager.current?.clearTripListener()
    }
    
    @IBAction func endTrip(_ sender: Any) {
        paused = true
        TripManager.current?.clearTripListener()
        self.mapView.clear()
        MBProgressHUD.showAdded(to: self.overlay, animated: true)
        mapView = nil
        TripManager.current!.stop()
        Alert3A.show(withTitle: "Felicitaciones", body: "Hemos guardado tu viaje de hoy en bici. Estamos procesando tu información para que veas cuánto has aportado al medio ambiente y a tu ciudad.", accpetTitle: "Genial", confirmation: {
            MBProgressHUD.hide(for: self.overlay, animated: true)
            self.performSegue(withIdentifier: "tripBrief", sender: nil)
        }, parent: self)
    }
    
    // Tracking
    func tripUpdated(path: GMSPath) {
        guard TripManager.current != nil && !paused else {
            return
        }
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
        guard TripManager.current != nil && !paused else {
            return
        }
        self.mapView.animate(toBearing: heading)
    }
    
    func noLocation() {
        hud?.hide(animated: true)
        hud = nil
        Alert3A.show(withTitle: "Lo sentimos", body: "No hemos podido recibir tu ubicación. Revisa que tengas el GPS prendido y que hayas autorizado a Trilly para usarlo.", accpetTitle: "OK", confirmation: {
            self.dismiss(animated: true, completion: nil)
        }, parent: self)
    }
    
    func tripPaused(message: String, path: GMSPath) {
        Alert3A.show(withTitle: "Viaje en pausa", body: message, accpetTitle: "Continuar viaje", cancelTitle: "Terminar", confirmation: {
            TripManager.resume(self)
        }, cancelation: {
            // Save paused path to firebase and clean encoded path
            TripManager.clear()
            self.performSegue(withIdentifier: "tripBrief", sender: nil)
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
    
    func destinationUpdated(_ route: GMSPath) {
        routePolyline?.map = nil
        routePolyline = GMSPolyline(path: route)
        routePolyline!.strokeColor = Trilly.UI.contrastColor
        routePolyline!.strokeWidth = 10
        routePolyline!.map = mapView
    }
    
    // For directios
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
        return false
    }
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        self.destinationTextField.text = place.name
        TripManager.current?.setDestination(place.coordinate)
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}
