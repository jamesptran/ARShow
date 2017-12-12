//
//  ViewController.swift
//  ARShow
//
//  Created by James Tran on 11/28/17.
//  Copyright © 2017 James Tran. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import MapKit
import CoreLocation
import Alamofire

protocol ObjectListProtocol {
    func receiveObject(object: String)
}

class ViewController: UIViewController, CLLocationManagerDelegate, ARSCNViewDelegate, UIPopoverPresentationControllerDelegate, ObjectListProtocol {
    
    @IBOutlet var sceneView: ARSCNView!
    let locationManager = CLLocationManager()
    var planeDict : [UUID : Plane] = [:]
    var objectScene : SCNScene = SCNScene()
    
    var sunLightSource : SCNLight = SCNLight()
    var sunLightNode : SCNNode = SCNNode()
    
    var ambientLightSource : SCNLight = SCNLight()
    var ambientLightNode : SCNNode = SCNNode()
    
    let newSolarCalculator = SolarCalculator()
    var currentLatitude : CLLocationDegrees = 0
    var currentLongitute : CLLocationDegrees = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        self.sceneView.autoenablesDefaultLighting = false
        self.sceneView.automaticallyUpdatesLighting = false
        
        configuration.isLightEstimationEnabled = false
        
        self.sceneView.delegate = self
        
        sunLightSource.type = .directional
        sunLightSource.shadowMode = .forward
        sunLightSource.castsShadow = true
        sunLightSource.intensity = 1000
        sunLightSource.shadowMode = .deferred
        
        sunLightNode.light = sunLightSource
        sunLightNode.position = SCNVector3Make(0, 0, 0)
        
