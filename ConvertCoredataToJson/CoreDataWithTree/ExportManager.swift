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
            strongSelf.processRecords()
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
   
    private func processRecords() {
        if folders.count > 0{
            print("Processing: \(folders.count)")
           
            var unProcessedFolders : [Folder] = []
           
            for folder in folders {
               
                myid +=  1
               
                folder.myid = myid
               
                processedFolders.append(folder)
                let currentParentId = myid
               
                if let children = folder.children?.allObjects {
                   
                    if !children.isEmpty {
                       
                        let childrenArray = children as! [Folder]
                       
                        for child in childrenArray{
                            myid += 1
                            child.myid = myid
                            child.parentid = currentParentId
                            unProcessedFolders.append(child)
                        }
                    }
                }
            }
           
            folders = unProcessedFolders
            processRecords()
        } else {
            print("Finish Processing: \(processedFolders.count)")
            do{
                let documentDirectoryURL =  try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let jsonURL = URL(fileURLWithPath: "folders", relativeTo: documentDirectoryURL.appendingPathComponent("Folders")).appendingPathExtension("json")
               
                print("jsonURL: \(jsonURL)")
               
                let jsonEncoder = JSONEncoder()
                jsonEncoder.outputFormatting = .prettyPrinted
                let jsonData = try jsonEncoder.encode(processedFolders)
                try jsonData.write(to: jsonURL)
                
                print("Exported dadta: \(String(data: jsonData, encoding: .utf8))")
                exportHandler()
            } catch let error as NSError{
                print("Error: \(error.description)")
            }
        }
    }
}
