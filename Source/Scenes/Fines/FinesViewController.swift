//
//  FinesViewController.swift
//
//  Copyright (C) 2018 Kenneth H. Cox
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import Foundation
import UIKit
import PromiseKit
import PMKAlamofire

class FinesViewController: UIViewController {

    //MARK: - Properties

    @IBOutlet weak var finesTable: UITableView!
    @IBOutlet weak var finesSummary: UIStackView!
    @IBOutlet weak var totalOwedLabel: UILabel!
    @IBOutlet weak var totalPaidLabel: UILabel!
    @IBOutlet weak var balanceOwedLabel: UILabel!
    @IBOutlet weak var totalOwedVal: UILabel!
    @IBOutlet weak var totalPaidVal: UILabel!
    @IBOutlet weak var balanceOwedVal: UILabel!

    var fines: [FineRecord] = []
//    var bgView: UIView?
    
    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        fetchData()
    }
    
    //MARK: - Functions
    
    func setupViews() {
        finesTable.delegate = self
        finesTable.dataSource = self
        
        Style.styleStackView(asTableHeader: finesSummary)
        /*
        // set the background of the summary stack to grey
        bgView = UIView()
        if let v = bgView {
            v.backgroundColor = Style.tableHeaderBackground
            v.translatesAutoresizingMaskIntoConstraints = false
            finesSummary.insertSubview(v, at: 0)
            v.pin(to: finesSummary)
        }
        */
        
        totalOwedLabel.textColor = UIColor.darkGray
        totalOwedVal.textColor = UIColor.darkGray
        totalPaidLabel.textColor = UIColor.darkGray
        totalPaidVal.textColor = UIColor.darkGray
        balanceOwedLabel.textColor = UIColor.darkGray
        balanceOwedVal.textColor = UIColor.darkGray
    }

    func fetchData() {
        guard let authtoken = App.account?.authtoken,
            let userid = App.account?.userID else
        {
            showAlert(title: "No account", message: "Not logged in")
            return //TODO: add analytics
        }
        
        // fetch the summary
        let req = Gateway.makeRequest(service: API.actor, method: API.finesSummary, args: [authtoken, userid])
        req.gatewayObjectResponse().done { obj in
            self.loadFinesSummary(fromObj: obj)
        }.catch { error in
            self.showAlert(title: "Request failed", message: error.localizedDescription)
        }
        
        // fetch the transactions
        let req2 = Gateway.makeRequest(service: API.actor, method: API.transactionsWithCharges, args: [authtoken, userid])
        req2.gatewayArrayResponse().done { objects in
            self.loadTransactions(fines: FineRecord.makeArray(objects))
        }.catch { error in
            self.showAlert(title: "Request failed", message: error.localizedDescription)
        }
    }
    
    func loadFinesSummary(fromObj obj: OSRFObject) {
        debugPrint(obj)
        totalOwedVal.text = String(format: "$ %.2f", obj.getDouble("total_owed")!)
        totalPaidVal.text = String(format: "$ %.2f", obj.getDouble("total_owed")!)
        balanceOwedVal.text = String(format: "$ %.2f", obj.getDouble("balance_owed")!)
        print("stop here")
    }
    
    func loadTransactions(fines: [FineRecord]) {
        self.fines = fines
        for fine in fines {
            print("-----------------------")
            print("title:    \(fine.title)")
            print("subtitle: \(fine.subtitle)")
            print("status:   \(fine.status)")
            if let balance = fine.balance {
                print("balance:  \(balance)")
            }
        }
        finesTable.reloadData()
    }
}

extension FinesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //need stuff here
    }
}

extension FinesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fines.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: "finesCell") else {
//            fatalError("Could not dequeue a cell")
//        }
        guard let cell: FinesTableViewCell = tableView.dequeueReusableCell(withIdentifier: "finesCell") as? FinesTableViewCell else {
            fatalError("Could not dequeue a cell")
        }
        let fine = fines[indexPath.row]
//        cell.textLabel?.text = fine.title
        cell.finesTitle?.text = fine.title
        cell.finesSubtitle?.text = fine.subtitle
        cell.finesValue?.text = String(format: "$ %.2f ", fine.balance!)
        cell.finesStatus?.text = fine.status
        return cell
    }
    
}


