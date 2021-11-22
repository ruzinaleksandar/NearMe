//
//  Venue+CoreDataProperties.swift
//  NearMeTask
//
//  Created by Aleksandar Ruzin on 20.11.21.
//
//

import Foundation
import CoreData

/*
 
 Automatically created class for the properties of the Venue entity defined in the xcdatamodel
 
 */

extension Venue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Venue> {
        return NSFetchRequest<Venue>(entityName: "Venue")
    }

    @NSManaged public var address: String?
    @NSManaged public var category: String?
    @NSManaged public var distance: Int16
    @NSManaged public var iconLink: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?

}

extension Venue : Identifiable {

}
