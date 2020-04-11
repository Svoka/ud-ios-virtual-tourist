//
//  AlbumViewController.swift
//  VirtualTourist
//
//  Created by Artem Osipov on 10/04/2020.
//  Copyright © 2020 Artem Osipov. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "PhotoViewCell"

class AlbumViewController: UICollectionViewController {
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    
    var dataController: DataController {
       let object = UIApplication.shared.delegate
       let appDelegate = object as! AppDelegate
       return appDelegate.dataController
    }
    
    var apiClient: ApiClient {
       let object = UIApplication.shared.delegate
       let appDelegate = object as! AppDelegate
       return appDelegate.apiClient
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UINib.init(nibName: "PhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        

        setupFetchedResultsController()
        checkIfNeedNetworkRequest()
    }

    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin.latitude)-\((pin.longitude))-albums")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func checkIfNeedNetworkRequest() {
        if (fetchedResultsController.sections![0].numberOfObjects == 0) {
            loadDataFromNetwork(page: 1)
        }
        
    }
    
    func loadDataFromNetwork(page: Int) {
        apiClient.loadList(latitude: pin.latitude, longitude: pin.longitude, page: page) { (photosWithPages, error) in
            guard error == nil else {self.showAlert(alertMessage: self.getAlertDataFromError(error: error!), buttonTitle: "Ok", presenter: self); return}
            
            DispatchQueue.main.async {
               
                self.pin.removeFromPhotos(self.pin.photos!)
                self.pin.pagesCount = Int32(photosWithPages!.pages)
                try? self.dataController.viewContext.save()
//            
                photosWithPages!.photos.forEach({ (photo) in
                    photo.pin = self.pin
                    self.apiClient.loadPhoto(photo: photo) { (data, error) in
                        if (error != nil) {print(error); return}
                        photo.photo = data
                        DispatchQueue.main.async {
                            try? self.dataController.backgroundContext.save()
                        }
                    }
                })
                try? self.dataController.viewContext.save()
            }
        }
    }
    
    func deletePhoto(photo: Photo) {
        dataController.viewContext.delete(photo)
        try? self.dataController.viewContext.save()
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
       return fetchedResultsController.sections?.count ?? 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.object(at: indexPath)
        if (photo.photo != nil) {
            cell.imageView.image = UIImage(data: photo.photo!)
            cell.progress.isHidden = true
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dataController.viewContext.delete(fetchedResultsController.object(at: indexPath))
        try? dataController.viewContext.save()
    }


    @IBAction func reloadPins(_ sender: Any) {
        loadDataFromNetwork(page: Int(arc4random_uniform(UInt32(pin!.pagesCount))))
    }
    
}


extension AlbumViewController:NSFetchedResultsControllerDelegate {
    

    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(newIndexPath!)
        default:
            // do nothing
            print("unsupported operation")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
        }, completion: nil)
    }
    
}
