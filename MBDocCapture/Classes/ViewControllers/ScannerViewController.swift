//
//  ScannerViewController.swift
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
//com.luzanovroman.BLECar
import UIKit
import AVFoundation

// The `ScannerViewController` offers an interface to give feedback to the user regarding rectangles that are detected. It also gives the user the opportunity to capture an image with a detected rectangle.
var isBatchScanSelected = false
var bacthScannedImage = [UIImage]()

final class ScannerViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    private var prepOverlayView: UIView!
    
    private var captureSessionManager: CaptureSessionManager?
    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    // The view that shows the focus rectangle (when the user taps to focus, similar to the Camera app)
    private var focusRectangle: FocusRectangleView!
    
    // The view that draws the detected rectangles.
    private let rectView = RectangleView()
    let gridButton = UIButton()
    let batchButton = UIButton()
    let singleButton = UIButton()
    let flashButton = UIButton()
    let QRButton = UIButton()
    
    private let griview = GridView()
    
    lazy private var ScanTopView : UIView = {
        let myView =  UIView()
        myView.backgroundColor = #colorLiteral(red: 0.09803921569, green: 0.1568627451, blue: 0.231372549, alpha: 1)
        myView.translatesAutoresizingMaskIntoConstraints = false
        
        //Text Label
        gridButton.backgroundColor = .clear
        gridButton.setImage(UIImage(named: "grid", in: bundle(), compatibleWith: nil), for: .normal)
        gridButton.addTarget(self, action: #selector(gridButtonTapped), for: .touchUpInside)
        
        batchButton.backgroundColor = .clear
        batchButton.setImage(UIImage(named: "batch", in: bundle(), compatibleWith: nil), for: .normal)
        batchButton.addTarget(self, action: #selector(batchleButtonTapped(_:)), for: .touchUpInside)
        
        
        
        singleButton.backgroundColor = .clear
        singleButton.setImage(UIImage(named: "single_selected", in: bundle(), compatibleWith: nil), for: .normal)
        singleButton.addTarget(self, action: #selector(singleButtonTapped(_:)), for: .touchUpInside)
        
        
        QRButton.backgroundColor = .clear
        QRButton.setImage(UIImage(named: "qrcode", in: bundle(), compatibleWith: nil), for: .normal)
        QRButton.addTarget(self, action: #selector(qrButtonTapped), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [gridButton,batchButton,singleButton,QRButton])
        stack.backgroundColor = .green
        stack.axis  = .horizontal
        stack.distribution  = .fillEqually
        stack.alignment = .fill
        stack.spacing   = 10.0
        myView.addSubview(stack)
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        stack.topAnchor.constraint(equalTo: myView.topAnchor, constant: 0).isActive = true
        stack.bottomAnchor.constraint(equalTo: myView.bottomAnchor, constant: 0).isActive = true
        stack.leadingAnchor.constraint(equalTo: myView.leadingAnchor, constant: 10).isActive = true
        stack.trailingAnchor.constraint(equalTo: myView.trailingAnchor, constant: -10).isActive = true
        
        
        return myView
    }()
    
    
    
    
    lazy private var ScanBottomView : UIView = {
        let myView =  UIView()
        myView.backgroundColor = #colorLiteral(red: 0.09803921569, green: 0.1568627451, blue: 0.231372549, alpha: 1)
        myView.translatesAutoresizingMaskIntoConstraints = false
        
        
        //Text Label
        let galleryBtn = UIButton()
        galleryBtn.backgroundColor = .clear
        galleryBtn.setImage(UIImage(named: "gallery", in: bundle(), compatibleWith: nil), for: .normal)
        galleryBtn.addTarget(self, action: #selector(galleryclicked), for: .touchUpInside)
        
        let cameraButton = UIButton()
        cameraButton.backgroundColor = .clear
        cameraButton.setImage(UIImage(named: "camera", in: bundle(), compatibleWith: nil), for: .normal)
        cameraButton.addTarget(self, action: #selector(captureImage(_:)), for: .touchUpInside)
        
        flashButton.backgroundColor = .clear
        
        
        let flashStatus = UserDefaults.standard.bool(forKey: "flash")
        print(flashStatus)
        if flashStatus {
            flashButton.setImage(UIImage(named: "flash_on", in: bundle(), compatibleWith: nil), for: .normal)
        }else{
            flashButton.setImage(UIImage(named: "flash_off", in: bundle(), compatibleWith: nil), for: .normal)
        }
        
        
        flashButton.addTarget(self, action: #selector(flashCliked(_:)), for: .touchUpInside)
        
        
        let stack = UIStackView(arrangedSubviews: [galleryBtn,cameraButton,flashButton])
        stack.backgroundColor = .green
        stack.axis  = .horizontal
        stack.distribution  = .fill
        stack.alignment = .center
        stack.spacing   = 60.0
        
        
        myView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.centerXAnchor.constraint(equalTo: myView.centerXAnchor).isActive = true
        stack.centerYAnchor.constraint(equalTo: myView.centerYAnchor).isActive = true
        return myView
    }()
    
    lazy private var shutterButton: ShutterButton = {
        let button = ShutterButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(captureImage(_:)), for: .touchUpInside)
        return button
    }()
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override public var shouldAutorotate: Bool {
        return true
    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    lazy private var cancelButton: UIBarButtonItem = {
        let title = NSLocalizedString("mbdoccapture.cancel_button", tableName: nil, bundle: bundle(), value: "Cancel", comment: "")
        let button = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(cancelImageScannerController))
        button.tintColor = .white
        return button
    }()
    
    lazy private var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    deinit {
        print("scanner has been deallocated")
    }
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = nil
        isBatchScanSelected = false
        setupNavigationBar()
        setupViews()
        setupConstraints()
        
        captureSessionManager = CaptureSessionManager(videoPreviewLayer: videoPreviewLayer)
        captureSessionManager?.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: nil)
        //        NotificationCenter.default.addObserver(self, selector: #selector(updateCameraOrientation), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized
        {
            setNeedsStatusBarAppearanceUpdate()
            
            CaptureSession.current.isEditing = false
            rectView.removeRectangle()
            captureSessionManager?.start()
            UIApplication.shared.isIdleTimerDisabled = true
            
            navigationController?.setToolbarHidden(true, animated: false)
            
            if CaptureSession.current.isScanningTwoFacedDocument {
                if let _ = CaptureSession.current.firstScanResult {
                    displayPrepOverlay()
                }else{
                    displayPrepOverlay()
                }
                ScanBottomView.isHidden = true
                ScanTopView.isHidden = true
            }else{
                ScanBottomView.isHidden = false
                ScanTopView.isHidden = false
            }
            updateCameraOrientation()
            
        }
        else
        {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted :Bool) -> Void in
                if granted == true
                {
                    DispatchQueue.main.async {
                        self.setNeedsStatusBarAppearanceUpdate()
                        
                        CaptureSession.current.isEditing = false
                        self.rectView.removeRectangle()
                        self.captureSessionManager?.start()
                        UIApplication.shared.isIdleTimerDisabled = true
                        
                        self.navigationController?.setToolbarHidden(true, animated: false)
                        
                        if CaptureSession.current.isScanningTwoFacedDocument {
                            if let _ = CaptureSession.current.firstScanResult {
                                self.displayPrepOverlay()
                            }else{
                                self.displayPrepOverlay()
                            }
                            self.ScanBottomView.isHidden = true
                            self.ScanTopView.isHidden = true
                        }else{
                            self.ScanBottomView.isHidden = false
                            self.ScanTopView.isHidden = false
                        }
                        self.updateCameraOrientation()
                    }
                    
                }
                else
                {
                    let ac = UIAlertController(title: "Alert", message: "We are unable to scan documents without camera permission, kindly grant access to camera by going to App settings", preferredStyle: .alert)
                    let setting = UIAlertAction(title: "Open Setting", style: .default) { (action) in
                        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                            DispatchQueue.main.async {
                                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                            }
                        }
                    }
                    let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    ac.addAction(setting)
                    ac.addAction(cancel)
                    self.present(ac, animated: true, completion: nil)
                    self.dismiss(animated: true, completion: nil)
                }
            });
        }
        
        
    }
    
    //    override func viewDidAppear(_ animated: Bool) {
    //        super.viewDidAppear(animated)
    //
    //
    //
    //        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  AVAuthorizationStatus.authorized {
    //                   print("Already Authorized")
    //
    //               }else {
    //                   let ac = UIAlertController(title: "Alert", message: "We are unable to scan documents without camera permission, kindly grant access to camera by going to App settings", preferredStyle: .alert)
    //                   let setting = UIAlertAction(title: "Open Setting", style: .default) { (action) in
    //                       if let appSettings = URL(string: UIApplication.openSettingsURLString) {
    //                           DispatchQueue.main.async {
    //                               UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
    //                           }
    //                       }
    //                   }
    //                   let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    //                   ac.addAction(setting)
    //                   ac.addAction(cancel)
    //                   self.present(ac, animated: true, completion: nil)
    //                   self.dismiss(animated: true, completion: nil)
    //               }
    //
    //        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  AVAuthorizationStatus.authorized {
    //            print("Already Authorized")
    //            setNeedsStatusBarAppearanceUpdate()
    //
    //            CaptureSession.current.isEditing = false
    //            rectView.removeRectangle()
    //            captureSessionManager?.start()
    //            UIApplication.shared.isIdleTimerDisabled = true
    //
    //            navigationController?.setToolbarHidden(true, animated: false)
    //
    //            if CaptureSession.current.isScanningTwoFacedDocument {
    //                if let _ = CaptureSession.current.firstScanResult {
    //                    displayPrepOverlay()
    //                }else{
    //                    displayPrepOverlay()
    //                }
    //                ScanBottomView.isHidden = true
    //                ScanTopView.isHidden = true
    //            }else{
    //                ScanBottomView.isHidden = false
    //                ScanTopView.isHidden = false
    //            }
    //            updateCameraOrientation()
    //
    //        }
    //    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        videoPreviewLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        updateCameraOrientation()
    }
    
    @objc private func updateCameraOrientation() {
        if UIDevice.current.orientation == .landscapeRight {
            videoPreviewLayer.connection!.videoOrientation       = .landscapeLeft
        } else if UIDevice.current.orientation == .landscapeLeft {
            videoPreviewLayer.connection!.videoOrientation       = .landscapeRight
        } else if UIDevice.current.orientation == .portrait {
            videoPreviewLayer.connection!.videoOrientation       = .portrait
        } else if UIDevice.current.orientation == .portraitUpsideDown {
            videoPreviewLayer.connection!.videoOrientation       = .portraitUpsideDown
        }
        let w = view.layer.bounds.width
        let h = view.layer.bounds.height
        videoPreviewLayer.frame = CGRect(x: 0, y: 0, width: w, height: h)
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        view.layer.addSublayer(videoPreviewLayer)
        rectView.translatesAutoresizingMaskIntoConstraints = false
        rectView.editable = false
        view.addSubview(rectView)
        view.addSubview(shutterButton)
        view.addSubview(ScanBottomView)
        view.addSubview(ScanTopView)
        view.addSubview(activityIndicator)
    }
    
    var isGridShowing = false
    
    @objc private func flashButtonTapped(){
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else{
            return
        }
        if device.hasFlash {
            AVCapturePhotoSettings().flashMode = .on
        }
    }
    
    
    @objc func singleButtonTapped(_ sender : UIButton){
        isBatchScanSelected = false
        bacthScannedImage.removeAll()
        QRButton.isEnabled = true
        singleButton.setImage(UIImage(named: "single_selected", in: bundle(), compatibleWith: nil), for: .normal)
        
        batchButton.setImage(UIImage(named: "batch", in: bundle(), compatibleWith: nil), for: .normal)
        
    }
    
    @objc func batchleButtonTapped(_ sender : UIButton){
        isBatchScanSelected = true
        QRButton.isEnabled = false
        
        bacthScannedImage.removeAll()
        batchButton.setImage(UIImage(named: "batch_selected", in: bundle(), compatibleWith: nil), for: .normal)
        
        singleButton.setImage(UIImage(named: "single", in: bundle(), compatibleWith: nil), for: .normal)
    }
    
    @objc func flashCliked(_ sender:UIButton){
        let flashStatus = UserDefaults.standard.bool(forKey: "flash")
        print(flashStatus)
        if flashStatus {
            flashButton.setImage(UIImage(named: "flash_off", in: bundle(), compatibleWith: nil), for: .normal)
            UserDefaults.standard.set(false, forKey: "flash")
        }else{
            flashButton.setImage(UIImage(named: "flash_on", in: bundle(), compatibleWith: nil), for: .normal)
            UserDefaults.standard.set(true, forKey: "flash")
        }
        UserDefaults.standard.synchronize()
    }
    
    
    @objc private func gridButtonTapped(){
        print("grid clicked")
        griview.backgroundColor = .clear
        if !isGridShowing {
            view.addSubview(griview)
            gridButton.setImage(UIImage(named: "grid_selected", in: bundle(), compatibleWith: nil), for: .normal)
            isGridShowing = true
        }else{
            DispatchQueue.main.async{
                self.griview.removeFromSuperview()
                self.gridButton.setImage(UIImage(named: "grid", in: self.bundle(), compatibleWith: nil), for: .normal)
                self.isGridShowing = false
            }
        }
        griview.frame = CGRect(x: 0, y: 60, width: view.bounds.width, height: view.bounds.height - 160)
    }
    
    @objc func qrButtonTapped(){
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        imageScannerController.imageScannerDelegate?.didTapQRCodeButton(imageScannerController)
    }
    
    @objc func galleryclicked(){
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        imageScannerController.imageScannerDelegate?.galleryButtonClicked(imageScannerController)
    }
    
    
    private func setupNavigationBar() {
        navigationItem.setLeftBarButton(cancelButton, animated: false)
        navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.09803921569, green: 0.1568627451, blue: 0.231372549, alpha: 1)
        navigationController?.navigationBar.isTranslucent = false
        if #available(iOS 13.0, *) {
            isModalInPresentation = false
            navigationController?.presentationController?.delegate = self
        }
    }
    
    private func setupConstraints() {
        var rectViewConstraints = [NSLayoutConstraint]()
        var shutterButtonConstraints = [NSLayoutConstraint]()
        var activityIndicatorConstraints = [NSLayoutConstraint]()
        var bottomViewConstraints = [NSLayoutConstraint]()
        var topViewConstraints = [NSLayoutConstraint]()
        
        bottomViewConstraints = [
            ScanBottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ScanBottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ScanBottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ScanBottomView.heightAnchor.constraint(equalToConstant: 100)
        ]
        
        topViewConstraints = [
            ScanTopView.topAnchor.constraint(equalTo: view.topAnchor),
            ScanTopView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ScanTopView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ScanTopView.heightAnchor.constraint(equalToConstant: 60)
        ]
        
        rectViewConstraints = [
            rectView.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: rectView.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: rectView.trailingAnchor),
            rectView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ]
        
        shutterButtonConstraints = [
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.widthAnchor.constraint(equalToConstant: 65.0),
            shutterButton.heightAnchor.constraint(equalToConstant: 65.0)
        ]
        
        activityIndicatorConstraints = [
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        
        if #available(iOS 11.0, *) {
            let shutterButtonBottomConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: shutterButton.bottomAnchor, constant: 8.0)
            shutterButtonConstraints.append(shutterButtonBottomConstraint)
        } else {
            let shutterButtonBottomConstraint = view.bottomAnchor.constraint(equalTo: shutterButton.bottomAnchor, constant: 8.0)
            shutterButtonConstraints.append(shutterButtonBottomConstraint)
        }
        
        NSLayoutConstraint.activate(rectViewConstraints + shutterButtonConstraints + topViewConstraints + bottomViewConstraints + activityIndicatorConstraints)
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
    
    // MARK: - Tap to Focus
    
    /// Called when the AVCaptureDevice detects that the subject area has changed significantly. When it's called, we reset the focus so the camera is no longer out of focus.
    @objc private func subjectAreaDidChange() {
        /// Reset the focus and exposure back to automatic
        do {
            try CaptureSession.current.resetFocusToAuto()
        } catch {
            let error = ImageScannerControllerError.inputDevice
            guard let captureSessionManager = captureSessionManager else { return }
            captureSessionManager.delegate?.captureSessionManager(captureSessionManager, didFailWithError: error)
            return
        }
        
        /// Remove the focus rectangle if one exists
        CaptureSession.current.removeFocusRectangleIfNeeded(focusRectangle, animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard  let touch = touches.first else { return }
        let touchPoint = touch.location(in: view)
        let convertedTouchPoint: CGPoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: touchPoint)
        
        CaptureSession.current.removeFocusRectangleIfNeeded(focusRectangle, animated: false)
        
        focusRectangle = FocusRectangleView(touchPoint: touchPoint)
        view.addSubview(focusRectangle)
        
        do {
            try CaptureSession.current.setFocusPointToTapPoint(convertedTouchPoint)
        } catch {
            let error = ImageScannerControllerError.inputDevice
            guard let captureSessionManager = captureSessionManager else { return }
            captureSessionManager.delegate?.captureSessionManager(captureSessionManager, didFailWithError: error)
            return
        }
    }
    
    // MARK: - Actions
    
    @objc private func captureImage(_ sender: UIButton) {
        (navigationController as? ImageScannerController)?.flashToBlack()
        shutterButton.isUserInteractionEnabled = false
        // toggleFlash()
        captureSessionManager?.capturePhoto()
    }
    
    func toggleFlash() {
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
            else {
                print("Unable to access back camera!")
                return
        }
        do {
            if backCamera.hasTorch {
                try backCamera.lockForConfiguration()
                if #available(iOS 11.0, *) {
                    let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                    settings.flashMode = .on
                } else {
                    // Fallback on earlier versions
                }
                backCamera.unlockForConfiguration()
                
                //  stillImageOutput.capturePhoto(with: settings, delegate: self)
            }
        } catch {
            return
        }
    }
    
    
    @objc func autoCaptureSwitchValueDidChange(sender:UISwitch!) {
        if sender.isOn {
            CaptureSession.current.isAutoScanEnabled = true
        } else {
            CaptureSession.current.isAutoScanEnabled = false
        }
    }
    
    @objc private func cancelImageScannerController() {
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        
        let alert = UIAlertController(title: "Alert", message: "Do you  really want to exit?", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "No", style: .cancel, handler: nil)
        let exit = UIAlertAction(title: "Yes", style: .default) { (action) in
            imageScannerController.imageScannerDelegate?.imageScannerControllerDidCancel(imageScannerController)
        }
        alert.addAction(cancel)
        alert.addAction(exit)
        
        self.present(alert, animated: true, completion: nil)
        
        
    }
}

