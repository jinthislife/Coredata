//
//  ViewController.swift
//  CollectionViewWithCoreData
//
//  Created by Jin Lee on 12/9/20.
//  Copyright © 2020 Jin Lee. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var appDelegate: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }

    var managedContext: NSManagedObjectContext {
        appDelegate.persistentContainer.viewContext
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Bookmark> = {
        let fetchRequest: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        //        fetchRequest.predicate = predicate ...
        let sortDescriptor1 = NSSortDescriptor(key: "category", ascending: true)
        let sortDescriptor2 = NSSortDescriptor(key: "mainText", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor1, sortDescriptor2]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: "category", cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Bookmarks"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print(error)
        }
    }
    
    @IBAction func addCategory(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "New Category",
                                      message: "Add a new category",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) {
            [unowned self] action in
            
            guard let textField = alert.textFields?.first,
                let newCategory = textField.text, let itemInfo = alert.textFields?.last?.text else {
                    return
            }
            
            
            self.save(category: newCategory, itemInfo: itemInfo)
            //            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addTextField { textfield in
            textfield.placeholder = "Category"
        }
        alert.addTextField { textfield in
            textfield.placeholder = "Item"
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func save(category: String, itemInfo: String) {
        
        let entity = NSEntityDescription.entity(forEntityName: "Bookmark",
                                                in: managedContext)!
        let bookmark = NSManagedObject(entity: entity,
                                       insertInto: managedContext)
        
        bookmark.setValue(category, forKeyPath: "category")
        bookmark.setValue(itemInfo, forKey: "mainText")
        
        appDelegate.saveContext()
    }
    
}

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        fetchedResultsController.sections?[section].name ?? ""
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bm = fetchedResultsController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = bm.value(forKeyPath: "mainText") as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let bookmark = fetchedResultsController.object(at: indexPath)
            managedContext.delete(bookmark)
            appDelegate.saveContext()
        }
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let section = IndexSet(integer: sectionIndex)
        
        switch type {
        case .delete:
            tableView.deleteSections(section, with: .automatic)
        case .insert:
            tableView.insertSections(section, with: .automatic)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?){
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        case .update:
            if let indexPath = indexPath {
                tableView.reloadRows(at: [indexPath], with: .top)
                //                let row = indexPath.item
                //                for column in 0..<tableView.numberOfColumns {
                //                    if let cell = tableView.view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView {
                //                        configureCell(cell: cell, row: row, column: column)
                //                    }
                //                }
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        @unknown default:
            fatalError("unknown case")
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
