//
//  Meal+CoreDataProperties.swift
//  MealTime
//
//  Created by Юлия Омельченко on 26.06.2020.
//  Copyright © 2020 Ivan Akulov. All rights reserved.
//
//

import Foundation
import CoreData


extension Meal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Meal> {
        return NSFetchRequest<Meal>(entityName: "Meal")
    }

    @NSManaged public var date: Date?
    @NSManaged public var person: Person?

}
