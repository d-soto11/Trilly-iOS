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
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row % 2 {
        case 0:
            let cellUI = tableView.dequeueReusableCell(withIdentifier: "GreenEvent", for: indexPath) as! TrillyCell
            cellUI.uiUpdates = {(cell) in
                cell.viewWithTag(1)?.addNormalShadow()
                cell.viewWithTag(1)?.addGradientBackground(Trilly.UI.secondColor, Trilly.UI.mainColor, horizontal: true, diagonal: true)
            }
            return cellUI
        case 1:
            let cellUI = tableView.dequeueReusableCell(withIdentifier: "RedEvent", for: indexPath) as! TrillyCell
            cellUI.uiUpdates = {(cell) in
                cell.viewWithTag(1)?.addNormalShadow()
                cell.viewWithTag(1)?.addGradientBackground(Trilly.UI.contrastColor, Trilly.UI.secondContrastColor, horizontal: true, diagonal: true)
            }
            return cellUI
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        EventDetailViewController.showEventDetail(parent: self)
    }

}
