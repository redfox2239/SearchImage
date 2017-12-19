//
//  ViewController.swift
//  SearchImage
//
//  Created by 原田　礼朗 on 2017/12/18.
//  Copyright © 2017年 reo harada. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SearchImageViewControllerDelegate {

    var selectedImages = [UIImage]()
    @IBOutlet weak var listTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedImages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ListImageTableViewCell
        cell.imgView?.image = selectedImages[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! ListImageTableViewCell
        return cell.frame.size.height
    }

    @IBAction func tapButton(_ sender: Any) {
        let nav = storyboard?.instantiateViewController(withIdentifier: "SearchImageNavigationViewController") as! UINavigationController
        if let childVC = nav.childViewControllers.first as? SearchImageViewController {
            childVC.delegate = self
            show(nav, sender: nil)
        }
    }
    
    @IBAction func tapRandomButton(_ sender: Any) {
        let nav = storyboard?.instantiateViewController(withIdentifier: "SearchImageNavigationViewController") as! UINavigationController
        if let childVC = nav.childViewControllers.first as? SearchImageViewController {
            childVC.delegate = self
            childVC.selectMode = .random
            show(nav, sender: nil)
        }
    }
    
    func didSelect(images: [UIImage]) {
        selectedImages = images
        listTableView.reloadData()
    }

}

class ListImageTableViewCell: UITableViewCell {
    @IBOutlet weak var imgView: UIImageView!
}
