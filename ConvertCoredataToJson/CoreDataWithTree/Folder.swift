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
    public var myid: Int16?
    public var parentid: Int16?
    @NSManaged public var id: UUID?
//    @NSManaged public var isFile: Bool?
    @NSManaged public var name: String?
    @NSManaged public var timeStamp: Date?
    @NSManaged public var children: NSSet?
    @NSManaged public var parent: Folder?
    
    public var isFile: Bool? {
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
        case myid
        case parentid
        case id
        case isFile
        case name
        case timeStamp
        case shortdescription
        case longdescription
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: "Folder")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(myid ?? 0, forKey: .myid)
        try container.encode(parentid ?? 0, forKey: .parentid)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(isFile, forKey: .isFile)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(timeStamp, forKey: .timeStamp)
    }

    public required convenience init(from decoder: Decoder) throws {
        guard let contextUserInfoKey = CodingUserInfoKey.managedObjectContext, let context = decoder.userInfo[contextUserInfoKey] as? NSManagedObjectContext else {
          throw DecoderConfigurationError.missingManagedObjectContext
        }

        self.init(context: context)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.myid = try container.decode(Int16?.self, forKey: .myid)
        self.parentid = try container.decode(Int16?.self, forKey: .parentid)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id)
        self.isFile = try container.decode(Bool.self, forKey: .isFile)
        self.name = try container.decode(String.self, forKey: .name)
        self.timeStamp = try container.decodeIfPresent(Date.self, forKey: .timeStamp)
    }
}

extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "context")
}

enum DecoderConfigurationError: Error {
  case missingManagedObjectContext
}
//@objc(Folder)
//public class Folder: NSManagedObject, Codable {
//    enum CodingKeys: CodingKey  {
//        case id, isFile, name, timeStamp
//    }
//
//    required convenience init(from decoder: Decoder) throws {
//        guard let contextUserInfoKey = CodingUserInfoKey.managedObjectContext, let context = decoder.userInfo[contextUserInfoKey] as? NSManagedObjectContext else {
//          throw DecoderConfigurationError.missingManagedObjectContext
//        }
//
//        self.init(context: context)
//
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.id = try container.decode(UUID.self, forKey: .id)
//        self.isFile = try container.decode(Bool.self, forKey: .isFile)
//        self.name = try container.decode(String.self, forKey: .name)
//        self.timeStamp = try container.decode(Date.self, forKey: .timeStamp)
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//        try container.encode(isFile, forKey: .isFile)
//        try container.encode(name, forKey: .name)
//        try container.encode(timeStamp, forKey: .timeStamp)
//    }
//}
//
//extension CodingUserInfoKey {
//    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")
//}
