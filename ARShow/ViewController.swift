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

class ViewController: UIViewController, CLLocationManagerDelegate, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    let locationManager = CLLocationManager()
    var planeDict : [UUID : Plane] = [:]
    var objectScene : SCNScene = SCNScene()
    var sunLightSource : SCNLight = SCNLight()
    var sunLightNode : SCNNode = SCNNode()
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
        
        // Change debug options for featurePoints and worldOrigin
        //        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        
        //        let env : UIImage = UIImage(named: "./Models.scnassets/sharedImages/spherical.jpg")!
        //        self.sceneView.scene.lightingEnvironment.contents = env;
        
        
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
    
    var y = 0
    func updateSun() {
        sunLightNode.removeFromParentNode()
        
        let date = Date()
        let calendar = Calendar.current
        let timezone = calendar.timeZone.secondsFromGMT()/3600
        
        
        newSolarCalculator.day = calendar.component(.day, from: date)
        newSolarCalculator.month = calendar.component(.month, from: date)
        newSolarCalculator.year = calendar.component(.year, from: date)
        newSolarCalculator.latitude = Double(currentLatitude)
        newSolarCalculator.longitude = Double(currentLongitute)
        newSolarCalculator.timezone = Double(timezone)
        newSolarCalculator.hour = y % 24
        y += 1
        print( y % 24)
            //calendar.component(.hour, from: date)
        newSolarCalculator.minute = calendar.component(.minute, from: date)
        newSolarCalculator.second = Double(calendar.component(.second, from: date))
        newSolarCalculator.elevation = 0
        
        print(newSolarCalculator.spa_calculate())
        
        sunLightSource.intensity = 1000
        
        let xRadian = (180 + newSolarCalculator.zenith)*(Double.pi/180)
        let yRadian = -newSolarCalculator.azimuth * (Double.pi/180)
        
        sunLightNode.eulerAngles = SCNVector3Make(Float(xRadian), Float(yRadian), 0)
        
        //Float(Double.pi + (Double.pi/2 - newSolarCalculator.zenith*(Double.pi/180)))
        //Float(-newSolarCalculator.azimuth*(Double.pi/180))
        
        self.sceneView.scene.rootNode.addChildNode(sunLightNode)

    }
    
    weak var timer: Timer?
    
    func startTimer() {
        timer?.invalidate()   // just in case you had existing `Timer`, `invalidate` it before we lose our reference to it
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
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
    
    func sessionSimpleDownload(urlString: String) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("test.scn")
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Alamofire.download(urlString, to: destination).response { response in
            print(response)
            
            if response.error == nil, let scnPath = response.destinationURL?.path {
                do {
                    self.objectScene = try SCNScene(url: fileURL, options: nil)
                } catch {
                    print("Lame")
                }

            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        sessionSimpleDownload(urlString: "http://127.0.0.1:5000/static/chair.scn")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        currentLatitude = locValue.latitude
        currentLongitute = locValue.longitude
    }
    
    func randomFloat(min: Float, max: Float) -> Float {
        return (Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }
    
    
    func insertSpotlight(position : SCNVector3) {
        let spotlight : SCNLight = SCNLight()
        spotlight.type = SCNLight.LightType.directional
        spotlight.shadowMode = .forward
        spotlight.castsShadow = true
        spotlight.intensity = 1000
        
        let spotNode : SCNNode = SCNNode()
        spotNode.light = spotlight
        spotNode.position = position
        
        spotNode.eulerAngles = SCNVector3Make(-Float.pi / 4, 0, 0)
        
        self.sceneView.scene.rootNode.addChildNode(spotNode)
        
        //        let ambientlight : SCNLight = SCNLight()
        //        ambientlight.type = SCNLight.LightType.ambient
        //        ambientlight.intensity = 500
        //
        //        let ambientNode : SCNNode = SCNNode()
        //        ambientNode.light = ambientlight
        //        ambientNode.position = position
        //
        //        ambientNode.eulerAngles = SCNVector3Make(-Float.pi / 2, 0, 0)
        //
        //        self.sceneView.scene.rootNode.addChildNode(ambientNode)
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
    
    
    @IBAction func addCube(_ sender: Any) {
        
        let cZ = randomFloat(min: -2, max: -0.2)
        let cubeBox = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        
        let mat = SCNMaterial()
        mat.lightingModel = SCNMaterial.LightingModel.physicallyBased
        
        mat.diffuse.contents = UIImage(named: "./Models.scnassets/Materials/carvedlimestoneground/carvedlimestoneground-albedo.png")
        mat.roughness.contents = UIImage(named: "./Models.scnassets/Materials/carvedlimestoneground/carvedlimestoneground-roughness.png")
        mat.metalness.contents = UIImage(named: "./Models.scnassets/Materials/carvedlimestoneground/carvedlimestoneground-metal.png")
        mat.normal.contents = UIImage(named: "./Models.scnassets/Materials/carvedlimestoneground/carvedlimestoneground-normal.png")
        
        mat.diffuse.wrapS = .repeat;
        mat.diffuse.wrapT = .repeat;
        mat.roughness.wrapS = .repeat;
        mat.roughness.wrapT = .repeat;
        mat.metalness.wrapS = .repeat;
        mat.metalness.wrapT = .repeat;
        mat.normal.wrapS = .repeat;
        mat.normal.wrapT = .repeat;
        
        cubeBox.materials = [mat]
        
        let cubeNode = SCNNode(geometry: cubeBox)
        
        let cc = getCameraCoordinates(sceneView: sceneView)
        cubeNode.position = SCNVector3(cc.x, cc.y, cc.z)
        //cubeNode.position = SCNVector3(0, 0, cZ)
        
        sceneView.scene.rootNode.addChildNode(cubeNode)
        
        let spotlightPosition = SCNVector3(cc.x, cc.y + 0.5, cc.z)
        insertDirectionalLight(position: spotlightPosition)
    }
    
    @IBAction func addCup(_ sender: Any) {
        let cupNode = SCNNode()
        
        let cc = getCameraCoordinates(sceneView: sceneView)
        cupNode.position = SCNVector3(cc.x, cc.y, cc.z)
        
        guard let virtualObjectScene = SCNScene(named: "cup.scn", inDirectory: "Models.scnassets/cup") else {
            return
        }
        
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            wrapperNode.addChildNode(child)
        }
        cupNode.addChildNode(wrapperNode)
        
        sceneView.scene.rootNode.addChildNode(cupNode)
    }
    
    @IBAction func addChair(_ sender: Any) {
        let chairNode = SCNNode()
        
        let cc = getCameraCoordinates(sceneView: sceneView)
        chairNode.position = SCNVector3(cc.x, cc.y, cc.z)
        
        guard let virtualObjectScene = SCNScene(named: "chair.scn", inDirectory: "Models.scnassets/chair") else {
            return
        }
        
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            wrapperNode.addChildNode(child)
        }
        chairNode.addChildNode(wrapperNode)
        
        sceneView.scene.rootNode.addChildNode(chairNode)
        
        let position = SCNVector3(cc.x, cc.y + 0.5, cc.z)
        insertDirectionalLight(position: position)
    }
    
    @IBAction func addCandle(_ sender: Any) {
        let position : SCNVector3 = SCNVector3Make(0, 0, 0)
        insertDirectionalLight(position: position)
    }
    
    @IBAction func addLamp(_ sender: Any) {
        let lampNode = SCNNode()
        
        let cc = getCameraCoordinates(sceneView: sceneView)
        lampNode.position = SCNVector3(cc.x + 10, cc.y, cc.z)
        
        guard let virtualObjectScene = SCNScene(named: "Building.scn", inDirectory: "Models.scnassets/Building5") else {
            return
        }
        
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            wrapperNode.addChildNode(child)
        }
        lampNode.addChildNode(wrapperNode)
        
        sceneView.scene.rootNode.addChildNode(lampNode)
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            
            let chairNode = SCNNode()
            //            let cube : SCNBox = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
            //            let node : SCNNode = SCNNode(geometry: cube)
            //            node.position = SCNVector3(x, y + 0.05, z)
            
            chairNode.position = SCNVector3(x, y, z)
            
            guard let virtualObjectScene = SCNScene(named: "chair.scn", inDirectory: "Models.scnassets/chair") else {
                return
            }
//            let virtualObjectScene = self.objectScene
            
            let wrapperNode = SCNNode()
            for child in virtualObjectScene.rootNode.childNodes {
                child.geometry?.firstMaterial?.lightingModel = .physicallyBased
                wrapperNode.addChildNode(child)
            }
            chairNode.addChildNode(wrapperNode)
            
            sceneView.scene.rootNode.addChildNode(chairNode)
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
}


