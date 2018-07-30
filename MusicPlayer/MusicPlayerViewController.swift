//
//  ViewController.swift
//  MusicPlayer
//
//  Created by Nikolay Sereda on 19.07.2018.
//  Copyright © 2018 Nikolay Sereda. All rights reserved.
//

import UIKit
import AVFoundation

class MusicPlayerViewController: UIViewController {
    
    //MARK: Properties
    private var player: AVAudioPlayer!
    private var timer: Timer!
    
    private let songs = ["Paper Thin.mp3", "Shine.mp3", "Let It In.mp3"]
    private var currentSongIndex = 1

    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var songImage: UIImageView!
    @IBOutlet weak var durationSlider: UISlider!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    
    //MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        takeSongByURL(atPosition: currentSongIndex)
    }
    
    //MARK: Actions
    @IBAction func playButtonTapped(_ sender: UIButton) {
        player.play()
   
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
    }
    
    @IBAction func pauseButtonTapped(_ sender: UIButton) {
        player.pause()
        timer.invalidate()
        updateUI()
    }
    
    @IBAction func prevButtonTapped(_ sender: UIButton) {
        currentSongIndex = (currentSongIndex == 0) ? songs.count - 1 : currentSongIndex - 1
        
        takeSongByURL(atPosition: currentSongIndex)
        player.play()
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        currentSongIndex = (currentSongIndex == songs.count - 1) ? 0 : currentSongIndex + 1
        
        takeSongByURL(atPosition: currentSongIndex)
        player.play()
    }
    
    @IBAction func durationSliderChanged(_ sender: UISlider) {
        player.currentTime = TimeInterval(sender.value)
    }
    
    //MARK: Private Methods
    @objc private func timerFired() {
        updateUI()
    }
    
    private func updateUI() {
        let currentTime = player.currentTime
    
        durationSlider.value = Float(currentTime)
        currentTimeLabel.text = leadToCorrectTimeFortat(time: Float(currentTime))
        
    }
    
    private func leadToCorrectTimeFortat(time: Float) -> String {
        let currentMinutes = Int(time / 60)
        let sec = time.truncatingRemainder(dividingBy: 60)
        let currentSec = String(format: "%.0f", sec)
        
        return "\(currentMinutes):\(currentSec)"
    }
    
    private func takeSongByURL(atPosition position: Int) {
        var song = songs[position].split(separator: ".")
        let songType = String(song.removeLast())
        let songName = song.joined(separator: ".")
   
        songNameLabel.text = songName
 
        let audioPath = Bundle.main.path(forResource: songName.replacingOccurrences(of: " ", with: ""), ofType: songType)
        
        do {
            try player = AVAudioPlayer(contentsOf: URL(string: audioPath!)!)
            player.delegate = self
            
            if songType == "mp3" {
                obtainMp3Metadata(withURL: audioPath!)
            }
   
            durationSlider.minimumValue = 0
            durationSlider.maximumValue = Float(player.duration)
            
            durationLabel.text = leadToCorrectTimeFortat(time: Float(player.duration))
        } catch {
            fatalError("Playing song error: \(error)")
        }

    }
    
    private func obtainMp3Metadata(withURL urlStr: String) {
        
        let url = URL(string: "file://\(urlStr)")
        
        let asset = AVURLAsset(url: url!)
        
        asset.loadValuesAsynchronously(forKeys: ["commonMetadata"]) {
            let artWork = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common)
            
            for item in artWork {
                if item.keySpace == AVMetadataKeySpace.id3 {
                    let data = item.value?.copy(with: nil) as! Data
                    DispatchQueue.main.async {
                        self.songImage.image = UIImage(data: data)
                    }
                }
            }
        }
    }
}

extension MusicPlayerViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        timer.invalidate()
        updateUI()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        timer.invalidate()
        updateUI()
    }
}
