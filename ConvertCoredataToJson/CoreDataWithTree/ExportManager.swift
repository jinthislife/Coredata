//
//  ExportManager.swift
//  CoreDataWithTree
//
//  Created by Jin Lee on 30/9/20.
//

import Foundation
import CoreData

class ExportManager{
    var exportHandler: (() -> Void)!

    private var managedObjectContext: NSManagedObjectContext!
   
    private var myid : Int16 = 0
   
    private var folders : [Folder] = []
    private var processedFolders : [Folder] = []
   
    init(managedObjectContext:NSManagedObjectContext){
        self.managedObjectContext = managedObjectContext
    }
   
    func exportData(){
        executeFetchRequest(){ [weak self] in
            guard let strongSelf = self else { return }
            print("strongSelf.subjects.count: \(strongSelf.folders.count)")

            strongSelf.encodeToJson()
        }
    }
  
    private func encodeToJson() {
        do{
            let documentDirectoryURL =  try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let jsonURL = URL(fileURLWithPath: "folders", relativeTo: documentDirectoryURL.appendingPathComponent("Folders")).appendingPathExtension("json")
           
            print("jsonURL: \(jsonURL)")
           
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            let jsonData = try jsonEncoder.encode(folders)
            try jsonData.write(to: jsonURL)
            
            print("Exported dadta: \(String(data: jsonData, encoding: .utf8))")
            exportHandler()
        } catch let error as NSError{
            print("Error: \(error.description)")
        }
    }
    
    private func executeFetchRequest(completion:@escaping () -> ()){
        let fetchRequest: NSFetchRequest<Folder> = Folder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "parent == NULL")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.relationshipKeyPathsForPrefetching = ["children"]
        managedObjectContext.perform {
            self.folders = try! fetchRequest.execute()
            completion()
        }
    }
}
