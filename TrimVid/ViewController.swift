//
//  ViewController.swift
//  TrimVid
//
//  Created by Azhar Anwar on 04/10/22.
//

import UIKit
import AVKit
import AVFoundation

public final class ViewController: UIViewController {
  
  // MARK: - Public properties
  
  // MARK: - Private properties
  
  private var player: AVPlayer?
  private var playbackTimeCheckerTimer: Timer?
  private var trimmerPositionChangedTime: Timer?
  
  // MARK: - Subviews
  
  private let playButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()
  
  private lazy var playerView: UIView = {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 32.0, height: 600.0))
    view.backgroundColor = .systemBackground
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  private lazy var trimmingView: TrimmingView = {
    let view = TrimmingView()
    view.delegate = self
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  // MARK: - View lifecycle
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .systemBackground
    
    setupSubviews()
    loadAsset()
  }
  
  // MARK: - Methods
  private func setupSubviews() {
    view.addSubview(playerView)
    NSLayoutConstraint.activate([
      playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      playerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
      playerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
      playerView.heightAnchor.constraint(equalToConstant: 600.0)
    ])
    
    view.addSubview(trimmingView)
    NSLayoutConstraint.activate([
      trimmingView.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 56.0),
      trimmingView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24.0),
      trimmingView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24.0),
      trimmingView.heightAnchor.constraint(equalToConstant: 56.0)
    ])
  }
  
  private func loadAsset() {
    guard let path = Bundle.main.url(forResource: "Pexels Videos 1722591", withExtension: "mp4") else { return }
    let asset = AVAsset(url: path)
    trimmingView.asset = asset
    addVideoPlayer(withAsset: asset, inPlayerView: playerView)
  }
  
  private func addVideoPlayer(withAsset asset: AVAsset, inPlayerView playerView: UIView) {
    let playerItem = AVPlayerItem(asset: asset)
    player = AVPlayer(playerItem: playerItem)
    
    let layer = AVPlayerLayer(player: player)
    layer.backgroundColor = UIColor.systemBackground.cgColor
    layer.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
    layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    
    if let sublayers = playerView.layer.sublayers {
      for sublayer in sublayers {
        sublayer.removeFromSuperlayer()
      }
    }
    
    playerView.layer.addSublayer(layer)
    player?.play()
  }
  
  @objc
  private func handleItemDidFinishPlaying() {
    
  }
  
  private func stopPlaybackTimeChecker() {
    playbackTimeCheckerTimer?.invalidate()
    playbackTimeCheckerTimer = nil
  }
  
  @objc
  private func handlePlaybackTimeChecker() {
    // TODO: -  Trimmer view start and end times
  }
  
  private func startPlaybackTimeChecker() {
    stopPlaybackTimeChecker()
    playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(handlePlaybackTimeChecker), userInfo: nil, repeats: true)
  }
  
  private func play() {
    guard let player = player, !player.isPlaying else {
      player?.pause()
      stopPlaybackTimeChecker()
      return 
    }
    player.play()
    startPlaybackTimeChecker()
  }
}

// MARK: - Trimming View Delegate
extension ViewController: TrimmingViewDelegate {
  public func handleDidChangePosition(atPlayerTime playerTime: CMTime) async {
    stopPlaybackTimeChecker()
    player?.pause()
    await player?.seek(to: playerTime, toleranceBefore: .zero, toleranceAfter: .zero)
    if let endTime = await trimmingView.endTime(),
       let startTime = await trimmingView.startTime() {
      let duration = (endTime - startTime).seconds
      print("CHANGED TRIM POSITION - \(duration)")
    }
  }
  
  public func handleDidStopMoving(atPlayerTime playerTime: CMTime) {
    player?.seek(to: playerTime, toleranceBefore: .zero, toleranceAfter: .zero)
    player?.play()
    startPlaybackTimeChecker()
  }
}
