//
//  VideoTrimmerView.swift
//  TrimVid
//
//  Created by Azhar Anwar on 04/10/22.
//

import AVFoundation
import UIKit

public protocol VideoTrimmerViewDelegate: AnyObject {
  func didChangePlayhead(_ playerTime: CMTime)
  func playheadStoppedMoving(_ playerTime: CMTime)
}

/// Use this class to setup the custom trimming control
public class VideoTrimmerView: UIView, UIScrollViewDelegate {
  
  // MARK: - Properties
  
  public var asset: AVAsset?
  
  public weak var delegate: VideoTrimmerViewDelegate?
  
  private let handleWidth: CGFloat = 15
  
  public var minDuration: Double = 3
  
  /// Use this property as source of truth for this view and VideoScrollView.
  /// Use this to generate thumbnails in VideoScrollView
  public var maxDuration: Double = 15 {
    didSet {
      videoScrollView.maxDuration = maxDuration
    }
  }
  
  // MARK: - Subviews
  
  private let videoScrollView = VideoScrollView()
  
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
  
  private let leftHandleNotch: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    view.layer.cornerRadius = 4.0
    return view
  }()
  
  private let rightHandleNotch: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    view.layer.cornerRadius = 4.0
    return view
  }()
  
  private let playheadView = UIView()
  private let leftMaskView = UIView()
  private let rightMaskView = UIView()
  
  // MARK: - Constraints
  
  private var currentLeftHandleConstraintConstant: CGFloat = 0
  private var currentRightHandleConstraintConstant: CGFloat = 0
  private var leftTrimConstraint: NSLayoutConstraint?
  private var rightTrimConstraint: NSLayoutConstraint?
  private var playheadPositionConstraint: NSLayoutConstraint?
  
  // MARK: - init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    layer.cornerRadius = 2
    layer.masksToBounds = true
    backgroundColor = UIColor.clear
    layer.zPosition = 1
    translatesAutoresizingMaskIntoConstraints = false
    
    setupVideoAssetPreview()
    setupTrimView()
    setupHandleView()
    setupMaskView()
    setupPlayhead()
    setupPanGestures()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Methods
  
  private func setupVideoAssetPreview() {
    videoScrollView.translatesAutoresizingMaskIntoConstraints = false
    videoScrollView.delegate = self
    addSubview(videoScrollView)
    
    NSLayoutConstraint.activate([
      videoScrollView.leftAnchor.constraint(equalTo: leftAnchor),
      videoScrollView.rightAnchor.constraint(equalTo: rightAnchor),
      videoScrollView.topAnchor.constraint(equalTo: topAnchor),
      videoScrollView.bottomAnchor.constraint(equalTo: bottomAnchor)    
    ])
    
  }
  
  private func setupTrimView() {
    trimView.layer.borderWidth = 2.0
    trimView.layer.cornerRadius = 6.0
    trimView.translatesAutoresizingMaskIntoConstraints = false
    trimView.isUserInteractionEnabled = false
    addSubview(trimView)
    
    NSLayoutConstraint.activate([
      trimView.topAnchor.constraint(equalTo: topAnchor),
      trimView.bottomAnchor.constraint(equalTo: bottomAnchor)    
    ])
    
    leftTrimConstraint = trimView.leftAnchor.constraint(equalTo: leftAnchor)
    rightTrimConstraint = trimView.rightAnchor.constraint(equalTo: rightAnchor)
    leftTrimConstraint?.isActive = true
    rightTrimConstraint?.isActive = true
  }
  
  private func setupHandleView() {
    leftHandleView.isUserInteractionEnabled = true
    leftHandleView.layer.cornerRadius = 6.0
    leftHandleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
    leftHandleView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(leftHandleView)
    
    NSLayoutConstraint.activate([
      leftHandleView.heightAnchor.constraint(equalTo: heightAnchor),
      leftHandleView.widthAnchor.constraint(equalToConstant: handleWidth),
      leftHandleView.leftAnchor.constraint(equalTo: trimView.leftAnchor),
      leftHandleView.centerYAnchor.constraint(equalTo: centerYAnchor)
    ])
    
    leftHandleNotch.translatesAutoresizingMaskIntoConstraints = false
    leftHandleView.addSubview(leftHandleNotch)
    
    NSLayoutConstraint.activate([
      leftHandleNotch.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5),
      leftHandleNotch.widthAnchor.constraint(equalToConstant: 2),
      leftHandleNotch.centerYAnchor.constraint(equalTo: leftHandleView.centerYAnchor),
      leftHandleNotch.centerXAnchor.constraint(equalTo: leftHandleView.centerXAnchor)    
    ])
    
    rightHandleView.isUserInteractionEnabled = true
    rightHandleView.layer.cornerRadius = 6.0
    rightHandleView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    rightHandleView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(rightHandleView)
    
    NSLayoutConstraint.activate([
      rightHandleView.heightAnchor.constraint(equalTo: heightAnchor),
      rightHandleView.widthAnchor.constraint(equalToConstant: handleWidth),
      rightHandleView.rightAnchor.constraint(equalTo: trimView.rightAnchor),
      rightHandleView.centerYAnchor.constraint(equalTo: centerYAnchor)    
    ])
    
    rightHandleNotch.translatesAutoresizingMaskIntoConstraints = false
    rightHandleView.addSubview(rightHandleNotch)
    
    NSLayoutConstraint.activate([
      rightHandleNotch.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5),
      rightHandleNotch.widthAnchor.constraint(equalToConstant: 2),
      rightHandleNotch.centerYAnchor.constraint(equalTo: rightHandleView.centerYAnchor),
      rightHandleNotch.centerXAnchor.constraint(equalTo: rightHandleView.centerXAnchor)    
    ])
  }
  
  private func setupMaskView() {
    leftMaskView.isUserInteractionEnabled = false
    leftMaskView.backgroundColor = .white
    leftMaskView.layer.cornerRadius = 6.0
    leftMaskView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
    leftMaskView.alpha = 0.7
    leftMaskView.translatesAutoresizingMaskIntoConstraints = false
    insertSubview(leftMaskView, belowSubview: leftHandleView)
    
    NSLayoutConstraint.activate([
      leftMaskView.leftAnchor.constraint(equalTo: leftAnchor),
      leftMaskView.bottomAnchor.constraint(equalTo: bottomAnchor),
      leftMaskView.topAnchor.constraint(equalTo: topAnchor),
      leftMaskView.rightAnchor.constraint(equalTo: leftHandleView.centerXAnchor)    
    ])
    
    rightMaskView.isUserInteractionEnabled = false
    rightMaskView.backgroundColor = .white
    rightMaskView.layer.cornerRadius = 6.0
    rightMaskView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    rightMaskView.alpha = 0.7
    rightMaskView.translatesAutoresizingMaskIntoConstraints = false
    insertSubview(rightMaskView, belowSubview: rightHandleView)
    
    NSLayoutConstraint.activate([
      rightMaskView.rightAnchor.constraint(equalTo: rightAnchor),
      rightMaskView.bottomAnchor.constraint(equalTo: bottomAnchor),
      rightMaskView.topAnchor.constraint(equalTo: topAnchor),
      rightMaskView.leftAnchor.constraint(equalTo: rightHandleView.centerXAnchor)    
    ])
  }
  
  private func setupPlayhead() {
    playheadView.frame = CGRect(x: 0, y: 0, width: 3, height: frame.height)
    playheadView.center = CGPoint(x: leftHandleView.frame.maxX, y: center.y)
    playheadView.backgroundColor = .white
    playheadView.translatesAutoresizingMaskIntoConstraints = false
    playheadView.isUserInteractionEnabled = false
    addSubview(playheadView)
    
    NSLayoutConstraint.activate([
      playheadView.centerYAnchor.constraint(equalTo: centerYAnchor),
      playheadView.widthAnchor.constraint(equalToConstant: 3),
      playheadView.heightAnchor.constraint(equalTo: heightAnchor)    
    ])
    
    playheadPositionConstraint = playheadView.leftAnchor.constraint(equalTo: leftHandleView.rightAnchor, constant: 0)
    playheadPositionConstraint?.isActive = true
  }
  
  private func setupPanGestures() {
    let leftPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
    leftHandleView.addGestureRecognizer(leftPanGesture)
    
    let rightPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
    rightHandleView.addGestureRecognizer(rightPanGesture)
  }
  
  // MARK: - Pan Gesture
  
  @objc 
  func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
    guard let view = gestureRecognizer.view,
          let superView = gestureRecognizer.view?.superview else { return }
    
    switch gestureRecognizer.state {
        
      case .began:
        if view == leftHandleView, let leftTrimConstraint = leftTrimConstraint {
          currentLeftHandleConstraintConstant = leftTrimConstraint.constant
        } else {
          if let rightTrimConstraint = rightTrimConstraint {
            currentRightHandleConstraintConstant = rightTrimConstraint.constant            
          }
        }
        updateSelectedTime(stoppedMoving: false)
        
      case .changed:
        let translation = gestureRecognizer.translation(in: superView)
        if view == leftHandleView {
          updateLeftConstraint(with: translation)
        } else {
          updateRightConstraint(with: translation)
        }
        layoutIfNeeded()
        
        if let startTime = startTime, view == leftHandleView {
          seek(toTime: startTime)
        } else if let endTime = endTime {
          seek(toTime: endTime)
        }
        updateSelectedTime(stoppedMoving: false)
        
      case .cancelled, .ended, .failed:
        updateSelectedTime(stoppedMoving: true)
        
      default: 
        break
    }
  }
  
  private func updateLeftConstraint(with translation: CGPoint) {
    let maxConstraint = max(rightHandleView.frame.origin.x - handleWidth - minimumDistanceBetweenHandles, 0)
    let newConstraint = min(max(0, currentLeftHandleConstraintConstant + translation.x), maxConstraint)
    leftTrimConstraint?.constant = newConstraint
  }
  
  private func updateRightConstraint(with translation: CGPoint) {
    let maxConstraint = min(2 * handleWidth - frame.width + leftHandleView.frame.origin.x + minimumDistanceBetweenHandles, 0)
    let newConstraint = max(min(0, currentRightHandleConstraintConstant + translation.x), maxConstraint)
    rightTrimConstraint?.constant = newConstraint
  }
  
  // MARK: - Video time and position methods and properties
  
  /// Le Secret sauce
  
  private var durationWidth: CGFloat {
    return videoScrollView.contentSize.width
  }
  
  private func getTime(from position: CGFloat) -> CMTime? {
    guard let asset = asset else {
      return nil
    }
    let ratio = max(min(1, position / durationWidth), 0)
    let positionTimeValue = Double(ratio) * Double(asset.duration.value)
    return CMTime(value: Int64(positionTimeValue), timescale: asset.duration.timescale)
  }
  
  private func getPosition(from time: CMTime) -> CGFloat? {
    guard let asset = asset else {
      return nil
    }
    /// We can also do a simpler
    // let timeRatio = CGFloat(time.seconds / asset.duration.seconds)
    /// but it can come at the cost of decimal accuracy so
    ///  I chose to divide the source fractions to improve the decimal point accuracy and hence the derived position value
    let timeRatio = CGFloat(time.value) * CGFloat(asset.duration.timescale) /
    (CGFloat(time.timescale) * CGFloat(asset.duration.value))
    
    return timeRatio * durationWidth
  }
  
  /// Move the position bar to the given time.
  public func seek(toTime time: CMTime) {
    if let newPosition = getPosition(from: time) {
      let offsetPosition = newPosition - videoScrollView.contentOffset.x - leftHandleView.frame.origin.x
      let maxPosition = rightHandleView.frame.origin.x - (leftHandleView.frame.origin.x + handleWidth)
      - playheadView.frame.width
      let normalizedPosition = min(max(0, offsetPosition), maxPosition)
      playheadPositionConstraint?.constant = normalizedPosition
      layoutIfNeeded()
    }
  }
  
  /// Corresponds to the playhead's positive relative to the left handle
  public var startTime: CMTime? {
    let startPosition = leftHandleView.frame.origin.x + videoScrollView.contentOffset.x
    return getTime(from: startPosition)
  }
  
  /// Corresponds to the playhead's positive relative to the right handle
  public var endTime: CMTime? {
    let endPosition = rightHandleView.frame.origin.x + videoScrollView.contentOffset.x - handleWidth
    return getTime(from: endPosition)
  }
  
  private func updateSelectedTime(stoppedMoving: Bool) {
    guard let playerTime = playheadTime else { return }
    
    if stoppedMoving {
      delegate?.playheadStoppedMoving(playerTime)
    } else {
      delegate?.didChangePlayhead(playerTime)
    }
  }
  
  /// Calculated by adding the scroll view's content to playhead's origin and subtracting the right handle's width
  private var playheadTime: CMTime? {
    let playheadPosition = playheadView.frame.origin.x + videoScrollView.contentOffset.x - handleWidth
    return getTime(from: playheadPosition)
  }
  
  /// Calculated by dividing width of the scroll view by video duration and using a minimum duration as a multiplier to
  /// derive minimum handle distance
  private var minimumDistanceBetweenHandles: CGFloat {
    guard let asset = asset else { return 0 }
    return CGFloat(minDuration) * videoScrollView.contentView.frame.width / CGFloat(asset.duration.seconds)
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