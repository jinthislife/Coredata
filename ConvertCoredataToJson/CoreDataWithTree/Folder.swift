//
//  Folder.swift
//  CoreDataWithTree
//
//  Created by Jin Lee on 30/9/20.
//

import Foundation
import CoreData

@objc(Folder)
public class Folder: NSManagedObject, Codable {
    @NSManaged public var id: UUID?
    //Swift Bool is an object, Objc bool is primitive type
//    @NSManaged public var isFile: Bool?
    @NSManaged public var name: String?
    @NSManaged public var timeStamp: Date?
    @NSManaged public var children: Set<Folder>?
    @NSManaged public var parent: Folder?
    
    public var isFile: Bool? {
        // https://stackoverflow.com/a/45420073/12395269
        get {
            willAccessValue(forKey: "isFile")
            let isFile = primitiveValue(forKey: "isFile") as? Bool
            didAccessValue(forKey: "isFile")
            return isFile
        }
        set {
            willChangeValue(forKey: "isFile")
            setPrimitiveValue(newValue, forKey: "isFile")
            didChangeValue(forKey: "isFile")
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case isFile
        case name
        case timeStamp
        case children
        case parent
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: "Folder")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(isFile, forKey: .isFile)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(timeStamp, forKey: .timeStamp)

        if let children = children {
            print("children cnt: \(children.count)")
            let array: [Folder] = Array(children)
            try container.encode(array, forKey: .children)
        }
//        try container.encode(children, forKey: .children)
//        try container.encode(parent, forKey: .parent)
    }

    public required convenience init(from decoder: Decoder) throws {
        guard let contextUserInfoKey = CodingUserInfoKey.managedObjectContext, let context = decoder.userInfo[contextUserInfoKey] as? NSManagedObjectContext else {
          throw DecoderConfigurationError.missingManagedObjectContext
        }

        self.init(context: context)

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(UUID.self, forKey: .id)
        self.isFile = try container.decode(Bool.self, forKey: .isFile)
        self.name = try container.decode(String.self, forKey: .name)
        self.timeStamp = try container.decodeIfPresent(Date.self, forKey: .timeStamp)
        self.children = try container.decode(Set<Folder>.self, forKey: .children)
//        self.parent = try container.decode(Folder.self, forKey: .parent)
    }
}

extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "context")
}

enum DecoderConfigurationError: Error {
  case missingManagedObjectContext
}
