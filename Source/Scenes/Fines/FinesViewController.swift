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

import UIKit
import PromiseKit
import PMKAlamofire

class FinesViewController: UIViewController {
    //MARK: - Properties
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchFines()
    }
    
    //MARK: - Functions
    
    func fetchFines() {
        guard let authtoken = AppSettings.account?.authtoken,
            let userid = AppSettings.account?.userID else
        {
            return //todo add analytics
        }
        
        // fetch the summary
        let req = Gateway.makeRequest(service: API.actor, method: API.finesSummary, args: [authtoken, userid])
        //todo: create gatewayResponseObj() promise that requires an osrfobject response
        req.gatewayResponse().done { resp, pmkresp in
            guard let obj = resp.obj else {
                throw HemlockError.unexpectedNetworkResponse("fines summary") //todo add analytics
            }
            self.loadFinesSummary(fromObj: obj)
        }.catch { error in
            self.showAlert(title: "Request failed", message: error.localizedDescription)
        }
        
        // fetch the transactions
        let req2 = Gateway.makeRequest(service: API.actor, method: API.transactionsWithCharges, args: [authtoken, userid])
        req2.gatewayArrayResponse().done { array in
            self.loadTransactions(fromArray: array)
        }.catch { error in
            self.showAlert(title: "Request failed", message: error.localizedDescription)
        }
    }
    
    func loadFinesSummary(fromObj obj: OSRFObject) {
        debugPrint(obj)
        let totalOwed = obj.getDouble("total_owed")
        let totalPaid = obj.getDouble("total_paid")
        let balanceOwed = obj.getDouble("balance_owed")
        print("totalOwed: \(totalOwed)")
        print("totalPaid: \(totalPaid)")
        print("balanceOwed: \(balanceOwed)")
        print("stop here")
    }
    
    func loadTransactions(fromArray array: [OSRFObject]) {
        debugPrint(array)
        print("here")
    }
}
