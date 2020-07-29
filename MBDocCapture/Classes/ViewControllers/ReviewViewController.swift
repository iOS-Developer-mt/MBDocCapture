//
//  ReviewViewController.swift
//  MBDocCapture
//
//  Created by El Mahdi Boukhris on 16/04/2019.
//  Copyright © 2019 El Mahdi Boukhris <m.boukhris@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

import UIKit

/// The `ReviewViewController` offers an interface to review the image after it has been cropped and deskwed according to the passed in rectangle.
final class ReviewViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    private var rotationAngle = Measurement<UnitAngle>(value: 0, unit: .degrees)
    private var enhancedImageIsAvailable = false
    private var isCurrentlyDisplayingEnhancedImage = false
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.isOpaque = true
        imageView.image = results.scannedImage
        imageView.backgroundColor = .black
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy private var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    
    lazy private var enhanceButton: UIBarButtonItem = {
        let image = UIImage(named: "enhance", in: bundle(), compatibleWith: nil)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(toggleEnhancedImage))
        button.tintColor = .white
        return button
    }()

    
    lazy private var rotateButton: UIBarButtonItem = {
        let image = UIImage(named: "rotate", in: bundle(), compatibleWith: nil)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(rotateImage))
        button.tintColor = .white
        return button
    }()
    
    
    
    lazy private var doneButton: UIBarButtonItem = {
        let title = NSLocalizedString("mbdoccapture.next_button", tableName: nil, bundle: bundle(), value: "Next", comment: "")
        let button = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(finishScan))
        button.tintColor = .white
        return button
    }()
    
    private let results: ImageScannerResults
    
    // MARK: - Life Cycle
    
    init(results: ImageScannerResults) {
        self.results = results
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        enhancedImageIsAvailable = results.enhancedImage != nil
        
        setupViews()
        setupToolbar()
        setupConstraints()
        
        if #available(iOS 13.0, *) {
            isModalInPresentation = false
            navigationController?.presentationController?.delegate = self
        }
      //  self.navigationController?.navigationBar.barTintColor = .white
        //self.navigationController?.navigationItem.title = "Edit Image"
        
      //  title = NSLocalizedString("mbdoccapture.scan_review_title", tableName: nil, bundle: bundle(), value: "Edit Image", comment: "")
        
        navigationItem.rightBarButtonItem = doneButton
        self.addActivityIndicator()
    }
    
    func addActivityIndicator() {
        self.view.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
         activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 50).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 50).isActive = true
        activityIndicator.startAnimating()
        activityIndicator.bringSubviewToFront(self.view)
    }
    
    func removeActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // We only show the toolbar (with the enhance button) if the enhanced image is available.
        if enhancedImageIsAvailable {
            navigationController?.setToolbarHidden(false, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
        self.removeActivityIndicator()
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
    
    // MARK: Setups
    
    private func setupViews() {
        view.addSubview(imageView)
    }
    
    private func setupToolbar() {
        guard enhancedImageIsAvailable else { return }
        navigationController?.toolbar.barTintColor = UIColor(hexString: "#24ABFC")
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [enhanceButton,flexibleSpace,rotateButton,flexibleSpace,doneButton,flexibleSpace
        ]
    }
    
    private func setupConstraints() {
        let imageViewConstraints = [
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
        ]
        
        NSLayoutConstraint.activate(imageViewConstraints)
    }
    
    // MARK: - Actions
    
    @objc private func reloadImage() {
        if enhancedImageIsAvailable, isCurrentlyDisplayingEnhancedImage {
            imageView.image = results.enhancedImage?.rotated(by: rotationAngle) ?? results.enhancedImage
        } else {
            imageView.image = results.scannedImage.rotated(by: rotationAngle) ?? results.scannedImage
        }
    }
    
    @objc func toggleEnhancedImage() {
        guard enhancedImageIsAvailable else { return }
        
        isCurrentlyDisplayingEnhancedImage.toggle()
        reloadImage()
        
        if isCurrentlyDisplayingEnhancedImage {
            enhanceButton.tintColor = UIColor(red: 64 / 255.0, green: 159 / 255.0, blue: 255 / 255.0, alpha: 1.0)
        } else {
            enhanceButton.tintColor = .white
        }
    }
    
    @objc func rotateImage() {
        rotationAngle.value += 90
        
        if rotationAngle.value == 360 {
            rotationAngle.value = 0
        }
        reloadImage()
    }
    
    @objc private func finishScan() {
        
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        var newResults = results
        newResults.scannedImage = results.scannedImage.rotated(by: rotationAngle) ?? results.scannedImage
        newResults.enhancedImage = results.enhancedImage?.rotated(by: rotationAngle) ?? results.enhancedImage
        newResults.doesUserPreferEnhancedImage = isCurrentlyDisplayingEnhancedImage
        if CaptureSession.current.isScanningTwoFacedDocument {
            if let firstPageResult = CaptureSession.current.firstScanResult {
                imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFinishScanningWithPage1Results: firstPageResult, andPage2Results: newResults)
                CaptureSession.current.isScanningTwoFacedDocument = false
                CaptureSession.current.firstScanResult = nil
            } else {
                CaptureSession.current.firstScanResult = newResults
                navigationController?.popToRootViewController(animated: true)
            }
        } else {
            imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFinishScanningWithResults: newResults)
        }
    }
}
