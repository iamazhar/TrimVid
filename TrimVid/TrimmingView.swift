//
//  TrimmingView.swift
//  TrimVid
//
//  Created by Azhar Anwar on 04/10/22.
//

import UIKit
import AVFoundation

public protocol TrimmingViewDelegate: AnyObject {
  func handleDidChangePosition(atPlayerTime playerTime: CMTime) async
  func handleDidStopMoving(atPlayerTime playerTime: CMTime)
}

public final class TrimmingView: UIView, UIScrollViewDelegate {
  
  // MARK: - Colors
  
  public var mainBorderColor: UIColor = .blue
  public var handleColor: UIColor = .orange
  public var maskedVideoPortionColor: UIColor = .gray
  
  // MARK: - Properties
  
  public weak var delegate: TrimmingViewDelegate?
  
  public var maxDuration: Double = 15.0 {
    didSet {
      videoPreviewScrollView.maxDuration = maxDuration
    }
  }
  
  public var asset: AVAsset? {
    didSet {
      // TODO: - 
    }
  }
  
  public var videoPreviewWidth: CGFloat {
    return videoPreviewScrollView.contentSize.width
  }
  
  private var currentLeftHandleConstraintConstant: CGFloat = 0.0
  private var currentRightHandleConstraintConstant: CGFloat = 0.0
  private var leftHandleConstraint: NSLayoutConstraint?
  private var rightHandleConstraint: NSLayoutConstraint?
  private var playheadConstraint: NSLayoutConstraint?
  
  private let handleWidth: CGFloat = 15.0
  
  private let minDuration: Double = 3.0
  
  // MARK: - Subviews
  
  private let videoPreviewScrollView = VideoPreviewScrollView()
  
  private let trimView: UIView = {
    let view = UIView()
    view.layer.borderWidth = 2.0
    view.layer.cornerRadius = 2.0
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    return view
  }()
  
  private let leftHandleView: UIView = {
    let view = UIView()
    view.isUserInteractionEnabled = true
    view.layer.cornerRadius = 2.0
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  private let rightHandleView: UIView = {
    let view = UIView()
    view.isUserInteractionEnabled = true
    view.layer.cornerRadius = 2.0
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  private lazy var playheadView: UIView = {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 3, height: frame.height))
    view.backgroundColor = .systemTeal
    view.center = CGPoint(x: leftHandleView.frame.maxX, y: center.y)
    view.layer.cornerRadius = 1
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    return view
  }()
  
