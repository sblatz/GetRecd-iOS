//
//  FriendsLikesViewController.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 4/16/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

class FriendsLikesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    var user = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        DataService.sharedInstance.getUser(uid: user, success: { (user) in
            self.navigationController?.title = user.name + " Likes"
        }) { (error) in
            print(error)
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchButtonPressed(_ sender: Any) {
    }
    
    @IBAction func changedSegment(_ sender: Any) {
        
    }

    // Table View Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as? FriendCell else { return FriendCell() }

        var arr: [String] = []

        cell.accessoryType = .none

        let user = arr[indexPath.row]
        cell.user = user

        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
