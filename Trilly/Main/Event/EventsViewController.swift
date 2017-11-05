//
//  EventsViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 10/5/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import MaterialTB
import MBProgressHUD

class EventsViewController: MaterialViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var eventsTable: UITableView!
    private var events: [Event] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        Event.global { (event) in
            MBProgressHUD.hide(for: self.view, animated: true)
            if event != nil {
                self.events = event!
                self.eventsTable.reloadData()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = events[indexPath.row]
        let loadCellInfo: (UITableViewCell)->Void = {cell in
            (cell.viewWithTag(2) as? UIImageView)?.downloadedFrom(link: event.icon ?? "")
            (cell.viewWithTag(11) as? UILabel)?.text = event.name ?? "Sin titulo"
            (cell.viewWithTag(12) as? UILabel)?.text = event.descriptionT ?? "Sin descripción"
            if event.date != nil {
                (cell.viewWithTag(13) as? UILabel)?.text = (event.date! as Date).toString(format: .Short)
                (cell.viewWithTag(14) as? UILabel)?.text = (event.date! as Date).toString(format: .Time)
            }
            if event.participants != nil {
                (cell.viewWithTag(15) as? UILabel)?.text = "\(event.participants ?? 0)"
            }
        }
        switch indexPath.row % 2 {
        case 0:
            let cellUI = tableView.dequeueReusableCell(withIdentifier: "GreenEvent", for: indexPath) as! TrillyCell
            cellUI.uiUpdates = {(cell) in
                cell.viewWithTag(1)?.addNormalShadow()
                cell.viewWithTag(1)?.addGradientBackground(Trilly.UI.secondColor, Trilly.UI.mainColor, horizontal: true, diagonal: true)
                loadCellInfo(cell)
            }
            return cellUI
        case 1:
            let cellUI = tableView.dequeueReusableCell(withIdentifier: "RedEvent", for: indexPath) as! TrillyCell
            cellUI.uiUpdates = {(cell) in
                cell.viewWithTag(1)?.addNormalShadow()
                cell.viewWithTag(1)?.addGradientBackground(Trilly.UI.contrastColor, Trilly.UI.secondContrastColor, horizontal: true, diagonal: true)
                loadCellInfo(cell)
            }
            return cellUI
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return max(250, UIScreen.main.bounds.size.height/3)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contrast = (indexPath.row % 2 == 1)
        EventDetailViewController.showEventDetail(event: events[indexPath.row], parent: self, specialColor: contrast)
    }

}
