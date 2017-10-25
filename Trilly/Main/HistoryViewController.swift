//
//  HistoryViewController.swift
//  Trilly
//
//  Created by Daniel Soto on 10/9/17.
//  Copyright © 2017 Tres Astronautas. All rights reserved.
//

import UIKit
import MaterialTB
import MBProgressHUD

class HistoryViewController: MaterialViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {


    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchBackground: UIView!
    @IBOutlet weak var searchB: UIButton!
    @IBOutlet weak var historyTable: UITableView!
    
    private var filteredTrips: [Trip]?
    var userTrips: [Trip] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MBProgressHUD.showAdded(to: self.view, animated: true)
        User.current!.history { (trips) in
            if trips != nil && trips!.count > 0 {
                self.userTrips = trips!
                self.historyTable.reloadData()
            } else {
                // Show no trip message
            }
            MBProgressHUD.hide(for: self.view, animated: true)
        }
        // Do any additional setup after loading the view.
    }

    override func viewDidLayoutSubviews() {
        self.searchBackground.addNormalShadow()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func search(_ sender: UIButton) {
    }
    
    
    // Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTrips != nil ? filteredTrips!.count : userTrips.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellUI = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath) as! TrillyCell
        let trip = filteredTrips != nil ? filteredTrips![indexPath.row] : userTrips[indexPath.row]
        
        cellUI.uiUpdates = {cell in
            cell.viewWithTag(1)?.addNormalShadow()
            (cell.viewWithTag(11) as? UILabel)?.text = String(format: "%.0f km", trip.stats?.km ?? 0)
            (cell.viewWithTag(12) as? UILabel)?.text = (trip.date! as Date).toString(format: .Short)
        }
        
        return cellUI
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let trip = filteredTrips != nil ? filteredTrips![indexPath.row] : userTrips[indexPath.row]
        TripBriefViewController.showTrip(trip: trip, onViewController: self)
    }
    
    // Search
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as NSString? {
            let resultString = text.replacingCharacters(in: range, with: string)
            applySearch(resultString)
        } else {
            applySearch("")
        }
        return true
    }
    
    func applySearch(_ query: String) {
        if query != "" {
            filteredTrips = userTrips.filter({ (trip) -> Bool in
                trip.filters!.lowercased().contains(query.lowercased())
            })
        } else {
            filteredTrips = nil
        }
        self.historyTable.reloadData()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchTextField.resignFirstResponder()
    }

}
