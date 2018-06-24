//
//  DetailsViewController.swift
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


class DetailsViewController: UIViewController {
    
    //MARK: - Properties

    var item: MBRecord?
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        fetchData()
    }
    
    //MARK: - Functions
    
    func setupViews() {
    }
    
    func fetchData() {
        guard let authtoken = App.account?.authtoken,
            let userid = App.account?.userID else
        {
            showAlert(error: HemlockError.sessionExpired())
            return //TODO: add analytics
        }
        
        /*
        // fetch the list of items
        let req = Gateway.makeRequest(service: API.actor, method: API.actorCheckedOut, args: [authtoken, userid])
        req.gatewayObjectResponse().done { obj in
            try self.fetchCircRecords(fromObject: obj)
            }.catch { error in
                self.showAlert(error: error)
        }
 */
    }
}

