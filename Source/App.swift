//
//  App.swift
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
import PromiseKit
import PMKAlamofire
import Valet
import os.log

class App {
    //MARK: - Properties

    // idea from https://developer.apple.com/documentation/swift/maintaining_state_in_your_apps
    /*
    enum State {
        case start
        case loggedOut(Library)
        case loggedIn(Library, Account)
        case sessionExpired(Library, Account)
    }
    var state: State = .start
    */
    
    static var theme: Theme!

    static var library: Library?
    static var idlLoaded: Bool?
    static var account: Account?

    /// the URL of the JSON directory of library systems available for use in the Hemlock app
    static let directoryURL = "https://evergreen-ils.org/directory/libraries.json"

    /// the valet saves things in the iOS keychain
    static let valet = Valet.valet(with: Identifier(nonEmpty: "Hemlock")!, accessibility: .whenUnlockedThisDeviceOnly)
    
    /// search scopes
    static let searchScopes = ["Keyword","Title","Author","Subject","Series"]

    //TODO: get from server
    static var organizations: [String] = [
"All PINES Libraries",
"Athens Regional Library System",
"Athens-Clarke County Library",
"Bogart Library",
"Danielsville/Madison County Library",
"East Athens Community Resource Ctr.",
"Lavonia Carnegie Library",
"Lay Park Community Resource Ctr.",
"Lexington/Oglethorpe County Library",
"Pinewoods North Community Learning Center",
"Royston Library",
"Sandy Creek ENSAT Resource Ctr.",
"Watkinsville/Oconee County Library",
"Winterville Library",
"Augusta-Richmond County Public Library System",
"Appleby Branch Library",
"Augusta-Richmond Co. Public Lib.",
"Diamond Lakes Branch Library",
"Friedman Branch Library",
"Maxwell Branch Library",
"Wallace Branch Library",
"Bartram Trail Regional Library",
"BTRL-Bookmobile",
"Mary Willis Library",
"Taliaferro County Library",
"Thomson-McDuffie County Library",
"Brooks County Public Library",
"Brooks County Public Library Headquarters",
"Catoosa County Library System",
"Catoosa County Library",
"Chattooga County Library",
"Summerville Branch",
"Trion Public Library",
"Cherokee Regional Library",
"Chickamauga Public Library",
"Dade County Public Library",
"LaFayette-Walker County Library",
"Rossville Public Library",
"Chestatee Regional Library System",
"Dawson County  Satellite",
"Dawson County Library",
"Lumpkin County Library",
"Clayton County Library System",
"Forest Park Branch",
"Headquarters Library",
"Jonesboro Branch",
"Lovejoy Branch",
"Morrow Branch",
"Riverdale Branch",
"Coastal Plain Regional Library System",
"Carrie Dorsey Perry Memorial Library",
"Coastal Plain Regional Library Headquarters",
"Cook County Library",
"Irwin County Library",
"Tifton-Tift County Public Library",
"Victoria Evans Memorial Library",
"Conyers-Rockdale Library System",
"Nancy Guinn Memorial Library",
"Desoto Trail Regional Library",
"Baker County Library",
"Blakely-Maddox Memorial Library",
"Camilla-DeSoto Trail Regional Library",
"Jakin Public Library",
"Pelham-Pelham Carnegie Library",
"Sale City Library",
"Dougherty County Public Library",
"Central Branch",
"Northwest Branch",
"Southside Branch",
"Tallulah Branch",
"Westtown Branch",
"Elbert County Public Library System",
"Bowman Branch",
"ECPL-Bookmobile",
"Elbert County Public Library",
"Fitzgerald-Ben Hill County Library System",
"Fitzgerald-Ben Hill County Library",
"Flint River Regional Library",
"Barnesville-Lamar County Library",
"Fayette County Public Library",
"Griffin-Spalding County Library",
"J. Joel Edwards Public Library",
"Jackson-Butts County Public Library",
"Monroe County Library",
"Peachtree City Library",
"Tyrone Public Library",
"Georgia Public Library Service",
"GLASS - Georgia Library for Accessible Services",
"Georgia Public Library Service - GDC",
"Georgia Public Library Service - Professional Collection",
"State Library of Georgia Administrative Offices",
"Greater Clarks Hill Regional Library",
"Burke County Library",
"Columbia County Library",
"Euchee Creek Library",
"Harlem Branch library",
"Lincoln County Library",
"Midville Library",
"Sardis Library",
"Warren County Library",
"Hall County Library System",
"Blackshear Place Branch",
"Gainesville Branch",
"Murrayville Branch",
"North Hall Tech Center",
"Spout Springs Library",
"Hart County Library System",
"Hart County Library",
"Henry County Library",
"Cochran Public Library / Stockbridge",
"Fairview Public Library ",
"Fortson Public Library / Hampton",
"Locust Grove Public Library",
"McDonough Public Library",
"Houston County Public Library",
"Centerville Branch Library",
"Nola Brantley Memorial Library / Warner Robins",
"Perry Branch Library",
"Jefferson County Library",
"JCL-Bookmobile",
"Louisville Public Library",
"McCollum Public Library",
"Wadley Public Library",
"Kinchafoonee Regional Library System",
"Calhoun County Library",
"Clay County Library",
"Kinchafoonee Regional Library",
"Quitman County Public Library",
"Randolph County Library",
"Terrell County Library",
"Webster County Library",
"Lake Blackshear Regional Library System",
"Byromville Public Library ",
"Cordele-Crisp Carnegie Library",
"Dooly County Library",
"Elizabeth Harris Library",
"Lake Blackshear Regional Library",
"Schley County Public Library",
"Lee County Public Library",
"Leesburg Branch",
"Oakland Branch",
"Redbone Branch",
"Smithville Branch",
"Live Oak Public Libraries",
"Bookmobile Services",
"Bull St. Library",
"Carnegie Library",
"Forest City Library",
"Garden City Library",
"Hinesville Library",
"Islands Library",
"Midway/Riceboro Library",
"Oglethorpe Mall Library - Savannah",
"Pooler Library",
"Port City Library",
"Rincon Library",
"Southwest Chatham Library",
"Springfield Library",
"Tybee Library",
"W.W. Law Library",
"West Broad St. Library",
"Marshes of Glynn Libraries",
"Brunswick-Glynn County Library",
"St. Simons Island Public Library",
"Middle Georgia Regional Library",
"Charles A. Lanford Library",
"Crawford County Public Library",
"East Wilkinson County Library",
"Genealogical and Historical Department",
"Gordon Public Library",
"Ideal Public Library",
"Jones County Public Library",
"Library for the Blind &amp; Physically Handicapped",
"Marshallville Public Library",
"Miss Martha Bookmobile",
"Montezuma Public Library",
"Oglethorpe Public Library",
"Regional Library",
"Riverside Branch Library",
"Shurling Branch Library",
"Twiggs County Public Library",
"Washington Memorial Library",
"Moultrie-Colquitt County Library System",
"Doerun Municipal Library",
"Moultrie Library Bookmobile",
"Moultrie-Colquitt County Library",
"Mountain Regional Library System",
"Fannin County Public Library",
"MRLS-Bookmobile",
"Mountain Regional Library",
"Towns County Public Library",
"Union County Public Library",
"Newton County Library System",
"Covington Branch Library",
"Newborn Library Service Outlet",
"Porter Memorial Branch Library",
"Northeast Georgia Regional Library",
"Clarkesville-Habersham County Library",
"Cornelia-Habersham County Library",
"Rabun County Library",
"System Offices",
"Toccoa-Stephens County Library",
"White County Library - Cleveland Branch",
"White County Library - Helen Branch",
"Northwest Georgia Regional Library",
"Calhoun-Gordon County Library",
"Chatsworth Murray County Library",
"Dalton-Whitfield Library ",
"Ocmulgee Regional Library System",
"Bleckley County Library",
"Ocmulgee Regional Library Headquarters",
"Pulaski County Library",
"Telfair County Library",
"Wheeler County Library",
"Wilcox County Library",
"Oconee Regional Library System",
"Glascock County Library",
"Johnson County Library",
"Laurens County Library",
"Rosa M. Tarbutton Memorial Library",
"Treutlen County Library",
"Ohoopee Regional Library System",
"Glennville / Tattnall County Library",
"Hazlehurst-Jeff Davis Branch",
"Ladson Genealogical Library",
"Montgomery County Library",
"Nelle Brown Memorial [Lyon]",
"Ohoopee Bookmobile",
"Reidsville / Tattnall County Library",
"Vidalia-Toombs County Library",
"Okefenokee Regional Library System",
"Alma-Bacon County Public Library",
"Appling County Public Library",
"Clinch County Public Library",
"Pierce County Public Library",
"Waycross-Ware Co. Public Lib.",
"Peach Public Libraries",
"Byron Public Library",
"Thomas Public Library",
"Piedmont Regional Library System",
"Auburn Public Library",
"Banks County Public Library",
"Braselton Library",
"Commerce Public Library",
"Harold S. Swindle Public Library (Nicholson)",
"Jefferson Public Library",
"Maysville Public Library",
"PIED-Bookmobile",
"Statham Public Library",
"Talmo Public Library",
"Winder Public Library",
"Pine Mountain Regional Library System",
"Butler Public Library",
"Extension Services",
"Greenville Area Public Library",
"Hightower Memorial Library",
"Manchester Public Library",
"Reynolds Community Library",
"Yatesville Public Library",
"Roddenbery Memorial Library System",
"Roddenbery Memorial Library",
"Sara Hightower Regional Library",
"Cave Spring Branch",
"Cedartown Branch",
"Outreach Collection",
"Rockmart Branch",
"Rome Branch",
"Satilla Regional Library",
"Ambrose Public Library",
"Broxton Public Library",
"Douglas-Coffee County Library",
"Nicholls Public Library",
"Pearson Public Library",
"Willacoochee Public Library",
"Screven-Jenkins Regional Library",
"Jenkins County Memorial Library",
"SJRLS-Bookmobile",
"Screven County Library",
"South Georgia Regional Library System",
"Allen Statenville Library",
"Bookvan",
"Johnston Lakes Library",
"McMullen Southside Library",
"Miller Lakeland Library",
"Salter Hahira Library",
"Talking Book Center",
"Southwest Georgia Regional Library System",
"Decatur County Public Library",
"Miller County Public Library",
"Seminole Public Library",
"Southwest Georgia Regional Library Bookmobile",
"Statesboro Regional Library",
"Bryan County Library, Pembroke",
"Bryan County Library, Richmond Hill",
"Evans County Library, Claxton",
"Franklin Memorial Library, Emanuel County, Swainsboro",
"Headquarters, Statesboro",
"L.C. Anderson Memorial Library, Candler County, Metter",
"Thomas County Public Library System",
"Boston Carnegie Library",
"Coolidge Public Library",
"Meigs Public Library",
"Ochlocknee Public Library ",
"Pavo Public Library",
"Thomas County Public Library",
"Three Rivers Regional Library System",
"Brantley County Library",
"Camden County Library",
"Charlton County Library",
"HQ - Administrative Office",
"Hog Hammock Public Library",
"Long County Library",
"McIntosh County/Ida Hilton Library",
"St. Marys Library",
"Wayne County Library",
"Troup-Harris Regional Library",
"Harris County Public Library",
"Hogansville Public Library",
"LaGrange Memorial Library",
"Twin Lakes Library System",
"Lake Sinclair Library",
"Mary Vinson Memorial Library",
"Uncle Remus Regional Library System",
"Greene County Public Library",
"Hancock County Public Library",
"Jasper County Public Library",
"Monroe-Walton County Library",
"Morgan County Library",
"O'Kelly Memorial Library",
"Putnam County Public Library",
"Stanton Memorial Library",
"Uncle Remus Regional Library System Headquarters",
"Walnut Grove Library",
"West Georgia Regional Library",
"Bowdon Public Library",
"Bremen Public Library",
"Buchanan Branch Library",
"Centralhatchee Public Library",
"Crossroads Public Library",
"Dallas Public Library",
"Dog River Library",
"Douglas County Public Library",
"Ephesus Public Library",
"Heard County Public Library",
"Lithia Springs Betty C. Hagler Public Library",
"Maude Ragsdale Public Library",
"Mount Zion Public Library",
"Neva Lomason Memorial",
"New Georgia Public Library",
"Ruth Holder Public Library",
"Tallapoosa Public Library",
"Villa Rica Public Library",
"West Georgia Regional Library Bookmobile",
"Whitesburg Public Library",
"Worth County Library System",
"Sylvester-Margaret Jones Library",
]

    //MARK: - Functions
    
    static func loadIDL() -> Bool {
        let start = Date()
        let parser = IDLParser(contentsOf: URL(string: Gateway.idlURL())!)
        App.idlLoaded = parser.parse()
        let elapsed = -start.timeIntervalSinceNow
        os_log("idl.elapsed: %.3f", log: Gateway.log, type: .info, elapsed)
        return App.idlLoaded!
    }
    static func fetchIDL() -> Promise<Void> {
        if App.idlLoaded ?? false {
            return Promise<Void>()
        }
        let start = Date()
        let req = Alamofire.request(Gateway.idlURL())
        let promise = req.responseData().done { data, pmkresponse in
            let parser = IDLParser(data: data)
            App.idlLoaded = parser.parse()
            let elapsed = -start.timeIntervalSinceNow
            os_log("idl.elapsed: %.3f", log: Gateway.log, type: .info, elapsed)
        }
        return promise
    }
}
