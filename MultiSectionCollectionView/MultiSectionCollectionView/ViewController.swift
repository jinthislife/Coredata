//
//  ViewController.swift
//  MultiSectionCollectionView
//
//  Created by Jin Lee on 12/9/20.
//  Copyright © 2020 Jin Lee. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var datasource: UICollectionViewDiffableDataSource<String, Bookmark>!
    var fetchedResultsController: NSFetchedResultsController<Bookmark>!
    
    var appDelegate: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }
    
    var managedContext: NSManagedObjectContext {
        appDelegate.persistentContainer.viewContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeader.identifier)
        collectionView.register(FeaturedCell.self, forCellWithReuseIdentifier: FeaturedCell.identifier)
        configureLayout()
        configureDatasource()
        initFetchedResultsController()
    }
    
    func configureDatasource() {
        datasource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeaturedCell.identifier, for: indexPath) as! FeaturedCell
            cell.configure(with: item)
            return cell
        })
        
        datasource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            print(indexPath)
            //            if kind == UICollectionView.elementKindSectionHeader {
            guard let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeader.identifier, for: indexPath) as? SectionHeader else {
                fatalError("Cannot create new supplementary")
            }
            let section = self?.datasource.snapshot().sectionIdentifiers[indexPath.section]
            sectionHeader.title.text = section
            sectionHeader.subtitle.text = "Description here..."
            return sectionHeader
        }
        //        }
    }
    
    func initFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        //        fetchRequest.predicate = predicate ...
        //        let sortDescriptor1 = NSSortDescriptor(key: "category", ascending: true)
        let sortDescriptor2 = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor2]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: "folder.name", cacheName: nil)
        fetchedResultsController.delegate = self
        try! fetchedResultsController.performFetch()
    }
    
    func configureLayout() {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: {
            (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1/5),
                heightDimension: .fractionalWidth(1/5))
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 10)
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .groupPaging // 이거 빠뜨리니까 버티컬 스크롤로 나와서 헤멤 ㅜ
            section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 0)
            section.interGroupSpacing = 10
            
            let headerFooterSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(20)
            )
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerFooterSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [sectionHeader]
            return section
        })
        layout.configuration = UICollectionViewCompositionalLayoutConfiguration()
        collectionView.collectionViewLayout = layout
    }
    
    @IBAction func addBookmark(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "New Folder", message: "Add a new folder", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) {
            [unowned self] action in
            
            guard let textField = alert.textFields?.first, let folder = textField.text, let itemInfo = alert.textFields?.last?.text else {
                return
            }
            self.save(folderName: folder, itemInfo: itemInfo)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addTextField { textfield in
            textfield.placeholder = "Folder"
        }
        alert.addTextField { textfield in
            textfield.placeholder = "Item"
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func save(folderName: String, itemInfo: String) {
        
        let bookmark = NSEntityDescription.insertNewObject(forEntityName: "Bookmark", into: managedContext) as! Bookmark
        bookmark.setValue(itemInfo, forKey: "name")
        
        let fetchRequest: NSFetchRequest<Folder> = Folder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", folderName)
        let fetchedFolders = try? managedContext.fetch(fetchRequest)
        
        if let fetchedFolder = fetchedFolders?.first {
            fetchedFolder.addToBookmark(bookmark)
//            bookmark.folder = fetchedFolder
        } else {
            let newFolder = NSEntityDescription.insertNewObject(forEntityName: "Folder", into: managedContext) as! Folder
            newFolder.name = folderName
            newFolder.addToBookmark(bookmark)
//            bookmark.folder = newFolder
        }
        appDelegate.saveContext()
    }
    
    @IBAction func deleteAll(_ sender: UIBarButtonItem) {
        
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Bookmark")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        deleteRequest.resultType = .resultTypeObjectIDs

        do {
            let result = try managedContext.execute(deleteRequest) as? NSBatchDeleteResult
            if let objectIDArray = result?.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDArray], into: [managedContext])
            }
        } catch {
            fatalError("Failed to execute request: \(error)")
        }
    }
    
    private func deleteAllEntities() {
        let entityNames = appDelegate.persistentContainer.managedObjectModel.entities.map({ $0.name!})
        entityNames.forEach { entityName in
            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
            deleteRequest.resultType = .resultTypeObjectIDs

            do {
                let result = try managedContext.execute(deleteRequest) as? NSBatchDeleteResult
                if let objectIDArray = result?.result as? [NSManagedObjectID] {
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDArray], into: [managedContext])
                }
            } catch {
                fatalError("Failed to execute request: \(error)")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let sectionHeader = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: SectionHeader.identifier,
                for: indexPath) as? SectionHeader
                else {
                    fatalError("Invalid view type")
            }
            sectionHeader.title.text = "new folder"
            sectionHeader.subtitle.text = "CollectionView Delegate"
            
            return sectionHeader
            
        default:
            assert(false, "Invalid element type")
        }
    }
    
}

extension ViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        
        var snapshot = NSDiffableDataSourceSnapshot<String, Bookmark>()
        
        if let sectionInfo = fetchedResultsController.sections {
            for section in sectionInfo {
                snapshot.appendSections([section.name])
                let items = section.objects
                snapshot.appendItems(items as! [Bookmark])
            }
        }
        //        let folders = fetchedResultsController.sections ?? []
        //        snapshot.appendSections(folders)
        //
        //        folders.forEach { (folder: Folder) in
        
        //            let bookmarks = folder.bookmark.array(of: Bookmark.self)
        //            snapshot.appendItems(bookmarks)
        //        }
        
        datasource?.apply(snapshot)
    }
    
}

extension Optional where Wrapped == NSSet {
    func array<T: Hashable>(of: T.Type) -> [T] {
        if let set = self as? Set<T> {
            return Array(set)
        }
        return [T]()
    }
}
