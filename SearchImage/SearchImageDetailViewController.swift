//
//  SearchImageDetailViewController.swift
//  SearchImage
//
//  Created by 原田　礼朗 on 2017/12/19.
//  Copyright © 2017年 reo harada. All rights reserved.
//

import UIKit
import WebKit

protocol SearchImageDetailViewControllerDelegate {
    func didSelect(image: UIImage) -> Void
}

extension SearchImageDetailViewControllerDelegate {
    func didSelect(image: UIImage) {}
}

class SearchImageDetailViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, WKNavigationDelegate {

    @IBOutlet weak var searchImageDetailCollectionView: UICollectionView!
    @IBOutlet weak var loadingActivityIndicatorView: UIActivityIndicatorView!
    
    var delegate: SearchImageDetailViewControllerDelegate!
    
    var webView = WKWebView()
    var data = [String]()
    var imageCacheManager = ImageCacheManager.sharedInstance
    var searchImgURL = ""
    var getImageURLJS = "var imgURLs = '';$('#Blog1').find('.entry img').each(function(index,val){ if (val.attributes.alt != undefined && val.attributes.alt != '') { imgURLs += val.src+','; }}); imgURLs"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        loadView(urlStr: searchImgURL)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchCollectionViewCell", for: indexPath) as! SearchCollectionViewCell
        cell.currentIndexPath = indexPath
        cell.searchImageView.image = nil
        cell.loadingIndicatorView.isHidden = false
        let urlStr = data[indexPath.row]
        if imageCacheManager.getImgCache(key: urlStr) == nil {
            UIImage.getImageWithBackground(urlStr: urlStr, handler: { (isError, data) in
                if !isError {
                    if let imgData = data {
                        self.imageCacheManager.setImgCache(key: urlStr, data: imgData)
                        if cell.currentIndexPath == indexPath {
                            cell.searchImageView.image = UIImage(data: imgData)
                            cell.loadingIndicatorView.stopAnimating()
                        }
                    }
                }
            })
        }
        else {
            if let imgData = imageCacheManager.getImgCache(key: urlStr) {
                cell.searchImageView.image = UIImage(data: imgData)
                cell.loadingIndicatorView.stopAnimating()
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if delegate != nil {
            if let imgData = imageCacheManager.getImgCache(key: data[indexPath.row]) {
                if let img = UIImage(data: imgData) {
                    delegate.didSelect(image: img)
                }
            }
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let halfScreenWidth = UIScreen.main.bounds.size.width / 2
        return CGSize(width: halfScreenWidth, height: halfScreenWidth)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingActivityIndicatorView.stopAnimating()
        webView.evaluateJavaScript(getImageURLJS) { (values, error) in
            if error == nil {
                if let imgURLsStr = values as? String {
                    let imgURLs = imgURLsStr.components(separatedBy: ",").filter{$0 != ""}
                    self.data += imgURLs
                    self.searchImageDetailCollectionView.reloadData()
                }
                self.imageCacheManager.setHtmlCache(key: self.searchImgURL, data: self.data, hrefData: [String]())
            }
        }
    }
    
    func loadView(urlStr: String) {
        if let cacheDatas = imageCacheManager.getHtmlCache(key: searchImgURL) {
            data = cacheDatas.0
            searchImageDetailCollectionView.reloadData()
            loadingActivityIndicatorView.stopAnimating()
        }
        else {
            data = [String]()
            searchImageDetailCollectionView.reloadData()
            if let url = URL(string: searchImgURL) {
                let request = URLRequest(url: url)
                webView.load(request)
            }
        }
    }
}
