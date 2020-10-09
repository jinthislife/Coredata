//
//  ImportManager.swift
//  CoreDataWithTree
//
//  Created by Jin Lee on 30/9/20.
//
import Foundation
import CoreData

class ImportManager{
    var managedObjectContext: NSManagedObjectContext!
  
    init(managedObjectContext:NSManagedObjectContext){
        self.managedObjectContext = managedObjectContext
    }

    func importData(completion:@escaping () -> ()){

//        guard let url = Bundle.main.url(forResource: "folders", withExtension: "json") else { fatalError("no file") }
        do{
            let documentDirectoryURL =  try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let jsonURL = URL(fileURLWithPath: "folders", relativeTo: documentDirectoryURL.appendingPathComponent("Folders")).appendingPathExtension("json")
            
            let json = try Data(contentsOf: jsonURL)
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext!] = managedObjectContext
            print(String(data: json, encoding: .utf8))
            do{
                let folders = try decoder.decode([Folder].self, from: json)

                for folder in folders where folder.parentid != 0{
                    guard let parentid = folder.parentid else { fatalError("Can not get parentid") }
                    guard let parent = (folders.filter { $0.myid == parentid }.first) else { fatalError("Can not get parent") }
                    folder.parent = parent
                }
                
                do {
                    try managedObjectContext.save()
                        completion()
                } catch {
                    print("Export Error 1")
                       completion()
                }
            }catch{
                print("Export Error 2\n\(error)")
                completion()
            }
        } catch {
            print("Export Error 3")
            completion()
        }
    }
}
