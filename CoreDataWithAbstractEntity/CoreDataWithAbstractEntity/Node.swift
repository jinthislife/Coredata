//
//  Node.swift
//  CoreDataWithAbstractEntity
//
//  Created by Jin Lee on 11/10/20.
//

import Foundation
import CoreData

@objc(Node)
class Node: NSManagedObject {
    @NSManaged var createdAt: Date
    @NSManaged var title: String
}

extension Node {
    @nonobjc func fetchRequest() -> NSFetchRequest<Node> {
        return NSFetchRequest<Node>(entityName: "Node")
    }
}
