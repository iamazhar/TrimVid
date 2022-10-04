//
//  AssetVideoScrollView.swift
//  TrimVid
//
//  Created by Azhar Anwar on 04/10/22.
//

import AVFoundation
import UIKit

public class VideoScrollView: UIScrollView {
  
  private var widthConstraint: NSLayoutConstraint?
  
  public let contentView = UIView()
  public var maxDuration: Double = 15
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    showsVerticalScrollIndicator = false
    showsHorizontalScrollIndicator = false
    clipsToBounds = true
    
    setupSubviews()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  private func setupSubviews() {
    contentView.backgroundColor = .clear
    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.tag = -1
    addSubview(contentView)
    
    contentView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    contentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    widthConstraint = contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0)
    widthConstraint?.isActive = true
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    contentSize = contentView.bounds.size
  }
  
  private func setContentSize(for asset: AVAsset) -> CGSize {
    
    let contentWidthFactor = CGFloat(max(1, asset.duration.seconds / maxDuration))
    widthConstraint?.isActive = false
    widthConstraint = contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: contentWidthFactor)
    widthConstraint?.isActive = true
    layoutIfNeeded()
    return contentView.bounds.size
  }
}
