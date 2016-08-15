//
//  ViewController.swift
//  TAAE2
//
//  Created by Mark Jeschke on 7/17/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//

import UIKit
import MessageUI

class ViewController: UIViewController, MFMailComposeViewControllerDelegate {
  
    var audioPlaying:Bool = false

    let timecodeFormatter = TimecodeFormatter()
    var timecodeTimer: NSTimer?
    var timecodeNumber = 0
    var timecodePlayDisplay: String?
    var timecodeRecordDisplay: String?

    var fileRecording: Bool = false

    // Timecode labels
    @IBOutlet weak var playbackTimecodeLabel: UILabel!
    @IBOutlet weak var recordedTimecodeLabel: UILabel!
    
    // UIButtons
    @IBOutlet weak var playStopBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var exportBtn: UIButton!
    
    // UIButton colors for play, record, and disabled.
    let lightGreenColor = UIColor(red: 0/255.0, green: 180/255.0, blue: 0/255.0, alpha: 1.0)
    let lightRedColor = UIColor(red: 255/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1.0)
    let grayColor = UIColor(red: 100/255.0, green: 100/255.0, blue: 100/255.0, alpha: 1.0)
    
    // MARK: === AEAudioController Class ===
    
    // Create a reference to the AEAudioController engine class.
    var audio: AEAudioController {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.audio!
    }
    