  private let leftMaskView: UIView = {
    let view = UIView()
    view.isUserInteractionEnabled = false
    view.backgroundColor = .white
    view.alpha = 0.7
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  private let rightMaskView: UIView = {
    let view = UIView()
    view.isUserInteractionEnabled = false
    view.backgroundColor = .white
    view.alpha = 0.7
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  // MARK: - init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    layer.cornerRadius = 2.0
    layer.masksToBounds = true
    backgroundColor = .clear
    layer.zPosition = 1
    
    /// Setup video preview view
    self.translatesAutoresizingMaskIntoConstraints = false
    videoPreviewScrollView.translatesAutoresizingMaskIntoConstraints = false
    videoPreviewScrollView.delegate = self
    addSubview(videoPreviewScrollView)
    
    NSLayoutConstraint.activate([
      videoPreviewScrollView.leftAnchor.constraint(equalTo: leftAnchor),
      videoPreviewScrollView.rightAnchor.constraint(equalTo: rightAnchor),
      videoPreviewScrollView.topAnchor.constraint(equalTo: topAnchor),
      videoPreviewScrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
    
    /// Setup trimming view
    addSubview(trimView)
    NSLayoutConstraint.activate([
      trimView.topAnchor.constraint(equalTo: topAnchor),
      trimView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    leftHandleConstraint = trimView.leftAnchor.constraint(equalTo: leftAnchor)
    rightHandleConstraint = trimView.rightAnchor.constraint(equalTo: rightAnchor)
    leftHandleConstraint?.isActive = true
    rightHandleConstraint?.isActive = true
    
    /// Setup left handle view
    addSubview(leftHandleView)
    NSLayoutConstraint.activate([
      leftHandleView.heightAnchor.constraint(equalTo: heightAnchor),
      leftHandleView.widthAnchor.constraint(equalToConstant: handleWidth),
      leftHandleView.leftAnchor.constraint(equalTo: trimView.leftAnchor),
      leftHandleView.centerYAnchor.constraint(equalTo: centerYAnchor)
    ])
    
    /// Setup right handle view
    addSubview(rightHandleView)
    NSLayoutConstraint.activate([
      rightHandleView.heightAnchor.constraint(equalTo: heightAnchor),
      rightHandleView.widthAnchor.constraint(equalToConstant: handleWidth),
      rightHandleView.rightAnchor.constraint(equalTo: trimView.rightAnchor),
      rightHandleView.centerYAnchor.constraint(equalTo: centerYAnchor)
    ])
    
    /// Setup Mask views
    insertSubview(leftMaskView, belowSubview: leftHandleView)
    NSLayoutConstraint.activate([
      leftMaskView.leftAnchor.constraint(equalTo: leftAnchor),
      leftMaskView.bottomAnchor.constraint(equalTo: bottomAnchor),
      leftMaskView.topAnchor.constraint(equalTo: topAnchor),
      leftMaskView.rightAnchor.constraint(equalTo: leftHandleView.centerXAnchor)
    ])
    
    insertSubview(rightMaskView, belowSubview: rightHandleView)
    NSLayoutConstraint.activate([
      rightMaskView.rightAnchor.constraint(equalTo: rightAnchor),
      rightMaskView.bottomAnchor.constraint(equalTo: bottomAnchor),
      rightMaskView.topAnchor.constraint(equalTo: topAnchor),
      rightMaskView.leftAnchor.constraint(equalTo: rightHandleView.centerXAnchor)
    ])
    
    /// Setup playhead
    addSubview(playheadView)
    NSLayoutConstraint.activate([
      playheadView.centerYAnchor.constraint(equalTo: centerYAnchor),
      playheadView.widthAnchor.constraint(equalToConstant: 3),
      playheadView.heightAnchor.constraint(equalTo: heightAnchor)
    ])
    playheadConstraint = playheadView.leftAnchor.constraint(equalTo: leftHandleView.rightAnchor, constant: 0)
    playheadConstraint?.isActive = true
    
    /// Add gestures
    leftHandleView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_ :))))
    rightHandleView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_ :))))
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Methods
  
  @objc
  private func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) async {
    guard let view = gestureRecognizer.view,
          let superView = gestureRecognizer.view?.superview else { return }
    
    switch gestureRecognizer.state {
      case .began:
        if view == leftHandleView {
          // TODO: - Improvement -> Safely unwrap before use
          currentLeftHandleConstraintConstant = leftHandleConstraint?.constant ?? 0.0
        } else {
          // TODO: - Improvement -> Safely unwrap before use
          currentRightHandleConstraintConstant = rightHandleConstraint?.constant ?? 0.0
        }
        await updateSelectedTrimWindow(didStopMoving: false)
        
      case .changed:
        let translation = gestureRecognizer.translation(in: superView)
        if view == leftHandleView {
          await updateLeftHandleConstraint(withTranslation: translation)
        } else {
          await updateRightHandleConstraint(withTranslation: translation)
        }
        layoutIfNeeded()
        
        if let startTime = await startTime(), view == leftHandleView {
          await movePlayhead(toTime: startTime)
        } else if let endTime = await endTime() {
          await movePlayhead(toTime: endTime)
        }
        await updateSelectedTrimWindow(didStopMoving: false)
        
      case .cancelled:
        await updateSelectedTrimWindow(didStopMoving: true)
        
      case .ended:
        await updateSelectedTrimWindow(didStopMoving: true)
        
      case .failed:
        await updateSelectedTrimWindow(didStopMoving: true)
      
      case .possible:
        break
        
      default:
        break
    }
  }
  
  // MARK: - Time and position methods
  
  public func movePlayhead(toTime time: CMTime) async {
    guard let newPosition = await fetchPosition(fromCMTime: time) else { return }
    
    let offsetPosition = newPosition - videoPreviewScrollView.contentOffset.x - leftHandleView.frame.origin.x
    let maxPosition = rightHandleView.frame.origin.x - (leftHandleView.frame.origin.x + handleWidth) - playheadView.frame.width
    let position = min(max(0, offsetPosition),maxPosition)
    playheadConstraint?.constant = position
    layoutIfNeeded()
  }
  
  /// The selected start time for the current video asset
  public func startTime() async -> CMTime? {
    let startPosition = leftHandleView.frame.origin.x + videoPreviewScrollView.contentOffset.x
    return await fetchTimestamp(forPosition: startPosition)
  }
  
  /// The selected end time for the current video asset
  public func endTime() async -> CMTime? {
    let endPosition = rightHandleView.frame.origin.x + videoPreviewScrollView.contentOffset.x - handleWidth
    return await fetchTimestamp(forPosition: endPosition)
  }
  
  // TODO: - updateLeftHandleConstraint and updateRightHandleConstraint can be consolidated into one method
  private func updateLeftHandleConstraint(withTranslation translation: CGPoint) async {
    guard let asset = asset, 
            let minimumDistanceBetweenHandle = try? await CGFloat(minDuration) * videoPreviewScrollView.contentView.frame.width / CGFloat(asset.load(.duration).seconds)
    else { return }
    
    let maxConstraint = max(rightHandleView.frame.origin.x - handleWidth - minimumDistanceBetweenHandle, 0)
    let newConstraint = min(max(0, currentLeftHandleConstraintConstant + translation.x), maxConstraint)
    leftHandleConstraint?.constant = newConstraint
  }
  
  private func updateRightHandleConstraint(withTranslation translation: CGPoint) async {
    guard let asset = asset, 
            let minimumDistanceBetweenHandle = try? await CGFloat(minDuration) * videoPreviewScrollView.contentView.frame.width / CGFloat(asset.load(.duration).seconds)
    else { return }
    
    let maxConstraint = min(2 * handleWidth - frame.width + leftHandleView.frame.origin.x + minimumDistanceBetweenHandle, 0)
    let newConstraint = max(min(0, currentRightHandleConstraintConstant + translation.x), maxConstraint)
    rightHandleConstraint?.constant = newConstraint
  }
  
  private func updateSelectedTrimWindow(didStopMoving stoppedMoving: Bool) async {
    let playheadPosition = playheadView.frame.origin.x + videoPreviewScrollView.contentOffset.x - handleWidth
    guard let timestamp = await fetchTimestamp(forPosition: playheadPosition) else { return }
    
    if stoppedMoving {
      delegate?.handleDidStopMoving(atPlayerTime: timestamp)
    } else {
      await delegate?.handleDidChangePosition(atPlayerTime: timestamp)
    }
  }
  
  public func regenThumbnails() async {
    guard let asset = asset else { return }
    await videoPreviewScrollView.regenImages(forAsset: asset)
  }
  
  public func fetchTimestamp(forPosition position: CGFloat) async -> CMTime? {
    guard let asset = asset else { return nil }
    
    let ratio = max(min(1, position/videoPreviewWidth), 0)
    do {
      let positionTimestamp = try await Double(ratio) * Double(asset.load(.duration).value)
      return try await CMTime(value: Int64(positionTimestamp), timescale: asset.load(.duration).timescale)
    } catch {
      /// Error handling
    }
    return nil
  }
  
  public func fetchPosition(fromCMTime time: CMTime) async -> CGFloat? {
    guard let asset = asset else { return nil }
    do {
      let ratio = try await CGFloat(time.value) * CGFloat(asset.load(.duration).timescale) /
      (CGFloat(time.timescale) * CGFloat(asset.load(.duration).value))      
      return ratio * videoPreviewWidth
    } catch {
      /// Error handling
    }
    return nil
  }
}

extension TrimmingView {
  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) async {
    await updateSelectedTrimWindow(didStopMoving: true)
  }
  
  public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) async {
    if !decelerate {
      await updateSelectedTrimWindow(didStopMoving: true)
    }
  }
  public func scrollViewDidScroll(_ scrollView: UIScrollView) async {
    await updateSelectedTrimWindow(didStopMoving: false)
  }
}
