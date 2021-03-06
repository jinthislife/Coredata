//
//  FolderViewController.swift
//  CoreDataWithTree
//
//  Created by Jin Lee on 28/9/20.
//

import UIKit
import CoreData

class FolderViewController: UIViewController {
    
    private var exportManager: ExportManager!
    private var importManager: ImportManager!
    var parentFolder: Folder?
    
    var appDelegate: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }
    
    var managedContext: NSManagedObjectContext {
        appDelegate.persistentContainer.viewContext
    }
    
    lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private lazy var frc: NSFetchedResultsController<Folder> = {
        let fetchRequest: NSFetchRequest<Folder> = Folder.fetchRequest()
        
        if let parent = parentFolder {
            fetchRequest.predicate = NSPredicate(format: "parent == %@", parent)
        } else {
            fetchRequest.predicate = NSPredicate(format: "parent == nil")
        }
        let sd1 = NSSortDescriptor(key: "isFile", ascending: true)
        let sd2 = NSSortDescriptor(key: "name", ascending: false)
        fetchRequest.sortDescriptors = [sd1, sd2]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        
        importManager = ImportManager(managedObjectContext: managedContext)
        exportManager = ExportManager(managedObjectContext: managedContext)
        exportManager.exportHandler = {
            print("Finish export data")
        }
        title = parentFolder?.name ?? "Root"
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "folder.fill"), style: .plain, target: self, action: #selector(addFolder)),
            UIBarButtonItem(image: UIImage(systemName: "doc.fill"), style: .plain, target: self, action: #selector(addFile))
        ]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
        
        do {
            try frc.performFetch()
            tableView.reloadData()
        } catch {
            print(error)
        }
        
        
    }
    
    func save(name: String, isFile: Bool) {
        
        let entity = NSEntityDescription.entity(forEntityName: "Folder", in: managedContext)!
        let folder = NSManagedObject(entity: entity, insertInto: managedContext)
        
        folder.setValue(name, forKeyPath: "name")
        folder.setValue(isFile, forKeyPath: "isFile")
        folder.setValue(parentFolder, forKey: "parent")
        
        appDelegate.saveContext()
    }
    
    func copyAndPaste(object: NSManagedObject?) {
        guard let object = object else {
            print("object is empty")
            return
        }
        let objectCopy = object.copyEntireObjectGraph(context: managedContext, excluding: parentFolder)
        
        objectCopy.setValue(parentFolder, forKey: "parent")
        
        appDelegate.saveContext()
    }
    
    func showEidtAlert(for item: String) {
        let alert = UIAlertController(title: "New \(item)",
                                      message: "Add \(item) name",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) {
            [unowned self] action in
            guard let textField = alert.textFields?.first,
                  let name = textField.text else {
                return
            }
            self.save(name: name, isFile: (item == "File"))
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addTextField { textfield in
            textfield.placeholder = "\(item) name"
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    @objc func addFolder() {
        showEidtAlert(for: "Folder")
    }
    
    @objc func addFile() {
//        showEidtAlert(for: "File")
//        exportManager.exportData()
        importData()
    }

    func importData() {
        print("import data ... ")
            importManager.importData(){ [weak self] in
                guard let strongSelf = self else { return }
                do {
                    try strongSelf.frc.performFetch()
                    strongSelf.tableView.reloadData()
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
}

extension FolderViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        frc.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let folder = frc.object(at: indexPath)
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell") else {
            fatalError("Could not dequeue UITableViewCell")
        }
        
        cell.imageView?.image = nil // reset for reuse
        if folder.isFile == false {
            cell.imageView?.image = UIImage(systemName: "folder.fill")
        }
        cell.textLabel?.text = folder.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let folder = frc.object(at: indexPath)
        
        guard let isFile = folder.isFile, !isFile else {
            return
        }
        
        let vc = FolderViewController()
        vc.parentFolder = folder
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let bookmark = frc.object(at: indexPath)
            managedContext.delete(bookmark)
            appDelegate.saveContext()
        }
    }
    
    func tableView(_ tableView: UITableView,
                            contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint)
    -> UIContextMenuConfiguration? {
        
        let copiedObject = frc.object(at: indexPath)
        let identifier = "\(indexPath.row)" as NSString
    
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
            let copyAction = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { [weak self] action in
                self?.copyAndPaste(object: copiedObject)
            }
            return UIMenu(title: "", image: nil, children: [copyAction])
        }
    }
    
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
      guard let identifier = configuration.identifier as? String,
        let index = Int(identifier),
        let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
        else {
          return nil
      }
      
      return UITargetedPreview(view: cell)
    }

}

extension FolderViewController: NSFetchedResultsControllerDelegate {
    
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

