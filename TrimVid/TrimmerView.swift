//
//  TrimmerView.swift
//  TrimVid
//
//  Created by Azhar Anwar on 04/10/22.
//

import AVFoundation
import UIKit

public protocol TrimmerViewDelegate: AnyObject {
  func didChangePositionBar(_ playerTime: CMTime)
  func positionBarStoppedMoving(_ playerTime: CMTime)
}

public class TrimmerView: UIView, UIScrollViewDelegate {
  
  // MARK: - Properties
  
  /// The asset to be displayed in the underlying scroll view. Setting a new asset will automatically refresh the thumbnails.
  public var asset: AVAsset? {
    didSet {
      assetDidChange(newAsset: asset)
    }
  }
  
  public weak var delegate: TrimmerViewDelegate?
  
  // MARK: Subviews
  
  private let assetPreview = VideoScrollView()
  
  private let trimView: UIView = {
    let view = UIView()
    view.layer.borderColor = UIColor.orange.cgColor
    return view
  }()
  
  private let leftHandleView: UIView = {
    let view = UIView()
    view.backgroundColor = .orange
    return view
  }()
  
  private let rightHandleView: UIView = {
    let view = UIView()
    view.backgroundColor = .orange
    return view
  }()
  
  private let positionBar: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    return view
  }()
  
  private let leftHandleNotch: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    return view
  }()
  
  private let rightHandleNotch: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    return view
  }()
  
  private let leftMaskView: UIView = {
    let view = UIView()
    view.backgroundColor = .systemGray
    return view
  }()
  
  private let rightMaskView: UIView = {
    let view = UIView()
    view.backgroundColor = .systemGray
    return view
  }()
  

  private func updateHandleColor() {
  }
  
  // MARK: Constraints
  
  private var currentLeftConstraint: CGFloat = 0
  private var currentRightConstraint: CGFloat = 0
  private var leftConstraint: NSLayoutConstraint?
  private var rightConstraint: NSLayoutConstraint?
  private var positionConstraint: NSLayoutConstraint?
  
  private let handleWidth: CGFloat = 15
  
  public var minDuration: Double = 3
  
  public var maxDuration: Double = 15 {
    didSet {
      assetPreview.maxDuration = maxDuration
    }
  }
  
  // MARK: - init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    layer.cornerRadius = 2
    layer.masksToBounds = true
    backgroundColor = UIColor.clear
    layer.zPosition = 1
    
    setupSubviews()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Methods
  
  private func setupSubviews() {    
    setupAssetPreview()
    setupTrimmerView()
    setupHandleView()
    setupMaskView()
    setupPositionBar()
    setupGestures()
  }
  
  private func setupAssetPreview() {
    self.translatesAutoresizingMaskIntoConstraints = false
    assetPreview.translatesAutoresizingMaskIntoConstraints = false
    assetPreview.delegate = self
    addSubview(assetPreview)
    
    assetPreview.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    assetPreview.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    assetPreview.topAnchor.constraint(equalTo: topAnchor).isActive = true
    assetPreview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
  }
  
  private func setupTrimmerView() {
    trimView.layer.borderWidth = 2.0
    trimView.layer.cornerRadius = 2.0
    trimView.translatesAutoresizingMaskIntoConstraints = false
    trimView.isUserInteractionEnabled = false
    addSubview(trimView)
    
    trimView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    trimView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    leftConstraint = trimView.leftAnchor.constraint(equalTo: leftAnchor)
    rightConstraint = trimView.rightAnchor.constraint(equalTo: rightAnchor)
    leftConstraint?.isActive = true
    rightConstraint?.isActive = true
  }
  
  private func setupHandleView() {
    
    leftHandleView.isUserInteractionEnabled = true
    leftHandleView.layer.cornerRadius = 2.0
    leftHandleView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(leftHandleView)
    
    leftHandleView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    leftHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
    leftHandleView.leftAnchor.constraint(equalTo: trimView.leftAnchor).isActive = true
    leftHandleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    
    leftHandleNotch.translatesAutoresizingMaskIntoConstraints = false
    leftHandleView.addSubview(leftHandleNotch)
    
    leftHandleNotch.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5).isActive = true
    leftHandleNotch.widthAnchor.constraint(equalToConstant: 2).isActive = true
    leftHandleNotch.centerYAnchor.constraint(equalTo: leftHandleView.centerYAnchor).isActive = true
    leftHandleNotch.centerXAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true
    
    rightHandleView.isUserInteractionEnabled = true
    rightHandleView.layer.cornerRadius = 2.0
    rightHandleView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(rightHandleView)
    
    rightHandleView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    rightHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
    rightHandleView.rightAnchor.constraint(equalTo: trimView.rightAnchor).isActive = true
    rightHandleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    
    rightHandleNotch.translatesAutoresizingMaskIntoConstraints = false
    rightHandleView.addSubview(rightHandleNotch)
    
    rightHandleNotch.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5).isActive = true
    rightHandleNotch.widthAnchor.constraint(equalToConstant: 2).isActive = true
    rightHandleNotch.centerYAnchor.constraint(equalTo: rightHandleView.centerYAnchor).isActive = true
    rightHandleNotch.centerXAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
  }
  
  private func setupMaskView() {
    
    leftMaskView.isUserInteractionEnabled = false
    leftMaskView.backgroundColor = .white
    leftMaskView.alpha = 0.7
    leftMaskView.translatesAutoresizingMaskIntoConstraints = false
    insertSubview(leftMaskView, belowSubview: leftHandleView)
    
    leftMaskView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    leftMaskView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    leftMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    leftMaskView.rightAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true
    
    rightMaskView.isUserInteractionEnabled = false
    rightMaskView.backgroundColor = .white
    rightMaskView.alpha = 0.7
    rightMaskView.translatesAutoresizingMaskIntoConstraints = false
    insertSubview(rightMaskView, belowSubview: rightHandleView)
    
    rightMaskView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    rightMaskView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    rightMaskView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    rightMaskView.leftAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
  }
  
  private func setupPositionBar() {
    
    positionBar.frame = CGRect(x: 0, y: 0, width: 3, height: frame.height)
    positionBar.center = CGPoint(x: leftHandleView.frame.maxX, y: center.y)
    positionBar.layer.cornerRadius = 1
    positionBar.translatesAutoresizingMaskIntoConstraints = false
    positionBar.isUserInteractionEnabled = false
    addSubview(positionBar)
    
    positionBar.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    positionBar.widthAnchor.constraint(equalToConstant: 3).isActive = true
    positionBar.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    positionConstraint = positionBar.leftAnchor.constraint(equalTo: leftHandleView.rightAnchor, constant: 0)
    positionConstraint?.isActive = true
  }
  
  private func setupGestures() {
    
    let leftPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
    leftHandleView.addGestureRecognizer(leftPanGestureRecognizer)
    let rightPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
    rightHandleView.addGestureRecognizer(rightPanGestureRecognizer)
  }
  
  // MARK: - Trim Gestures
  
  @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
    guard let view = gestureRecognizer.view, let superView = gestureRecognizer.view?.superview else { return }
    let isLeftGesture = view == leftHandleView
    switch gestureRecognizer.state {
        
      case .began:
        if isLeftGesture {
          currentLeftConstraint = leftConstraint!.constant
        } else {
          currentRightConstraint = rightConstraint!.constant
        }
        updateSelectedTime(stoppedMoving: false)
      case .changed:
        let translation = gestureRecognizer.translation(in: superView)
        if isLeftGesture {
          updateLeftConstraint(with: translation)
        } else {
          updateRightConstraint(with: translation)
        }
        layoutIfNeeded()
        if let startTime = startTime, isLeftGesture {
          seek(to: startTime)
        } else if let endTime = endTime {
          seek(to: endTime)
        }
        updateSelectedTime(stoppedMoving: false)
        
      case .cancelled, .ended, .failed:
        updateSelectedTime(stoppedMoving: true)
      default: break
    }
  }
  
  private func updateLeftConstraint(with translation: CGPoint) {
    let maxConstraint = max(rightHandleView.frame.origin.x - handleWidth - minimumDistanceBetweenHandle, 0)
    let newConstraint = min(max(0, currentLeftConstraint + translation.x), maxConstraint)
    leftConstraint?.constant = newConstraint
  }
  
  private func updateRightConstraint(with translation: CGPoint) {
    let maxConstraint = min(2 * handleWidth - frame.width + leftHandleView.frame.origin.x + minimumDistanceBetweenHandle, 0)
    let newConstraint = max(min(0, currentRightConstraint + translation.x), maxConstraint)
    rightConstraint?.constant = newConstraint
  }
  
  // MARK: - Asset loading
  
  private func assetDidChange(newAsset: AVAsset?) {
    leftConstraint?.constant = 0
    rightConstraint?.constant = 0
    layoutIfNeeded()
  }
  
  // MARK: - Time Equivalence
  
  private var durationSize: CGFloat {
    return assetPreview.contentSize.width
  }
  
  private func getTime(from position: CGFloat) -> CMTime? {
    guard let asset = asset else {
      return nil
    }
    let normalizedRatio = max(min(1, position / durationSize), 0)
    let positionTimeValue = Double(normalizedRatio) * Double(asset.duration.value)
    return CMTime(value: Int64(positionTimeValue), timescale: asset.duration.timescale)
  }
  
  private func getPosition(from time: CMTime) -> CGFloat? {
    guard let asset = asset else {
      return nil
    }
    let timeRatio = CGFloat(time.value) * CGFloat(asset.duration.timescale) /
    (CGFloat(time.timescale) * CGFloat(asset.duration.value))
    return timeRatio * durationSize
  }
  
  /// Move the position bar to the given time.
  public func seek(to time: CMTime) {
    if let newPosition = getPosition(from: time) {
      
      let offsetPosition = newPosition - assetPreview.contentOffset.x - leftHandleView.frame.origin.x
      let maxPosition = rightHandleView.frame.origin.x - (leftHandleView.frame.origin.x + handleWidth)
      - positionBar.frame.width
      let normalizedPosition = min(max(0, offsetPosition), maxPosition)
      positionConstraint?.constant = normalizedPosition
      layoutIfNeeded()
    }
  }
  
  /// The selected start time for the current asset.
  public var startTime: CMTime? {
    let startPosition = leftHandleView.frame.origin.x + assetPreview.contentOffset.x
    return getTime(from: startPosition)
  }
  
  /// The selected end time for the current asset.
  public var endTime: CMTime? {
    let endPosition = rightHandleView.frame.origin.x + assetPreview.contentOffset.x - handleWidth
    return getTime(from: endPosition)
  }
  
  private func updateSelectedTime(stoppedMoving: Bool) {
    guard let playerTime = positionBarTime else {
      return
    }
    if stoppedMoving {
      delegate?.positionBarStoppedMoving(playerTime)
    } else {
      delegate?.didChangePositionBar(playerTime)
    }
  }
  
  private var positionBarTime: CMTime? {
    let barPosition = positionBar.frame.origin.x + assetPreview.contentOffset.x - handleWidth
    return getTime(from: barPosition)
  }
  
  private var minimumDistanceBetweenHandle: CGFloat {
    guard let asset = asset else { return 0 }
    return CGFloat(minDuration) * assetPreview.contentView.frame.width / CGFloat(asset.duration.seconds)
  }
  
  // MARK: - Scroll View Delegate
  
  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    updateSelectedTime(stoppedMoving: true)
  }
  
  public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      updateSelectedTime(stoppedMoving: true)
    }
  }
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    updateSelectedTime(stoppedMoving: false)
  }
}

