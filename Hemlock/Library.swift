//
//  Library.swift
//  Hemlock
//
//  Created by Ken Cox on 4/15/18.
//  Copyright © 2018 Ken Cox. All rights reserved.
//

import Foundation

class Library {
    let url: String
    let name: String?
    let directoryName: String?

    init(_ url: String, name: String? = nil, directoryName: String? = nil) {
        self.name = name
        self.directoryName = directoryName
        self.url = url
    }
}
