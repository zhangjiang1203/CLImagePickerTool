//
//  CLImagePickerSingleViewController.swift
//  ImageDeal
//
//  Created by darren on 2017/7/27.
//  Copyright © 2017年 陈亮陈亮. All rights reserved.
//

import UIKit
import PhotosUI
import Photos

typealias  CLImagePickerSingleChooseImageCompleteClouse = (Array<PHAsset>,UIImage?)->()

class CLImagePickerSingleViewController: CLBaseImagePickerViewController {

    var photoArr: [CLImagePickerPhotoModel]?
    
    var cameraPicker: UIImagePickerController!
    
    var singleChooseImageCompleteClouse: CLImagePickerSingleChooseImageCompleteClouse?
    
    let imageCellID = "imagecellID"
    
    // 标记是不是所有照片。如果是所有照片再添加拍照图片
    var isAllPhoto: Bool = false
    
    // 单选状态的类型
    var singleType: CLImagePickersToolType?
    
    // 图片裁剪比例
    var singlePictureCropScale: CGFloat?
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var flowout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var sureBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 假如用户在收藏相册详情中选中了一张照片，那么就应该把全部照片中的数据源刷新一下，这样才能显示选中状态
        // 将所有模型至为未选中
        if self.photoArr != nil {
            for model in self.photoArr! {
                model.isSelect = false
            }
        }
        let chooseAssetArr = CLPickersTools.instence.getChoosePictureArray()
        for item in chooseAssetArr {
            guard let photoArrVaile = self.photoArr else {
                continue
            }
            for model in photoArrVaile {
                if model.phAsset?.localIdentifier == item.localIdentifier {
                    model.isSelect = true
                    continue
                }
            }
        }
        
        if self.isAllPhoto {
            // 数组中新增一个数据代表相机图片
            self.photoArr?.append(CLImagePickerPhotoModel())
        }
        
