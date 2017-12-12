//
//  ObjectPopover.swift
//  ARShow
//
//  Created by James Tran on 12/9/17.
//  Copyright © 2017 James Tran. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

class ObjectPopoverViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    var objectList : [String] = []
    var delegate : ObjectListProtocol?
    
    override func viewDidLoad() {
        // Get object list from server.
        objectList.removeAll()
        
        let url = URL(string: "http://hopper.cluster.earlham.edu:4848/list")
        var contents : String = ""
        
        do {
            try contents = (String(contentsOf: url!))
            print(contents)
        } catch {
            print("Error getting list")
        }
        
        let contentArr = contents.split(separator: ",")
        for item in contentArr {
            objectList.append(String(item))
        }
        print(objectList)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objectList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ObjectCell") as! ObjectCell
        cell.objectNameLabel.text = objectList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let url = URL(string: "http://hopper.cluster.earlham.edu:4848/object/" + objectList[indexPath.row])
        var contents : String = ""
        do {
            try contents = (String(contentsOf: url!))
            print(contents)
        } catch {
            print("Error getting object path")
        }
        
        delegate?.receiveObject(object: contents)
        self.dismiss(animated: true, completion: nil)
    }
    
}

class ObjectCell : UITableViewCell {
    @IBOutlet weak var objectNameLabel: UILabel!
}
