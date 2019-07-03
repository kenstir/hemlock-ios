//
//  MARCDatafield.swift
//  Hemlock
//
//  Created by Kenneth Cox on 7/2/19.
//  Copyright © 2019 Ken Cox. All rights reserved.
//

import Foundation

struct MARCDatafield {
    let tag: String
    let ind1: String
    let ind2: String
    init(tag: String, ind1: String, ind2: String) {
        self.tag = tag
        self.ind1 = ind1
        self.ind2 = ind2
    }
}