    // MARK: === View Life-Cycle ===
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(alertNotification), name: "alertController", object: nil)
        
        // Check whether an audio file has been recorded for export.
        self.detectExistingAudioFile()
        
        // Initialize colors and timecode displays.
        self.recordBtn.tintColor = lightRedColor
        self.timecodePlayDisplay = timecodeFormatter.convertSecondsToTimecode(0)
        self.timecodeRecordDisplay = timecodeFormatter.convertSecondsToTimecode(0)
    }
    
    // Deinitialize notification observer.
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: === Start/Stop Recording Action ===

    @IBAction func recordAction(sender: UIButton) {
        if audio.recording {
            // Stop recording
            audio.stopRecordingAtTime(0, completionBlock: {
                self.fileRecording = false
                self.detectExistingAudioFile()
                self.playBtn.enabled = true
                self.playBtn.tintColor = self.lightGreenColor
                self.recordedTimecodeLabel.text = self.timecodeRecordDisplay
                self.recordBtn.setTitle("◉ Record", forState: .Normal)
                self.recordBtn.selected = false
                self.removeTimecodeTimer()
            })
        } else {
            do {
                // Start recording
                self.fileRecording = true
                try audio.beginRecordingAtTime(0)
                self.timecodeNumber = 0
                self.recordBtn.tintColor = self.lightRedColor
                self.recordBtn.setTitle("◼︎ Stop", forState: .Normal)
                self.playBtn.enabled = false
                self.recordedTimecodeLabel.text = self.timecodeFormatter.convertSecondsToTimecode(0)
                self.recordBtn.selected = true
                self.playBtn.setTitle("▶︎ Play", forState: .Normal)
                startTimecodeTimer()
            } catch _ {
                NSNotificationCenter.defaultCenter().postNotificationName("alertController", object: self, userInfo:["error":"Oops! Something went wrong. We unfortunately can't record."])
            }
        }
    }
    
    // MARK: === Start/Stop Playback (of Recording) Action ===

    @IBAction func playAction(sender: UIButton) {
        if audio.playingRecording {
            // Stop the playback
            audio.stopPlayingRecording()
            self.playBtn.setTitle("▶︎ Play", forState: .Normal)
            self.playBtn.selected = false
            removeTimecodeTimer()
        } else {
            // Start playback
            startTimecodeTimer()
            self.playBtn.selected = true
            self.playBtn.tintColor = lightGreenColor
            self.playBtn.setTitle("◼︎ Stop", forState: .Normal)
            audio.playRecordingWithCompletionBlock({
                self.playbackTimecodeLabel.text = self.timecodeFormatter.convertSecondsToTimecode(0)
                self.playBtn.setTitle("▶︎ Play", forState: .Normal)
                self.playBtn.selected = false
                self.removeTimecodeTimer()
            })
        }
    }
    
    // MARK: === Play/Stop Audio File ===
    
    @IBAction func playStopAction(sender: UIButton) {
        // Play the audio files from the AEAudioController
        audio.playMelody()
        audio.playBeatOne()
        audio.playBeatTwo()
        audio.playBassline()
        // Button play/stop states
        if !audioPlaying {
            playStopBtn.setTitle("◼︎ Stop Audio", forState: .Normal)
            playStopBtn.selected = true
            audioPlaying = true
        } else {
            playStopBtn.setTitle("▶︎ Play Audio", forState: .Normal)
            playStopBtn.selected = false
            audioPlaying = false
        }
    }
    
    // MARK: === Start/Stop Recoding Action ===
    
    @IBAction func recordTap() {
        if audio.recording {
            // Stop recording
            audio.stopRecordingAtTime(0, completionBlock: {
                self.fileRecording = false
                self.detectExistingAudioFile()
                self.playBtn.enabled = true
                self.playBtn.tintColor = self.lightGreenColor
                self.recordedTimecodeLabel.text = self.timecodeRecordDisplay
                self.recordBtn.setTitle("◉ Record", forState: .Normal)
                self.recordBtn.selected = false
                self.removeTimecodeTimer()
            })
        } else {
            do {
                // Start recording
                self.fileRecording = true
                try audio.beginRecordingAtTime(0)
                self.timecodeNumber = 0
                self.recordBtn.tintColor = self.lightRedColor
                self.recordBtn.setTitle("◼︎ Stop", forState: .Normal)
                self.playBtn.enabled = false
                self.recordedTimecodeLabel.text = self.timecodeFormatter.convertSecondsToTimecode(0)
                self.recordBtn.selected = true
                self.playBtn.setTitle("▶︎ Play", forState: .Normal)
                startTimecodeTimer()
            } catch _ {
                // D'oh, something went wrong. Guess we can't record.
            }
        }
    }
    
    // MARK: === Start/Stop Playback (of Recording) Action ===
    
    @IBAction func playTap() {
        if audio.playingRecording {
            // Stop the playback
            audio.stopPlayingRecording()
            self.playBtn.setTitle("▶︎ Play", forState: .Normal)
            self.playBtn.selected = false
            removeTimecodeTimer()
        } else {
            // Start playback
            startTimecodeTimer()
            self.playBtn.selected = true
            self.playBtn.tintColor = lightGreenColor
            self.playBtn.setTitle("◼︎ Stop", forState: .Normal)
            audio.playRecordingWithCompletionBlock({
                self.playbackTimecodeLabel.text = self.timecodeFormatter.convertSecondsToTimecode(0)
                self.playBtn.setTitle("▶︎ Play", forState: .Normal)
                self.playBtn.selected = false
                self.removeTimecodeTimer()
            })
        }
    }
    
    // MARK: === Export Audio Action ===
    
    @IBAction func exportAction(sender: UIButton) {
        exportAudioFile()
    }
    
    // MARK: === Export Alert Controller Options ===

    func exportAudioFile() {
        let alertController = UIAlertController(title: "Export Audio", message: "\(self.audio.fullRecordingName)", preferredStyle: .Alert)
        // AudioShare
        let audioShareAction = UIAlertAction(title: "AudioShare", style: .Default) { (action) in
            self.audio.exportToAudioShare() // Method is in 'AEAudioController.m'
        }
        // Email
        let emailAction = UIAlertAction(title: "Email", style: .Default) { (action) in
            self.exportToEmail()
        }
        // Share
        let shareAction = UIAlertAction(title: "More options", style: .Default) { (action) in
            self.exportTap()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action) in
        }

        alertController.addAction(audioShareAction)
        alertController.addAction(emailAction)
        alertController.addAction(shareAction)
        alertController.addAction(cancelAction)

        self.presentViewController(alertController, animated: true) {
        }
    }
    
    // MARK: === Detect Existing Audio File to Enable Export UI Button ===
    
    // Enable/disable recording-based actions, depending on whether a recording exists
    private func detectExistingAudioFile() {
        let fileManager = NSFileManager.defaultManager()
        exportBtn.enabled = fileManager.fileExistsAtPath(audio.recordingPath.path!)
        playBtn.enabled = exportBtn.enabled;
        if playBtn.enabled {
            playBtn.tintColor = lightGreenColor
        } else {
            self.playBtn.tintColor = grayColor
            self.playBtn.enabled = false
        }
    }
    
    // MARK: === Compose Email Controller ===
    
    func exportToEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            
            var emailSubject: String?
            //var emailRecipients: String?
            var emailMessageBody: String?
            
            emailSubject = "\(self.audio.recordingName)"
            emailMessageBody = "<p>Check out my latest recording made with <a href=\'http://theamazingaudioengine.com/'>The Amazing Audio Engine 2!</a>"
            
            mail.setSubject(emailSubject!)
            mail.setMessageBody(emailMessageBody!, isHTML: true)
            
            let filePath = self.audio.recordingPath.path;
            if let fileData = NSData(contentsOfFile: filePath!) {
                mail.addAttachmentData(fileData, mimeType: "audio/m4a", fileName: "\(self.audio.fullRecordingName)")

            }
            presentViewController(mail, animated: true, completion: nil)
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName("alertController", object: self, userInfo:["error":"Failed to send email."])
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: === Share Activity Controller (More Options) ===
    
    func exportTap() {
        // Show the share controller
        let controller = UIActivityViewController(activityItems: [audio.recordingPath], applicationActivities: nil)
        // Set the audio file's subject when sharing via email.
        controller.setValue("\(self.audio.recordingName)", forKey: "subject")
        controller.completionWithItemsHandler = { activity, success, items, error in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
            controller.popoverPresentationController?.sourceView = self.exportBtn
            controller.modalPresentationStyle = UIModalPresentationStyle.Popover
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }

    // MARK: === Timecode Timers ===
    
    func startTimecodeTimer() {
        if timecodeTimer == nil {
          timecodeTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self,
                                                                 selector: #selector(onTick),
                                                                 userInfo: nil, repeats: true)
        }
    }
    
    // Trigger this function with each second tick
    func onTick() {
        if self.fileRecording {
            timecodeNumber += 1
            self.timecodeRecordDisplay = timecodeFormatter.convertSecondsToTimecode(timecodeNumber)
            self.recordedTimecodeLabel.text = self.timecodeRecordDisplay
        } else {
            self.timecodePlayDisplay = timecodeFormatter.convertSecondsToTimecode(0)
            if audio.playback.currentTime <= audio.playback.duration {
                self.timecodePlayDisplay = timecodeFormatter.convertSecondsToTimecode(Int(audio.playback.currentTime)+1)
                self.playbackTimecodeLabel.text = self.timecodePlayDisplay
            }
        }
    }
    
    func removeTimecodeTimer() {
        self.timecodeTimer!.invalidate()
        self.timecodeTimer = nil
    }
    
    // MARK: === Alert Error Notification Controller ===
    
    func alertNotification(notification: NSNotification) {
        let errorMessage:String = (notification.userInfo!["error"] as? String)!
        let alertController = UIAlertController(title: nil, message: errorMessage, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (result : UIAlertAction) -> Void in
        }
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }

}
