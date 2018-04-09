//
//  API.swift
//  Hemlock
//
//  Created by Ken Cox on 4/8/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

import Foundation

struct API {
    // auth
    static let auth = "open-ils.auth"
    static let authInit = "open-ils.auth.authenticate.init"
    static let authComplete = "open-ils.auth.authenticate.complete"
    static let authGetSession = "open-ils.auth.session.retrieve"
}
