//
//  SecondViewController.swift
//  Gram
//
//  Created by Andy Xue on 1/24/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import UIKit

class CommunityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var viewNoPhotos: UILabel!
    @IBOutlet weak var communityTableView: UITableView!
    @IBOutlet weak var communitySearchBar: UISearchBar!
    var photos = [PhotoCard]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        communityTableView.delegate = self
        communityTableView.dataSource = self
        
        viewNoPhotos.isHidden = false  // Initially, show "no photos" message
    }
    
    override func viewWillAppear(_ animated: Bool) {
        changeStatusBarColor(forView: self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        <#code#>
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        <#code#>
    }


}

