//
//  HoldsViewController.swift
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

class HoldsViewController: UIViewController {
    //MARK: - Properties

    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
    }
    
    //MARK: - Functions
    
    func fetchData() {
        guard let authtoken = App.account?.authtoken,
            let userid = App.account?.userID else
        {
            showAlert(title: "No account", message: "Not logged in")
            return //TODO: add analytics
        }
        
        // fetch holds
        let req = Gateway.makeRequest(service: API.circ, method: API.holdsRetrieve, args: [authtoken, userid])
        req.gatewayArrayResponse().done { objects in
            self.loadHolds(holds: HoldRecord.makeArray(objects))
        }.catch { error in
            self.showAlert(error: error)
        }
    }
    
    func loadHolds(holds: [HoldRecord]) {
        for hold in holds {
            print("----------")
            print("target: \(hold.target)")
        }
    }
}
