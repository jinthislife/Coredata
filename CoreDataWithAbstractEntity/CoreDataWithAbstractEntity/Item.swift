//
//  Item.swift
//  CoreDataWithAbstractEntity
//
//  Created by Jin Lee on 11/10/20.
//

import Foundation
import CoreData

class Item: Node {
    @NSManaged fileprivate(set) var caption: String
    @NSManaged fileprivate(set) var imageHeight: NSNumber
    @NSManaged fileprivate(set) var imageWidth: NSNumber
    @NSManaged fileprivate(set) var imageURL: String
    @NSManaged fileprivate(set) var webURL: String
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
    }
}