        self.initView()
    }
    
    // 点击确定
    @IBAction func clickSureBtn(_ sender: Any) {

        self.choosePictureComplete(assetArr: CLPickersTools.instence.getChoosePictureArray(), img: nil)
    }
    
    func choosePictureComplete(assetArr:Array<PHAsset>,img:UIImage?) {
        if self.singleChooseImageCompleteClouse != nil {
            self.singleChooseImageCompleteClouse!(assetArr,img)
        }
        
        // 记得pop，不然控制器释放不掉
        self.dismiss(animated: true) {
            self.navigationController?.popViewController(animated: true)
        }

    }
    
    func initView() {
        self.backBtn.isHidden = false
        
        self.rightBtn.setTitle("取消", for: .normal)
        
        if CLPickersTools.instence.getSavePictureCount() > 0 {
            let title = "确定(\(CLPickersTools.instence.getSavePictureCount()))"
            self.sureBtn.setTitle(title, for: .normal)
        }
        
        self.flowout.sectionInset = UIEdgeInsets(top: 5, left: 0, bottom: 30, right: 0)
        self.flowout.footerReferenceSize = CGSize(width: KScreenWidth, height: 30)
        self.flowout.minimumLineSpacing = 5
        self.flowout.minimumInteritemSpacing = 0
        self.flowout.itemSize = CGSize(width: cellH, height:cellH)
        
        self.collectionView.register(UINib.init(nibName: "ImagePickerChooseImageCell", bundle: BundleUtil.getCurrentBundle()), forCellWithReuseIdentifier: imageCellID)
        self.collectionView.register(CLImagePickerCamaroCell.self, forCellWithReuseIdentifier: "CLImagePickerCamaroCell")
        self.collectionView.register(UINib.init(nibName: "CLSingleTypeCell", bundle: BundleUtil.getCurrentBundle()), forCellWithReuseIdentifier: "CLSingleTypeCell")

        
        self.collectionView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 44, right: 0)
        self.collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 64, left: 0, bottom: 44, right: 0)
        
        let item = self.collectionView(self.collectionView!, numberOfItemsInSection: 0) - 1
        if item == -1 { // 防止相册为0
            return
        }
        let lastItemIndex = IndexPath.init(item: item, section: 0)
        self.collectionView?.scrollToItem(at: lastItemIndex, at: .top, animated: false)
        
        // 单选隐藏下面的确定
        if self.singleType == nil {  // 说明不是单选
            self.bottomView.isHidden = false
        } else {
            self.bottomView.isHidden = true
        }
    }
    
    override func backBtnclick() {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func rightBtnClick() {
        
        // 记得pop，不然控制器释放不掉
        self.dismiss(animated: true) { 
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    deinit {
        print("CLImagePickerSingleViewController释放")
    }

}

extension CLImagePickerSingleViewController: UICollectionViewDelegate,UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoArr?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // 相机
        if indexPath.row == (self.photoArr?.count ?? 1) - 1 && self.isAllPhoto {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CLImagePickerCamaroCell", for: indexPath) as! CLImagePickerCamaroCell
            cell.clickCamaroCell = {[weak self]() in
                
                CLPickersTools.instence.authorizeCamaro { (state) in
                    if state == .authorized {
                        self?.cameraPicker = UIImagePickerController()
                        self?.cameraPicker.delegate = self
                        self?.cameraPicker.sourceType = .camera
                        self?.present((self?.cameraPicker)!, animated: true, completion: nil)
                    }
                }
                
            }
            return cell
        }
        
        
        if self.singleType == nil {  // 说明不是单选
            let model = self.photoArr?[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imageCellID, for: indexPath) as! ImagePickerChooseImageCell
            cell.model = model
            cell.imagePickerChooseImage = {[weak self] () in
                let chooseCount = CLPickersTools.instence.getSavePictureCount()
                if chooseCount == 0 {
                    self?.sureBtn.setTitle("确定", for: .normal)
                } else {
                    self?.sureBtn.setTitle("确定(\(chooseCount))", for: .normal)
                }
            }
            return cell
        } else {  // 是单选
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CLSingleTypeCell", for: indexPath) as! CLSingleTypeCell
            cell.model = self.photoArr?[indexPath.row]
            cell.singleChoosePicture = { [weak self] (assetArr,img) in
                
                if self?.singleType == .singlePictureCrop {  // 单选裁剪
                    if assetArr.first?.mediaType == .video {
                        self?.choosePictureComplete(assetArr: assetArr, img: img)
                        return
                    }
                    let cutVC = CLCropViewController()
                    if self?.singlePictureCropScale != nil {
                        cutVC.scale = (self?.singlePictureCropScale)!
                    }
                    cutVC.originalImage = img
                    cutVC.clCropClouse = {(cutImg) in
                        self?.choosePictureComplete(assetArr: assetArr, img: cutImg)
                    }
                    cutVC.asset = assetArr.first
                    self?.navigationController?.pushViewController(cutVC, animated: true)
                } else {
                    self?.choosePictureComplete(assetArr: assetArr, img: img)
                }
            }
            return cell
        }
    }
}

extension CLImagePickerSingleViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        self.dismiss(animated: true) {}
        
        PopViewUtil.share.showLoading()

        // 保存到相册
        let type = info[UIImagePickerControllerMediaType] as? String
        if type == "public.image" {
            let photo = info[UIImagePickerControllerOriginalImage]
            UIImageWriteToSavedPhotosAlbum(photo as! UIImage, self, #selector(CLImagePickerSingleViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // 保存图片的结果
    func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafeRawPointer) {
        if let err = error {
            UIAlertView(title: "错误", message: err.localizedDescription, delegate: nil, cancelButtonTitle: "确定").show()
        } else {
        
            var dataArr = CLPickersTools.instence.loadData()
            let newModel = dataArr.first?.values.first?.last
            
            self.photoArr?.insert(newModel!, at: (self.photoArr?.count ?? 1)-1)
            self.collectionView.reloadData()
            let lastItemIndex = IndexPath.init(item: (self.photoArr?.count ?? 1)-1, section: 0)
            self.collectionView?.scrollToItem(at: lastItemIndex, at: .top, animated: false)
            
            // 发送通知更新列表的数据
            dataArr.removeFirst()
            var arr = self.photoArr
            arr?.removeLast()
            dataArr.insert(["所有照片":arr!], at: 0)
            CLNotificationCenter.post(name: NSNotification.Name(rawValue:CLPhotoListRefreshNotic), object: dataArr)
            
            PopViewUtil.share.stopLoading()
        }
    }

}
