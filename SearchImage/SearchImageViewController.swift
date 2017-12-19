//
//  SearchImageViewController.swift
//  SearchImage
//
//  Created by 原田　礼朗 on 2017/12/18.
//  Copyright © 2017年 reo harada. All rights reserved.
//

import UIKit
import WebKit

protocol SearchImageViewControllerDelegate {
    func didSelect(images: [UIImage]) -> Void
}

extension SearchImageViewControllerDelegate {
    func didSelect(images: [UIImage]) {}
}

class SearchImageViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, WKNavigationDelegate, SearchImageDetailViewControllerDelegate {
    
    @IBOutlet weak var searchImageCollectionView: UICollectionView!
    @IBOutlet weak var searchQueryTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchImageCollectionViewMarginTop: NSLayoutConstraint!
    @IBOutlet weak var selectedImageCollectionView: UICollectionView!
    @IBOutlet weak var OKButtonItem: UIBarButtonItem!
    @IBOutlet weak var selectedImageCollectionViewBottom: NSLayoutConstraint!
    @IBOutlet weak var loadingActivityIndicatorView: UIActivityIndicatorView!
    
    var delegate: SearchImageViewControllerDelegate!
    
    var webView = WKWebView()
    var data = [String]()
    var hrefData = [String]()
    var imgCacheManager = ImageCacheManager.sharedInstance
    var searchImgURL = "http://www.irasutoya.com/search"
    var getImageURLJS = "var imgURLs = '';$('#Blog1').find('.boxthumb').each(function(index,val){imgURLs += val.src+','});imgURLs"
    var getURLJS = "var href = ''; $('.boxim').each(function(index,val){ href += $(val).find('a')[0].href+','; }); href;"
    var tapNextPageJS = "$('.navibtn').each(function(index,val){ if (val.innerHTML === '次のページ') val.click(); });"
    var selectedImages = [UIImage]()
    
    enum selectModeType {
        case single,random;
    }
    var selectMode = selectModeType.single
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        loadingActivityIndicatorView.stopAnimating()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == searchImageCollectionView {
            return data.count
        }
        else {
            return selectedImages.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchCollectionViewCell", for: indexPath) as! SearchCollectionViewCell
        if searchImageCollectionView == collectionView {
            cell.currentIndexPath = indexPath
            cell.searchImageView.image = nil
            cell.loadingIndicatorView.isHidden = false
            let urlStr = data[indexPath.row]
            if imgCacheManager.getImgCache(key: urlStr) == nil {
                UIImage.getImageWithBackground(urlStr: urlStr, handler: { (isError, data) in
                    if !isError {
                        if let imgData = data {
                            self.imgCacheManager.setImgCache(key: urlStr, data: imgData)
                            if cell.currentIndexPath == indexPath {
                                cell.searchImageView.image = UIImage(data: imgData)
                                cell.loadingIndicatorView.stopAnimating()
                            }
                        }
                    }
                })
            }
            else {
                if let imgData = imgCacheManager.getImgCache(key: urlStr) {
                    cell.searchImageView.image = UIImage(data: imgData)
                    cell.loadingIndicatorView.stopAnimating()
                }
            }
        }
        else {
            cell.searchImageView.image = selectedImages[indexPath.row]
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == searchImageCollectionView {
            let vc = storyboard?.instantiateViewController(withIdentifier: "SearchImageDetailViewController") as! SearchImageDetailViewController
            vc.searchImgURL = hrefData[indexPath.row]
            vc.delegate = self
            show(vc, sender: nil)
        }
        else {
            let alert = UIAlertController(title: "けしますか？", message: nil, preferredStyle: .alert)
            let action = UIAlertAction(title: "けす", style: .default, handler: { (alert) in
                self.selectedImages.remove(at: indexPath.row)
                self.selectedImageCollectionView.reloadData()
            })
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
            alert.addAction(action)
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == searchImageCollectionView {
            let quarterScreenWidth = UIScreen.main.bounds.size.width / 4
            return CGSize(width: quarterScreenWidth, height: quarterScreenWidth)
        }
        else {
            let height = UIScreen.main.bounds.size.width * 0.1 - 10
            return CGSize(width: height, height: height)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingActivityIndicatorView.stopAnimating()
        webView.evaluateJavaScript(getImageURLJS) { (values, error) in
            if error == nil {
                if let imgURLsStr = values as? String {
                    let imgURLs = imgURLsStr.components(separatedBy: ",").filter{$0 != ""}
                    self.data += imgURLs
                    self.searchImageCollectionView.reloadData()
                    webView.evaluateJavaScript(self.getURLJS) { (vals, error) in
                        if error == nil {
                            if let urlsStr = vals as? String {
                                let urls = urlsStr.components(separatedBy: ",").filter{$0 != ""}
                                self.hrefData += urls
                            }
                        }
                        ImageCacheManager.sharedInstance.setHtmlCache(key: self.searchImgURL, data: self.data, hrefData: self.hrefData)
                        webView.evaluateJavaScript(self.tapNextPageJS, completionHandler: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func tapSearchButton(_ sender: Any) {
        guard let query = searchQueryTextField.text else {
            return
        }
        searchImgURL = "http://www.irasutoya.com/search"
        if let encodeQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            searchImgURL += "?q=\(encodeQuery)&m=1"
        }
        loadView(urlStr: searchImgURL)
    }
    
    @IBAction func tapOKButton(_ sender: Any) {
        delegate.didSelect(images: selectedImages)
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func loadView(urlStr: String) {
        if let url = URL(string: searchImgURL) {
            let request = URLRequest(url: url)
            loadingActivityIndicatorView.startAnimating()
            if let cacheDatas = ImageCacheManager.sharedInstance.getHtmlCache(key: searchImgURL) {
                data = cacheDatas.0
                hrefData = cacheDatas.1
                searchImageCollectionView.reloadData()
                loadingActivityIndicatorView.stopAnimating()
            }
            else {
                data = [String]()
                hrefData = [String]()
                searchImageCollectionView.reloadData()
                webView.load(request)
            }
        }
    }
    
    func didSelect(image: UIImage) {
        if selectMode == .single {
            selectedImages = [UIImage]()
        }
        selectedImages.append(image)
        selectedImageCollectionView.reloadData()
    }
}

class SearchCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var searchImageView: UIImageView!
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!
    var currentIndexPath: IndexPath!
}

class ImageCacheManager {
    static let sharedInstance = ImageCacheManager()
    var imgCache = [String:Data]()
    var htmlCache = [String:[String]]()
    var hrefCache = [String:[String]]()
    func setImgCache(key: String, data: Data) {
        imgCache[key] = data
    }
    func getImgCache(key: String) -> Data? {
        if imgCache[key] == nil {
            return nil
        }
        return imgCache[key]
    }
    func setHtmlCache(key: String, data: [String], hrefData: [String]) {
        htmlCache[key] = data
        hrefCache[key] = hrefData
    }
    func getHtmlCache(key: String) -> ([String], [String])? {
        if htmlCache[key] == nil || hrefCache[key] == nil {
            return nil
        }
        return (htmlCache[key]!, hrefCache[key]!)
    }
}

extension UIImage {
    class func getImageWithBackground(urlStr: String, handler: @escaping (Bool, Data?)->Void) {
        guard let url = URL(string: urlStr) else {
            handler(true, nil)
            return
        }
        DispatchQueue.global(qos: .default).async {
            do {
                let data = try Data(contentsOf: url)
                DispatchQueue.main.async {
                    handler(false, data)
                    return
                }
            }
            catch {
                DispatchQueue.main.async {
                    handler(true, nil)
                    return
                }
            }
        }
    }
}
