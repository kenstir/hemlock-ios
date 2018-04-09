//
//  Account.swift
//  hemlock.ios
//
//  Created by Ken Cox on 4/8/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

import Foundation

struct Account {
    let name: String
    var authToken: String?
    var userID: Int?
    
    init(name: String) {
        self.name = name
    }
}
