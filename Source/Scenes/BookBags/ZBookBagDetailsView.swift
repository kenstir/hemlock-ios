/*
 * ZBookBagDetailsView.swift
 * Z is for SwiftUI
 *
 * Copyright (C) 2021 Kenneth H. Cox
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

import SwiftUI

@available(iOS 14.0, *)
struct ZBookBagDetailsView: View {
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("books to read")
                    .font(.title2)
                Text("random books I want to read")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            List(0 ..< 15) { item in
                VStack(alignment: .leading) {
                    Text("Harry Potter and the Order of the Phoenix")
                        .font(.headline)
                    Text("Rowling, J. K.")
                        .font(.subheadline)
                    
                }
            }
        }
    }
}

@available(iOS 14.0, *)
struct BookBagDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ZBookBagDetailsView()
    }
}