extension ScannerViewController: RectangleDetectionDelegateProtocol {
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didFailWithError error: Error) {
        
        activityIndicator.stopAnimating()
        shutterButton.isUserInteractionEnabled = true
        
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFailWithError: error)
    }
    
    func didStartCapturingPicture(for captureSessionManager: CaptureSessionManager) {
        activityIndicator.startAnimating()
        shutterButton.isUserInteractionEnabled = false
    }
    
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didCapturePicture picture: UIImage, withRect rect: Rectangle?) {
        activityIndicator.stopAnimating()
        
        let editVC = EditScanViewController(image: picture, rect: rect)
        navigationController?.pushViewController(editVC, animated: false)
        
        shutterButton.isUserInteractionEnabled = true
    }
    
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didDetectRect rect: Rectangle?, _ imageSize: CGSize) {
        guard let rect = rect else {
            // If no rect has been detected, we remove the currently displayed on on the rectView.
            rectView.removeRectangle()
            return
        }
        
        let portraitImageSize = CGSize(width: imageSize.height, height: imageSize.width)
        
        let scaleTransform = CGAffineTransform.scaleTransform(forSize: portraitImageSize, aspectFillInSize: rectView.bounds.size)
        let scaledImageSize = imageSize.applying(scaleTransform)
        
        let rotationTransform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
        
        let imageBounds = CGRect(origin: .zero, size: scaledImageSize).applying(rotationTransform)
        
        let translationTransform = CGAffineTransform.translateTransform(fromCenterOfRect: imageBounds, toCenterOfRect: rectView.bounds)
        
        let transforms = [scaleTransform, rotationTransform, translationTransform]
        
        let transformedRect = rect.applyTransforms(transforms)
        
        rectView.drawRectangle(rect: transformedRect, animated: true)
    }
    
    func displayPrepOverlay() {
        CaptureSession.current.isEditing = true
        
        prepOverlayView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 120))
        prepOverlayView.backgroundColor = UIColor(hexString: "FFFFFF99")
        
        let image = UIImageView(frame: CGRect(x: (view.frame.width - 40) / 2, y: 16, width: 40, height: 40))
        let icon = UIImage(named: "ic_touch", in: bundle(), compatibleWith: nil)
        image.image = icon
        prepOverlayView.addSubview(image)
        
        let defaultFont = UIFont(name: "HelveticaNeue-Bold", size: 15)
        let label = UILabel(frame: CGRect(x: 16, y: image.frame.maxY + 16, width: prepOverlayView.frame.width - 32, height: 40))
        label.font = defaultFont
        label.numberOfLines = 0
        label.textColor = .black
        label.textAlignment = .center
        
        if CaptureSession.current.isScanningTwoFacedDocument {
            if let _ = CaptureSession.current.firstScanResult {
                label.text = NSLocalizedString("mbdoccapture.document_capture_flip", tableName: nil, bundle: bundle(), value: "Back Side and Touch to foucs.", comment: "")
            }else{
                label.text = NSLocalizedString("mbdoccapture.document_capture_flip", tableName: nil, bundle: bundle(), value: "Front Side and Touch to foucs.", comment: "")
            }
        }
        
        
        
        prepOverlayView.addSubview(label)
        
        let button = UIButton(frame: view.bounds)
        button.backgroundColor = .clear
        button.setTitle("", for: .normal)
        button.addTarget(self, action: #selector(didSelectRemoveOverlay(_:)), for: .touchUpInside)
        
        prepOverlayView.center = self.view.center
        view.addSubview(prepOverlayView)
        view.addSubview(button)
    }
    
    @objc func didSelectRemoveOverlay(_ button: UIButton) {
        button.removeFromSuperview()
        prepOverlayView.removeFromSuperview()
        CaptureSession.current.isEditing = false
    }
}


extension UIButton {
    func alignVertical(spacing: CGFloat = 5.0) {
        guard let imageSize = imageView?.image?.size,
            let text = titleLabel?.text,
            let font = titleLabel?.font
            else { return }
        
        titleEdgeInsets = UIEdgeInsets(
            top: 0.0,
            left: -imageSize.width,
            bottom: -(imageSize.height + spacing),
            right: 0.0
        )
        
        let titleSize = text.size(withAttributes: [.font: font])
        imageEdgeInsets = UIEdgeInsets(
            top: -(titleSize.height + spacing),
            left: 0.0,
            bottom: 0.0, right: -titleSize.width
        )
        
        let edgeOffset = abs(titleSize.height - imageSize.height) / 2.0
        contentEdgeInsets = UIEdgeInsets(
            top: edgeOffset,
            left: 0.0,
            bottom: edgeOffset,
            right: 0.0
        )
    }
}

