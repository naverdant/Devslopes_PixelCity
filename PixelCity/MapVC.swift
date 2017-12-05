//
//  MapVC.swift
//  PixelCity
//
//  Created by Perfect on 2017/12/4.
//  Copyright © 2017年 Alex. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Alamofire
import AlamofireImage

class MapVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    
    let regionRadius: Double = 3000
    let screenSize = UIScreen.main.bounds
    
    var progressLbl: UILabel?
    var spinner: UIActivityIndicatorView?
    
    var collectionView: UICollectionView?
    var layoutFlow = UICollectionViewFlowLayout()
    
    var imageUrlArray = [String]()
    var imageArray = [Image]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        mapView.delegate = self
        configureLocationService()
        addDoubleTap()
        addSwipe()
        addCollectionView()
    }

    @IBAction func centerMapBtnWasPressed(_ sender: UIButton) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }

    func centerMapOnUserLocation() {
        
        if let coordinate = locationManager.location?.coordinate {
            let region = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius, regionRadius)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(gesture: )))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func addCollectionView() {
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: screenSize.size.width, height: screenSize.size.height/3), collectionViewLayout: layoutFlow)
        print(view.frame)
        print("addCollectionView")
        print(CGRect(x: 0, y: 0, width: screenSize.size.width, height: screenSize.size.height/3))
//        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layoutFlow)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.backgroundColor = UIColor.clear
        pullUpView.addSubview(collectionView!)
    }
    
    func dropPin(gesture: UITapGestureRecognizer) {
        removePin()
        removeProgressLabel()
        removeSpinner()
        
        
        let tapPoint = gesture.location(in: mapView)
        let tapCoordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)

        let pinRegion = MKCoordinateRegionMakeWithDistance(tapCoordinate, regionRadius, regionRadius)
        mapView.setRegion(pinRegion, animated: true)
        
        let annotation = DroppablePin(coordinate: tapCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
    
        retrieveUrls(forAnnotation: annotation) { (finished) in
            if finished {
                self.retrieveImages(completion: { (finished) in
                    if finished {
                        self.removeProgressLabel()
                        self.removeSpinner()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
        animateViewUp()
        addProgressLabel()
        addSpinner()
    }
    
    func removePin() {
        for annnotation in mapView.annotations {
            mapView.removeAnnotation(annnotation)
        }
    }
    
    func animateViewUp() {
        pullUpViewHeightConstraint.constant = screenSize.size.height / 3
        UIView.animate(withDuration: 0.4) { 
            self.view.layoutIfNeeded()
        }
    }
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(annimateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
//        collectionView?.addGestureRecognizer(swipe)
    }
    
    func annimateViewDown() {
        pullUpViewHeightConstraint.constant = 1
        UIView.animate(withDuration: 0.4) { 
            self.view.layoutIfNeeded()
        }
    }
    
    func addProgressLabel() {
        progressLbl = UILabel(frame: CGRect(x: pullUpView.bounds.size.width/2 - 100, y: pullUpView.bounds.size.height/2 - 25, width: 200, height: 50))
        progressLbl?.text = "Photos loading..."
        progressLbl?.textAlignment = .center
        progressLbl?.font = UIFont(name: "Avenir Next", size: 15)
        progressLbl?.textColor = UIColor.white
        collectionView?.addSubview(progressLbl!)
    }
    
    func removeProgressLabel() {
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
    }
    
    func addSpinner() {
        spinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
        spinner?.center = CGPoint(x: pullUpView.bounds.size.width/2, y: pullUpView.bounds.size.height/2 - 50)
        spinner?.color = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func retrieveUrls(forAnnotation annotation: DroppablePin, completion: @escaping (_ finished: Bool) -> () ) {
        imageUrlArray.removeAll()
        Alamofire.request(flickrUrl(forApiKey: apiKey, withAnnotation: annotation, andNumberOfPhotots: 35)).responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String, AnyObject> else {
                completion(false)
                return
            }
            let photosDict = json["photos"] as! Dictionary<String, AnyObject>
            let photoArray = photosDict["photo"] as! [Dictionary<String, AnyObject>]
            for photo in photoArray {
                let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                self.imageUrlArray.append(postUrl)
            }
            completion(true)
        }
    }
    
    func retrieveImages(completion: @escaping (_ finished: Bool) -> ()) {
        imageArray.removeAll()
        for url in imageUrlArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                guard let image = response.result.value else { return }
                self.imageArray.append(image)
                self.progressLbl?.text = "\(self.imageArray.count)/5 PHOTOS DOWNLOADED!"
                if self.imageUrlArray.count == self.imageArray.count {
                    completion(true)
                }
            })
        }
    }
    
    func cancelAllSession() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({$0.cancel()})
            //            // $0 means "task" in below lines:
            //            for task in sessionDataTask {
            //                task.cancel()
            //            }
            downloadData.forEach({$0.cancel()})
            
        }
    }
    
}

extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        
        let droppablePinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        droppablePinAnnotation.animatesDrop = true
        droppablePinAnnotation.pinTintColor = #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)
        return droppablePinAnnotation
    }
}

extension MapVC: CLLocationManagerDelegate {
    func configureLocationService() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }else { return }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

extension MapVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        let imageView = UIImageView(image: imageArray[indexPath.row])
        imageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        imageView.contentMode = .scaleAspectFit
//        imageView.clipsToBounds = true
        for subView in cell.subviews {
            subView.removeFromSuperview()
        }
        cell.addSubview(imageView)

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Did select collectionView")
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return }
        popVC.initData(forImage: imageArray[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
}
