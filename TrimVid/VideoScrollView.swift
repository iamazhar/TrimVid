//
//  AssetVideoScrollView.swift
//  TrimVid
//
//  Created by Azhar Anwar on 04/10/22.
//

import AVFoundation
import UIKit

/// Thumbnail generation logic can reside in this class
public final class VideoScrollView: UIScrollView {
  
  // MARK: - Properties
  
  private var widthConstraint: NSLayoutConstraint?
  public var maxDuration: Double = 15
  
  // MARK: - Subviews
  
  public let contentView = UIView()
  
  // MARK: - init  
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    showsVerticalScrollIndicator = false
    showsHorizontalScrollIndicator = false
    clipsToBounds = true
    
    setupSubviews()
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    contentSize = contentView.bounds.size
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  // MARK: - Methods
  
  private func setupSubviews() {
    contentView.backgroundColor = .clear
    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.tag = 100
    addSubview(contentView)
    
    NSLayoutConstraint.activate([
      contentView.leftAnchor.constraint(equalTo: leftAnchor),
      contentView.topAnchor.constraint(equalTo: topAnchor),
      contentView.bottomAnchor.constraint(equalTo: bottomAnchor)    
    ])
    
    widthConstraint = contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0)
    widthConstraint?.isActive = true
  }
  
}
