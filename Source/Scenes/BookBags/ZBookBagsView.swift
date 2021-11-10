/*
 * ZBookBagsView.swift
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
struct ZBookBagsView: View {
    var bookBags: [BookBag]

    var body: some View {
        List(bookBags) { bookBag in
            BookBagRow(bookBag: bookBag)
        }.navigationBarTitle("My Lists")
            .listStyle(.grouped)
    }
}

@available(iOS 14.0, *)
struct BookBagsView_Previews: PreviewProvider {
    static var previews: some View {
        ZBookBagsView(bookBags: testData)
    }
}

@available(iOS 14.0, *)
struct BookBagRow: View {
    let bookBag: BookBag

    var body: some View {
        NavigationLink(destination: Text(bookBag.name)) {
            HStack() {
                VStack(alignment: .leading) {
                    Text(bookBag.name)
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    Text(bookBag.description ?? "")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                Text("\(bookBag.items.count) items")
                    .foregroundColor(.secondary)
                    .frame(alignment: .topLeading)
            }
        }
    }
}
