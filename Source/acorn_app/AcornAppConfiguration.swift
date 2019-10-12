//
//  AcornAppConfiguration.swift
//
//  Copyright (C) 2019 Kenneth H. Cox
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

class AcornAppConfiguration: AppConfiguration {
    let title = "Acorn Catalog"
    let url = "https://acorn.biblio.org"
    let bugReportEmailAddress = "kenstir.apps@gmail.com"
    let sort: String? = nil

    let enableHierarchicalOrgTree = true
    let enableHoldShowQueuePosition = true
    let enableHoldPhoneNotification = true
    let enableMainSceneBottomToolbar = false
    let enablePayFines = true
    let groupCopyInfoBySystem = false
    let enableCopyInfoWebLinks = true
    let needMARCRecord = true

    let barcodeFormat: BarcodeFormat = .Codabar
    let searchLimit = 100

    let searchFormatsJSON = """
[
  {"l":"All Formats", "f":""},
  {"l":"All Books", "f":"book", "L":"Book"},
  {"l":"All Music", "f":"music"},
  {"l":"Audiocassette music recording", "f":"casmusic", "h":true},
  {"l":"Blu-ray", "f":"blu-ray"},
  {"l":"Braille", "f":"braille", "h":true},
  {"l":"Cassette audiobook", "f":"casaudiobook", "h":true},
  {"l":"CD Audiobook", "f":"cdaudiobook"},
  {"l":"CD Music recording", "f":"cdmusic"},
  {"l":"Downloadable audiobooks", "f":"eaudio"},
  {"l":"Downloadable ebooks", "f":"ebook"},
  {"l":"Downloadable music", "f":"emusic"},
  {"l":"Downloadable video", "f":"evideo"},
  {"l":"DVD", "f":"dvd"},
  {"l":"Equipment, games, toys", "f":"equip", "h":true},
  {"l":"Graphic novels and comic books", "f":"graphicnovel"},
  {"l":"Kit", "f":"kit", "h":true},
  {"l":"Large Print Material", "f":"lpbook"},
  {"l":"Magazines", "f":"magazine", "L":"Magazine"},
  {"l":"Map", "f":"map", "h":true},
  {"l":"Microform", "f":"microform", "h":true},
  {"l":"MP3 CD Audiobook", "f":"mp3audio"},
  {"l":"Music Score", "f":"score"},
  {"l":"Phonograph music recording", "f":"phonomusic", "h":true},
  {"l":"Phonograph spoken recording", "f":"phonospoken", "h":true},
  {"l":"Picture", "f":"picture"},
  {"l":"Playaway", "f":"playaway"},
  {"l":"Playaway Views", "f":"playaway_views"},
  {"l":"Serials and magazines", "f":"serial"},
  {"l":"Software and video games", "f":"software"},
  {"l":"VHS", "f":"vhs", "h":true}
]
"""
}
