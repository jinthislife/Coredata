//
//  NodeListViewController.swift
//  CoreDataWithAbstractEntity
//
//  Created by Jin Lee on 11/10/20.
//

import UIKit
import CoreData

class NodeListViewController: UIViewController {
    
    var parentTopic: Topic?
    
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
    
    private lazy var frc: NSFetchedResultsController<Node> = {
//        let fetchRequest: NSFetchRequest<Node> = Node.fetchRequest()
        let fetchRequest = NSFetchRequest<Node>(entityName: "Node")
        
        if let parent = parentTopic {
            fetchRequest.predicate = NSPredicate(format: "parent == %@", parent)
        } else {
            fetchRequest.predicate = NSPredicate(format: "parent == nil")
        }
        let sd1 = NSSortDescriptor(key: "createdAt", ascending: false)
        let sd2 = NSSortDescriptor(key: "title", ascending: false)
        fetchRequest.sortDescriptors = [sd1, sd2]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        
        title = parentTopic?.title ?? "Root"
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
    
    func save(name: String, isItem: Bool) {
        
//        let entity = NSEntityDescription.entity(forEntityName: "Node", in: managedContext)!
        var entity: NSEntityDescription
        if isItem {
            entity = NSEntityDescription.entity(forEntityName: "Item", in: managedContext)!
        } else {
            entity = NSEntityDescription.entity(forEntityName: "Topic", in: managedContext)!
        }
        
        let folder = NSManagedObject(entity: entity, insertInto: managedContext)
        
        folder.setValue(name, forKeyPath: "title")
        folder.setValue(parentTopic, forKey: "parent")
        
        appDelegate.saveContext()
    }
    
    func copyAndPaste(object: NSManagedObject?) {
        guard let object = object else {
            print("object is empty")
            return
        }
        let objectCopy = object.copyEntireObjectGraph(context: managedContext, excluding: parentTopic)
        
        objectCopy.setValue(parentTopic, forKey: "parent")
        
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
            self.save(name: name, isItem: (item == "Item"))
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
        showEidtAlert(for: "Topic")
    }
    
    @objc func addFile() {
        showEidtAlert(for: "Item")
    }
    
}

extension NodeListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        frc.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let object = frc.object(at: indexPath)
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell") else {
            fatalError("Could not dequeue UITableViewCell")
        }
        
        cell.imageView?.image = nil // reset for reuse
        if let _ = object as? Topic {
            cell.imageView?.image = UIImage(systemName: "folder.fill")
        }
        cell.textLabel?.text = object.title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let object = frc.object(at: indexPath)
        
        guard let node = object as? Topic else {
            return
        }
        
        let vc = NodeListViewController()
        vc.parentTopic = node
        
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

extension NodeListViewController: NSFetchedResultsControllerDelegate {
    
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


