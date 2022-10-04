//
//  VideoScrollView.swift
//  TrimVid
//
//  Created by Azhar Anwar on 04/10/22.
//

import AVFoundation
import UIKit

public final class VideoPreviewScrollView: UIScrollView {
  
  // MARK: - Properties
  
  private var widthConstraint: NSLayoutConstraint?
  
  public var maxDuration: Double = 15
  private var imageGenerator: AVAssetImageGenerator?
  
  // MARK: - Subviews
  
  public let contentView = UIView()
  
  // MARK: - init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = .clear
    showsVerticalScrollIndicator = false
    showsHorizontalScrollIndicator = false
    clipsToBounds = true
    
    contentView.backgroundColor = .clear
    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.tag = -1
    addSubview(contentView)
    
    NSLayoutConstraint.activate([
      contentView.leftAnchor.constraint(equalTo: leftAnchor),
      contentView.topAnchor.constraint(equalTo: topAnchor),
      contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
    
    widthConstraint = contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0)
    widthConstraint?.isActive = true
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Methods
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    contentSize = contentView.bounds.size
  }
  
  public func regenImages(forAsset asset: AVAsset) async {
    guard let thumbnailSize = await getImageSize(fromAsset: asset),
          thumbnailSize.width != 0 else { return }
    
    imageGenerator?.cancelAllCGImageGeneration()
    
    /// Remove all existing image thumbnails
    for subview in contentView.subviews {
      subview.removeFromSuperview()
    }
    
    let newThumbnailsSize = await setThumbnailContentSize(forAsset: asset)
    let visibleThumbnailsCount = Int(ceil(frame.width / thumbnailSize.width))
    
    let thumbnailCount = Int(ceil(newThumbnailsSize.width / thumbnailSize.width))
    addNewThumbnails(withCount: thumbnailCount, size: thumbnailSize)
    
    let timestampsForThumbnail = await fetchThumbnailTimes(forAsset: asset, withCount: thumbnailCount)
    createThumbnailImages(forAsset: asset, atTimestamps: timestampsForThumbnail, usingMaxSize: thumbnailSize, withVisibleThumbnailsCount: visibleThumbnailsCount)
  }
  
  private func createThumbnailImages(
    forAsset asset: AVAsset,
    atTimestamps timestamps: [NSValue],
    usingMaxSize maxSize: CGSize,
    withVisibleThumbnailsCount visibleCount: Int
  ) {
    imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator?.appliesPreferredTrackTransform = true
    
    let scaledImageSize = CGSize(
      width: maxSize.width * UIScreen.main.scale,
      height: maxSize.height * UIScreen.main.scale
    )
    
    imageGenerator?.maximumSize = scaledImageSize
    
    var count = 0
    
    imageGenerator?.generateCGImagesAsynchronously(forTimes: timestamps) { [weak self] (_, cgImage, _, result, error) in
      guard let self = self else { return }
      
      if let cgImage = cgImage, error == nil, result == .succeeded {
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          if count == 0 {
            self.displayFirstThumbnailImage(usingCGImage: cgImage, visibleThumbnailsCount: visibleCount)
          }
          self.displayThumbnail(withCGImage: cgImage, atIndex: count)
          count += 1
        }
      }
    }
    
  }
  
  private func displayFirstThumbnailImage(usingCGImage cgImage: CGImage, visibleThumbnailsCount count: Int) {
    for i in 0...count {
      displayThumbnail(withCGImage: cgImage, atIndex: i)
    }
  }
  
  private func displayThumbnail(withCGImage cgImage: CGImage, atIndex index: Int) {
    guard let imageView = contentView.viewWithTag(index) as? UIImageView else {return }
    let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    imageView.image = image
  }
  
  /// Use this method to calculate the time increment for thumbnails
  /// - Parameters:
  ///   - asset: The video asset
  ///   - count: Number of thumbnail images
  /// - Returns: Array of timestamps for thumbnails
  private func fetchThumbnailTimes(forAsset asset: AVAsset, withCount count: Int) async -> [NSValue] {
    guard let timeIncrement = try? await (asset.load(.duration).seconds * 1000) / Double(count) else { return [] }
    
    var timesForThumbnailImages: [NSValue] = []
    
    for i in 0..<count {
      let coreMediaTime = CMTime(value: Int64(timeIncrement * Float64(i)), timescale: 1000)
      let nsValue = NSValue(time: coreMediaTime)
      timesForThumbnailImages.append(nsValue)
    }
    
    return timesForThumbnailImages
  }
  
  
  /// Add new thumbnails to content view in relation to the width of the content view
  /// - Parameters:
  ///   - count: Total number of thumbnail images
  ///   - size: Size of each thumbnail image
  private func addNewThumbnails(withCount count: Int, size: CGSize) {
    for i in 0..<count {
      let imageView = UIImageView(frame: .zero)
      imageView.clipsToBounds = true
      
      let imageEndOnXAxis = CGFloat(i) * size.width + size.width
      
      if imageEndOnXAxis > contentView.frame.width {
        imageView.frame.size = CGSize(
          width: size.width + (contentView.frame.width - imageEndOnXAxis),
          height: size.height 
        )
      } else {
        imageView.frame.size = size
        imageView.contentMode = .scaleAspectFit
      }
      
      imageView.frame.origin = CGPoint(x: CGFloat(i) * size.width, y: 0)
      imageView.tag = i
      contentView.addSubview(imageView)
    }
  }
  
  /// Use this to get the size of the image from a video clip using its natural size
  /// - Parameter asset: The video asset
  /// - Returns: Video image size
  private func getImageSize(fromAsset asset: AVAsset) async -> CGSize? {
    
    do {
      let tracks = try await asset.loadTracks(withMediaType: .video)
      guard let track = tracks.first else { return .zero }
      
      let size = try await track.load(.naturalSize).applying(track.load(.preferredTransform))
      
      let height = frame.height
      let ratio = size.width / size.height
      
      let width = height * ratio
      return CGSize(width: abs(width), height: abs(height))
    } catch {
      return .zero
    }
  }
  
  /// Update the content view's width based on duration of the video asset
  /// - Parameter asset: The video asset
  /// - Returns: returns the new size of the content view 
  private func setThumbnailContentSize(forAsset asset: AVAsset) async -> CGSize {
    guard let thumbnailContentWidthFactor = try? await CGFloat(max(1, asset.load(.duration).seconds / maxDuration)) else { return .zero }
    
    widthConstraint?.isActive = false
    widthConstraint = contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: thumbnailContentWidthFactor)
    widthConstraint?.isActive = true
    layoutIfNeeded()
    return contentView.bounds.size
  }
}
