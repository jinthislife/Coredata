//
//  Topic.swift
//  CoreDataWithAbstractEntity
//
//  Created by Jin Lee on 11/10/20.
//

import Foundation
import CoreData

class Topic: Node {
    @NSManaged fileprivate(set) var id: UUID

    override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
    }
}