        self.sceneView.scene.rootNode.addChildNode(sunLightNode)
        startTimer()
    }
    
    func updateSun() {
        sunLightNode.removeFromParentNode()
        
        let date = Date()
        let calendar = Calendar.current
        let timezone = calendar.timeZone.secondsFromGMT()/3600
        
        let hour = calendar.component(.hour, from: date)
        
        newSolarCalculator.day = calendar.component(.day, from: date)
        newSolarCalculator.month = calendar.component(.month, from: date)
        newSolarCalculator.year = calendar.component(.year, from: date)
        newSolarCalculator.latitude = Double(currentLatitude)
        newSolarCalculator.longitude = Double(currentLongitute)
        newSolarCalculator.timezone = Double(timezone)
        newSolarCalculator.hour = calendar.component(.hour, from: date)
        newSolarCalculator.minute = calendar.component(.minute, from: date)
        newSolarCalculator.second = Double(calendar.component(.second, from: date))
        newSolarCalculator.elevation = 0
        
        print(newSolarCalculator.spa_calculate())
        let sunsetTuple = newSolarCalculator.get_sunset_tuple()
        let sunriseTuple = newSolarCalculator.get_sunrise_tuple()
        
        // Change background contents with these three environments
        let sunSet = UIImage(named: "ParkingLotEnv.hdr")
        let sunHigh = UIImage(named: "Harbor_3_Free_Env.hdr")
        let sunBright = UIImage(named: "SkyCloudyEnv.hdr")
        
        //self.objectScene.lightingEnvironment.contents
        sunLightSource.shadowMode = .deferred
        if (calendar.component(.hour, from: date)) >= sunriseTuple.hour && (calendar.component(.hour, from: date)) < sunsetTuple.hour {
            let diff = (calendar.component(.hour, from: date)) - sunriseTuple.hour
            if diff < 3 {
                print("Sun has risen recently")
                sunLightSource.intensity = 800
                sceneView.scene.lightingEnvironment.contents = sunHigh
            } else if diff < 7 {
                print("Sun has risen in the middle")
                sunLightSource.intensity = 1200
                sceneView.scene.lightingEnvironment.contents = sunBright
            } else if diff < 10 {
                print("Sun is about to set")
                sunLightSource.intensity = 800
                sceneView.scene.lightingEnvironment.contents = sunSet
            }
            
        } else {
            print("Sun has set")
            sunLightSource.intensity = 0
            //sunLightSource.castsShadow = false
            sunLightSource.shadowMode = .forward
        }
        
        let xRadian = (180 + newSolarCalculator.zenith)*(Double.pi/180)
        let yRadian = -newSolarCalculator.azimuth * (Double.pi/180)
        
        sunLightNode.eulerAngles = SCNVector3Make(Float(xRadian), Float(yRadian), 0)
        
        self.sceneView.scene.rootNode.addChildNode(sunLightNode)
        
        
    }
    
    weak var timer: Timer?
    
    func startTimer() {
        timer?.invalidate()   // just in case you had existing `Timer`, `invalidate` it before we lose our reference to it
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSun()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    
    // if appropriate, make sure to stop your timer in `deinit`
    
    deinit {
        stopTimer()
    }
    
    func getAllChild(ofNode node: SCNNode) -> [SCNNode] {
        var a : [SCNNode] = []
        for child in node.childNodes {
            a.append(child)
            a += getAllChild(ofNode: child)
        }
        return a
    }
        
    
    func getObjectFromUrl(urlString: String) {
        let url = URL(string: urlString)
        do {
            self.objectScene = try SCNScene(url: url!, options: [.overrideAssetURLs: false])
        } catch {
            print("Error getting objects")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        currentLatitude = locValue.latitude
        currentLongitute = locValue.longitude
    }
    
    func insertDirectionalLight(position: SCNVector3) {
        let directionalLight : SCNLight = SCNLight()
        directionalLight.type = SCNLight.LightType.directional
        directionalLight.shadowMode = .forward
        directionalLight.castsShadow = true
        directionalLight.intensity = 1000
        directionalLight.shadowMode = .deferred
        
        let directionalNode : SCNNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.position = position
        
        directionalNode.eulerAngles = SCNVector3Make(-Float.pi / 4, 0, 0)
        
        self.sceneView.scene.rootNode.addChildNode(directionalNode)
    }
    
    struct myCameraCoordinates {
        var x = Float()
        var y = Float()
        var z = Float()
    }
    
    func getCameraCoordinates(sceneView: ARSCNView) -> myCameraCoordinates {
        let cameraTransform = sceneView.session.currentFrame?.camera.transform
        let cameraCoordinates = MDLTransform(matrix: cameraTransform!)
        
        var cc = myCameraCoordinates()
        cc.x = cameraCoordinates.translation.x
        cc.y = cameraCoordinates.translation.y
        cc.z = cameraCoordinates.translation.z
        
        return cc
    }
    
    @IBAction func selectCandle(_ sender: Any) {
        self.objectScene = SCNScene(named: "candle.scn", inDirectory: "Models.scnassets/candle")!
    }
    
    @IBAction func selectSword(_ sender: Any) {
        self.objectScene = SCNScene(named: "Sting-Sword-lowpoly.scn", inDirectory: "Models.scnassets/ATest")!
    }
    
    @IBAction func selectChair(_ sender: Any) {
        self.objectScene = SCNScene(named: "chair.scn", inDirectory: "Models.scnassets/chair")!
    }
    
    @IBAction func tap(_ sender: Any) {
        // Take the screen space tap coordinates and pass them to the
        // hitTest method on the ARSCNView instance
        if let tapRecognizer = sender as? UITapGestureRecognizer {
            let tapPoint : CGPoint = tapRecognizer.location(in: self.sceneView)
            
            let result : [ARHitTestResult] = self.sceneView.hitTest(tapPoint, types: .existingPlaneUsingExtent)
            
            if result.count == 0 {
                return
            }
            
            let hitResult = result.first
            let hitTransform = hitResult?.worldTransform
            let x : Float = (hitTransform?.columns.3.x)!
            let y : Float = (hitTransform?.columns.3.y)!
            let z : Float = (hitTransform?.columns.3.z)!
            
            let objectNode = SCNNode()
            objectNode.position = SCNVector3(x, y, z)
            
            let virtualObjectScene = self.objectScene
            
            let wrapperNode = SCNNode()
            for child in virtualObjectScene.rootNode.childNodes {
                child.geometry?.firstMaterial?.lightingModel = .physicallyBased
                wrapperNode.addChildNode(child)
            }
            objectNode.addChildNode(wrapperNode)
            
            sceneView.scene.rootNode.addChildNode(objectNode)
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        //let estimate : ARLightEstimate? = self.sceneView.session.currentFrame?.lightEstimate
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let anchorAsPlaneAnchor = anchor as? ARPlaneAnchor {
            let newPlane : Plane = Plane(with: anchorAsPlaneAnchor)
            
            self.planeDict[anchorAsPlaneAnchor.identifier] = newPlane
            
            node.addChildNode(newPlane)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let anchorAsPlaneAnchor = anchor as? ARPlaneAnchor {
            if let planeForAnchor = self.planeDict[anchorAsPlaneAnchor.identifier] {
                planeForAnchor.update(anchor: anchorAsPlaneAnchor)
            }
        }
    }
    
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    // Prepare for segue methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ObjectPopover" {
            let popoverViewController = segue.destination as! ObjectPopoverViewController
            
            popoverViewController.delegate = self
            
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
    }
    
    func receiveObject(object: String) {
        getObjectFromUrl(urlString: "http://hopper.cluster.earlham.edu:4848/static/" + object)
    }
}


