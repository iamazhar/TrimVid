//
//  ViewController.swift
//  TrimVid
//
//  Created by Azhar Anwar on 04/10/22.
//

import UIKit
import AVKit
import AVFoundation
import Photos

public final class ViewController: UIViewController {
  
  // MARK: - Private properties
  
  private var player: AVPlayer?
  private var playbackTimer: Timer?
  
  // MARK: - Subviews
  
  public let startTimeLabel: UILabel = {
    let view = UILabel()
    view.numberOfLines = 1
    view.textAlignment = .center
    view.font = UIFont.systemFont(ofSize: 14.0)
    view.textColor = .white
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  public let endTimeLabel: UILabel = {
    let view = UILabel()
    view.numberOfLines = 1
    view.textAlignment = .center
    view.font = UIFont.systemFont(ofSize: 14.0)
    view.textColor = .white
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
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
    guard let asset = trimmerView.asset,
          let startTime = trimmerView.startTime,
          let endTime = trimmerView.endTime
    else { return }
    
    ExportHelper.export(asset, startTime: startTime, endTime: endTime) { saved, error in
      if error != nil {
        let alertController = UIAlertController(title: "Failed to save your video", message: error?.localizedDescription, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
        return
      }
      
      let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
      let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
      alertController.addAction(defaultAction)
      self.present(alertController, animated: true, completion: nil)        
    }
  }
  
  @objc
  private func handlePlay() {
    play()
  }
  
  private lazy var playerView: UIView = {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 32.0, height: 500.0))
    view.backgroundColor = .systemBackground
    view.layer.cornerCurve = .continuous
    view.layer.cornerRadius = 16.0
    view.clipsToBounds =  true
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  private lazy var trimmerView: VideoTrimmerView = {
    let view = VideoTrimmerView()
    view.delegate = self
    return view
  }()
  
  // MARK: - View lifecycle
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .black
    
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
      playerView.heightAnchor.constraint(equalToConstant: 500.0)
    ])
    
    view.addSubview(trimmerView)
    NSLayoutConstraint.activate([
      trimmerView.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 24.0),
      trimmerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24.0),
      trimmerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24.0),
      trimmerView.heightAnchor.constraint(equalToConstant: 56.0)
    ])
    
    view.addSubview(startTimeLabel)
    NSLayoutConstraint.activate([
      startTimeLabel.topAnchor.constraint(equalTo: trimmerView.bottomAnchor, constant: 12.0),
      startTimeLabel.leadingAnchor.constraint(equalTo: trimmerView.leadingAnchor)
    ])
    
    view.addSubview(endTimeLabel)
    NSLayoutConstraint.activate([
      endTimeLabel.topAnchor.constraint(equalTo: trimmerView.bottomAnchor, constant: 12.0),
      endTimeLabel.trailingAnchor.constraint(equalTo: trimmerView.trailingAnchor)
    ])
    
    view.addSubview(playButton)
    NSLayoutConstraint.activate([
      playButton.heightAnchor.constraint(equalToConstant: 56.0),
      playButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      playButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24.0)
    ])
    
    view.addSubview(exportButton)
    NSLayoutConstraint.activate([
      exportButton.heightAnchor.constraint(equalToConstant: 56.0),
      exportButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      exportButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24.0)
    ])
  }
  
  private func loadAsset() {
    guard let path = Bundle.main.url(forResource: "Pexels Videos 1722591", withExtension: "mp4") else { return }
    let asset = AVAsset(url: path)
    trimmerView.asset = asset
    addVideoPlayer(withAsset: asset)
  }
  
  private func addVideoPlayer(withAsset asset: AVAsset) {
    let playerItem = AVPlayerItem(asset: asset)
    player = AVPlayer(playerItem: playerItem)
    
    let layer = AVPlayerLayer(player: player)
    layer.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
    layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    
    if let sublayers = playerView.layer.sublayers {
      for sublayer in sublayers {
        sublayer.removeFromSuperlayer()
      }
    }
    
    playerView.layer.addSublayer(layer)
  }
  
  @objc
  /// This selector method is triggered by the playback timer
  private func handlePlaybackTimer() {
    guard let startTime = trimmerView.startTime,
          let endTime = trimmerView.endTime,
          let player = player else { return }
    
    let playBackTime = player.currentTime()
    trimmerView.seek(toTime: playBackTime)
    
    if playBackTime >= endTime {
      player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
      trimmerView.seek(toTime: startTime)
    }
  }
  
  private func stopPlaybackTimer() {
    playbackTimer?.invalidate()
    playbackTimer = nil
  }
  
  private func startPlaybackTimer() {
    /// Make sure to always stop the current timer and set it to nil before starting the timer again
    stopPlaybackTimer()
    playbackTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(handlePlaybackTimer), userInfo: nil, repeats: true)
  }
  
  private func play() {
    guard let player = player, !player.isPlaying else {
      player?.pause()
      stopPlaybackTimer()
      return 
    }
    
    player.play()
    startPlaybackTimer()
  }
}

// MARK: - Trimmer View Delegate
extension ViewController: VideoTrimmerViewDelegate {
  
  /// Make UI/processing updates here when the user has stopped moving the handles
  /// - Parameter playerTime: Video time when the user stopped moving either handle
  public func playheadStoppedMoving(_ playerTime: CMTime) {
    player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    player?.play()
    startPlaybackTimer()
  }
  
  /// Make UI/processing updates while the user is moving either handle
  /// - Parameter playerTime: Video time received continuously as the user is moving either handle
  public func didChangePlayhead(_ playerTime: CMTime) {
    stopPlaybackTimer()
    player?.pause()
    player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
    print(duration)
    
    if let startTime = trimmerView.startTime {
      startTimeLabel.text = "Start Time: \(Int(startTime.seconds))"
      startTimeLabel.sizeToFit()      
    }
    
    if let endTime = trimmerView.endTime {
      endTimeLabel.text = "End Time: \(Int(ceil(endTime.seconds)))"
      endTimeLabel.sizeToFit()
    }
  }
}
