//
//  EventDetailViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 10/6/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import Modals3A
import CoreLocation

class EventDetailViewController: UIViewController {
    
    private var event: Event!
    private var specialColor: Bool!
    
    public class func showEventDetail(event: Event, parent: UIViewController, specialColor: Bool = false) {
        let st = UIStoryboard(name: "Event", bundle: nil)
        let eventVC = st.instantiateViewController(withIdentifier: "Event") as! EventDetailViewController
        eventVC.event = event
        eventVC.specialColor = specialColor
        parent.showDetailViewController(eventVC, sender: nil)
        UIApplication.shared.statusBarStyle = .lightContent
    }

    @IBOutlet weak var backB: UIButton!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var coverBackground: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoBackground: UIView!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var bookedLabel: UILabel!
    @IBOutlet weak var infoText: UITextView!
    @IBOutlet weak var locationB: UIButton!
    @IBOutlet weak var joinB: UIButton!
    @IBOutlet weak var locationImage: UIImageView!
    
    private var isUserAttending = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if event.icon != nil {
            self.coverImage.image = UIImage(named: event.icon!)
        }
        self.titleLabel.text = event.name ?? "Evento Trilly"
        self.pointsLabel.text = String(format: "%.0f pts.", event.reward ?? 0)
        if event.date != nil {
            self.dateLabel.text = (event.date! as Date).toString(format: .Short)
            self.timeLabel.text = (event.date! as Date).toString(format: .Time)
        }
        self.bookedLabel.text = "\(event.participants ?? 0)"
        self.infoText.text = event.descriptionT ?? "Un evento para que disfrutes con Trilly"
        
        User.current!.events { (events) in
            if events != nil {
                for event in events! {
                    if (event.uid ?? "") == self.event.uid! {
                        self.isUserAttending = true
                    }
                }
                if self.isUserAttending {
                    self.joinB.setTitle("¡Ya estás en este evento!", for: .normal)
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !specialColor {
            self.coverBackground.addGradientBackground(Trilly.UI.secondColor, Trilly.UI.mainColor, horizontal: true, diagonal: true)
            self.joinB.addGradientBackground(Trilly.UI.mainColor, Trilly.UI.secondColor, horizontal: true)
        } else {
            self.coverBackground.addGradientBackground(Trilly.UI.contrastColor, Trilly.UI.secondContrastColor, horizontal: true, diagonal: true)
            self.joinB.addGradientBackground(Trilly.UI.contrastColor, Trilly.UI.secondContrastColor, horizontal: true)
            self.locationB.setTitleColor(Trilly.UI.secondContrastColor, for: .normal)
            self.locationImage.image = UIImage(named: "LocationPink")
        }
        self.infoBackground.addDarkShadow()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func location(_ sender: Any) {
        if event.location != nil {
            LocationViewController.showLocation(location: CLLocationCoordinate2D(latitude: event.location!.latitude, longitude: event.location!.longitude), title: event.name ?? "Evento Trilly", onViewController: self)
        }
    }
    
    @IBAction func join(_ sender: Any) {
        if !self.isUserAttending {
            
            guard !Trilly.Network.offline else {
                self.showAlert(title: "Sin conexión", message: "No puedes unirte a un evento si no tienes conexión. Intenta de nuevo más tarde", closeButtonTitle: "Entendido")
                return
            }
            
            event.addUser(User.current!)
            User.current!.addEvent(event)
            
            self.joinB.setTitle("¡Ya estás en este evento!", for: .normal)
        } else {
            guard event.date != nil else { return }
            if let compareDate = Calendar.current.date(byAdding: .hour, value: 3, to: Date()) {
                if compareDate <= (event.date! as Date) {
                    self.showAlert(title: "¡Ya vamos a empezar!", message: "Este evento está próximo a comenzar, puedes entrar a la ubicación para iniciar un viaje hacia el evento.", closeButtonTitle: "Genial")
                }
            }
        }
    }
    
}
