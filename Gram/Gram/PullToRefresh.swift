//
//  PullToRefresh.swift
//  Gram
//
//  Created by Andy Xue on 2/25/19.
//  Copyright © 2019 ECS165A. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

class PullToRefresh: UIView {
    @IBOutlet weak var loadingIndicator: NVActivityIndicatorView!
    
    func startAnimation() {
        loadingIndicator.startAnimating()
    }
}
