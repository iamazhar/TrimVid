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
  
  // MARK: - Private properties
  
  private var player: AVPlayer?
  private var playbackTimeCheckerTimer: Timer?
  private var trimmerPositionChangedTime: Timer?
  
  // MARK: - Subviews
  
  private lazy var playButton: UIButton = {
    let button = UIButton()
    button.setTitle("Play", for: .normal)
    button.titleLabel?.font = .boldSystemFont(ofSize: 18.0)
    button.setTitleColor(.systemPurple, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
    return button
  }()
  
  private lazy var exportButton: UIButton = {
    let button = UIButton()
    button.titleLabel?.font = .boldSystemFont(ofSize: 18.0)
    button.setTitle("Export", for: .normal)
    button.setTitleColor(.systemPurple, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(handleExport), for: .touchUpInside)
    return button
  }()
  
  @objc
  private func handleExport() {
    // TODO: - 
  }
  
  @objc
  private func handlePlay() {
    play()
  }
  
  private lazy var playerView: UIView = {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 32.0, height: 600.0))
    view.backgroundColor = .systemBackground
    view.layer.cornerCurve = .continuous
    view.layer.cornerRadius = 12.0
    view.clipsToBounds =  true
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  private lazy var trimmerView: TrimmerView = {
    let view = TrimmerView()
    view.delegate = self
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
    
    view.addSubview(trimmerView)
    NSLayoutConstraint.activate([
      trimmerView.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 24.0),
      trimmerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24.0),
      trimmerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24.0),
      trimmerView.heightAnchor.constraint(equalToConstant: 56.0)
    ])
    
    view.addSubview(playButton)
    NSLayoutConstraint.activate([
      playButton.heightAnchor.constraint(equalToConstant: 56.0),
      playButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      playButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0)
    ])
    
    view.addSubview(exportButton)
    NSLayoutConstraint.activate([
      exportButton.heightAnchor.constraint(equalToConstant: 56.0),
      exportButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      exportButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0)
    ])
  }
  
  private func loadAsset() {
    guard let path = Bundle.main.url(forResource: "Pexels Videos 1722591", withExtension: "mp4") else { return }
    let asset = AVAsset(url: path)
    trimmerView.asset = asset
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
  }
  
  private func stopPlaybackTimeChecker() {
    playbackTimeCheckerTimer?.invalidate()
    playbackTimeCheckerTimer = nil
  }
  
  @objc
  private func handlePlaybackTimeChecker() {
    guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime, let player = player else {
        return
    }

    let playBackTime = player.currentTime()
    trimmerView.seek(to: playBackTime)

    if playBackTime >= endTime {
        player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        trimmerView.seek(to: startTime)
    }
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

// MARK: - Trimmer View Delegate
extension ViewController: TrimmerViewDelegate {
    public func positionBarStoppedMoving(_ playerTime: CMTime) {
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        player?.play()
        startPlaybackTimeChecker()
    }

    public func didChangePositionBar(_ playerTime: CMTime) {
        stopPlaybackTimeChecker()
        player?.pause()
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
        print(duration)
    }
}
