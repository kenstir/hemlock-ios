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
import os.log

class FinesViewController: UIViewController {

    //MARK: - Properties

    @IBOutlet weak var finesTable: UITableView!
    @IBOutlet weak var finesSummary: UIStackView!
    @IBOutlet weak var totalOwedStack: UIStackView!
    @IBOutlet weak var totalOwedLabel: UILabel!
    @IBOutlet weak var totalOwedVal: UILabel!
    @IBOutlet weak var totalPaidStack: UIStackView!
    @IBOutlet weak var totalPaidLabel: UILabel!
    @IBOutlet weak var totalPaidVal: UILabel!
    @IBOutlet weak var balanceOwedLabel: UILabel!
    @IBOutlet weak var balanceOwedVal: UILabel!
    @IBOutlet weak var payFinesButton: UIButton!

    weak var activityIndicator: UIActivityIndicatorView!

    var fines: [FineRecord] = []
    var balanceOwed: Double = 0
    
    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchData()
    }

    //MARK: - Functions
    
    func setupViews() {
        if let title = R.string["Fines"] {
            self.title = title
        }

        finesTable.delegate = self
        finesTable.dataSource = self
        finesTable.tableFooterView = UIView() // prevent display of ghost rows at end of table
        
        // create and style the activity indicator
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)

        self.setupHomeButton()

        Style.styleStackView(asTableHeader: finesSummary)
        Style.styleLabel(asTableHeader: totalOwedLabel)
        Style.styleLabel(asTableHeader: totalOwedVal)
        Style.styleLabel(asTableHeader: totalPaidLabel)
        Style.styleLabel(asTableHeader: totalPaidVal)
        Style.styleLabel(asTableHeader: balanceOwedLabel)
        Style.styleLabel(asTableHeader: balanceOwedVal)
        
        // hide Total Owed and Total Paid columns if labels are empty
        if let str = R.string["total_owed"] {
            if str.isEmpty {
                totalOwedStack.isHidden = true
            } else {
                totalOwedLabel.text = str
            }
        }
        if let str = R.string["total_paid"] {
            if str.isEmpty {
                totalPaidStack.isHidden = true
            } else {
                totalPaidLabel.text = str
            }
        }
        if let str = R.string["balance_owed"] {
            if str.isEmpty {
                //balanceOwedStack.isHidden = true
            } else {
                balanceOwedLabel.text = str
            }
        }

        payFinesButton.isEnabled = false
        if App.config.enablePayFines {
            Style.styleButton(asOutline: payFinesButton)
        } else {
            payFinesButton.isHidden = true
        }
        if let str = R.string["button_pay_fines"] {
            payFinesButton.setTitle(str, for: .normal)
        }
    }

    func fetchData() {
        guard let authtoken = App.account?.authtoken,
            let userid = App.account?.userID else
        {
            self.presentGatewayAlert(forError: HemlockError.sessionExpired)
            return //TODO: add analytics
        }
        
        var promises: [Promise<Void>] = []

        centerSubview(activityIndicator)
        activityIndicator.startAnimating()

        // fetch the orgs
        promises.append(ActorService.fetchOrgTreeAndSettings(forOrgID: App.account?.homeOrgID))

        // fetch the summary
        let req1 = Gateway.makeRequest(service: API.actor, method: API.finesSummary, args: [authtoken, userid])
        let promise1 = req1.gatewayOptionalObjectResponse().done { obj in
            self.loadFinesSummary(fromObj: obj)
        }
        promises.append(promise1)
        
        // fetch the transactions
        let req2 = Gateway.makeRequest(service: API.actor, method: API.transactionsWithCharges, args: [authtoken, userid])
        let promise2 = req2.gatewayArrayResponse().done { objects in
            self.loadTransactions(fines: FineRecord.makeArray(objects))
        }
        promises.append(promise2)
        
        // wait for them to finish
        firstly {
            when(fulfilled: promises)
        }.done {
            self.updatePayFinesButton()
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func updatePayFinesButton() {
        if App.config.enablePayFines,
            let homeOrgID = App.account?.homeOrgID,
            let homeOrg = Organization.find(byId: homeOrgID),
            let isPaymentAllowed = homeOrg.isPaymentAllowedSetting,
            isPaymentAllowed && balanceOwed > 0
        {
            Style.styleButton(asInverse: payFinesButton)
            payFinesButton.isEnabled = true
            payFinesButton.addTarget(self, action: #selector(payFinesButtonPressed(_:)), for: .touchUpInside)
        }
    }

    @objc func payFinesButtonPressed(_ sender: Any) {
        if let baseurl_string = App.library?.url,
            let url = URL(string: baseurl_string + "/eg/opac/myopac/main_payment_form#pay_fines_now") {
            UIApplication.shared.open(url)
        }
    }

    func loadFinesSummary(fromObj obj: OSRFObject?) {
        let totalOwed = obj?.getDouble("total_owed") ?? 0.0
        let totalPaid = obj?.getDouble("total_paid") ?? 0.0
        self.balanceOwed = obj?.getDouble("balance_owed") ?? 0.0
        totalOwedVal.text = String(format: "$ %.2f", totalOwed)
        totalPaidVal.text = String(format: "$ %.2f", totalPaid)
        balanceOwedVal.text = String(format: "$ %.2f", balanceOwed)
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

//MARK: - UITableViewDataSource
extension FinesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fines.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: FinesTableViewCell = tableView.dequeueReusableCell(withIdentifier: "finesCell") as? FinesTableViewCell else {
            fatalError("Could not dequeue a cell")
        }
        let fine = fines[indexPath.row]
        cell.finesTitle?.text = fine.title
        cell.finesSubtitle?.text = fine.subtitle
        cell.finesValue?.text = String(format: "$ %.2f ", fine.balance!)
        cell.finesStatus?.text = fine.status
        return cell
    }
}

//MARK: - UITableViewDelegate
extension FinesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var haveAnyGroceryBills = false

        // TODO have to deal with grocery bills in the same way as android
        var records: [MBRecord] = []
        var selectedIndex = indexPath.row
        for fine in fines {
            if let mvrObj = fine.mvrObj,
                let id = mvrObj.getInt("doc_id"),
                id > 0
            {
                records.append(MBRecord(id: id, mvrObj: mvrObj))
            } else {
                haveAnyGroceryBills = true
            }
        }

        if haveAnyGroceryBills {
            // If any of the fines are for non-circulation items ("grocery bills"), we
            // launch the Details VC with only the selected record, if we can.  We have
            // no details on grocery bills, and the Details VC doesn't handle nulls.
            if let mvrObj = fines[indexPath.row].mvrObj,
                let id = mvrObj.getInt("doc_id"),
                id > 0
            {
                records = [MBRecord(id: id, mvrObj: mvrObj)]
                selectedIndex = 0
            }
        }
        
        if records.count > 0 {
            let displayOptions = RecordDisplayOptions(enablePlaceHold: true, orgShortName: nil)
            let vc = XDetailsPagerViewController(items: records, selectedItem: selectedIndex, displayOptions: displayOptions)
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            // deselect row
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
