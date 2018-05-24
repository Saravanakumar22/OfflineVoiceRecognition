//
//  ViewController.swift
//  OfflineVoiceRecognition
//
//  Created by Saravanakumar on 24/05/18.
//  Copyright © 2018 Saravanakumar. All rights reserved.
//

import UIKit
import AVFoundation
import Speech
import UserNotifications

class ViewController: UIViewController,SFSpeechRecognizerDelegate,AVSpeechSynthesizerDelegate,UNUserNotificationCenterDelegate,OEEventsObserverDelegate {
    
    @IBOutlet var contentText: UITextView!
    @IBOutlet var startButton:UIButton!
    @IBOutlet var startButtonWidth:NSLayoutConstraint!
    @IBOutlet var contentTextTop: NSLayoutConstraint!
    @IBOutlet var repeatButton : UIButton!
    @IBOutlet var imageView : UIImageView!
    @IBOutlet var topBarView : UIView!
    @IBOutlet var microphoneButton : UIButton!
    @IBOutlet var repeatButtonWidth : NSLayoutConstraint!
    @IBOutlet var microButtonWidth : NSLayoutConstraint!
    @IBOutlet var topBarHeight: NSLayoutConstraint!
    @IBOutlet var topBarTop: NSLayoutConstraint!
    @IBOutlet var contentTextHeight: NSLayoutConstraint!
    @IBOutlet var volumeButton : UIButton!
    @IBOutlet var volumeButtonWidth : NSLayoutConstraint!
    
    
    var lmPath : String!
    var lmDic : String!
    var openEarsEventObserver = OEEventsObserver()
    var okActionToEnable : UIAlertAction!
    var audioPlayer : AVAudioPlayer?
    var instructions = ["please ensure that all items donated","Call me Later , What are you doing right now?","May i help you","a rough copy of your paper that you continue to shape, edit and strengthen after it is written.","With your outline in sight, start writing the introduction of your rough draft","you have come up with in your prewriting exercise. Try reading the prewriting text out loud","Website is intended for students, ages middle school through returning adult, as well as their parents, teachers and support professionals"]
    var selectedIndex : Int = 0
    var isStopSpeaking : Bool = false
    var isStopListening : Bool = false
    var timeInMinutes : Int!
    
    let contentFont : CGFloat = UI_USER_INTERFACE_IDIOM() == .pad ? 32.0 : 22.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            topBarTop.constant = 20.0
            topBarHeight.constant = 60.0
            repeatButtonWidth.constant = 50.0
            microButtonWidth.constant = 50.0
            startButtonWidth.constant = 50.0
            volumeButtonWidth.constant = 50.0
        }else {
            topBarTop.constant = 0.0
            topBarHeight.constant = 50.0
            repeatButtonWidth.constant = 30.0
            volumeButtonWidth.constant = 30.0
            startButtonWidth.constant = 30.0
            microButtonWidth.constant = 30.0
        }
        
        contentText.font = UIFont.systemFont(ofSize: contentFont)
        
        setupContentText(instruction: "Press 'Play' to Start. Speak once Text Speech done (Supported Commands ie., Next, Previous, Repeat)")
        openEarsEventObserver.delegate = self
        setupButtons()
        setupOpenEars()
        
    }
    
    var speechSynthesizer : AVSpeechSynthesizer {
        
        if _speechSynthesizer != nil {
            return _speechSynthesizer!
        }
        
        _speechSynthesizer = AVSpeechSynthesizer()
        _speechSynthesizer!.delegate = self
        return _speechSynthesizer!
    }
    
    var _speechSynthesizer : AVSpeechSynthesizer?
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        let bottomLayer = CALayer()
        bottomLayer.backgroundColor = UIColor.black.cgColor
        bottomLayer.opacity = 0.5
        bottomLayer.frame = CGRect(x: 0, y: topBarView.frame.height-1, width: self.view.frame.width, height: 0.5)
        topBarView.layer.addSublayer(bottomLayer)
        
        AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
            
            if !granted {
                self.showAlertController(message: "If you want to change instruction by Voice comment like(next , previous and repeat). Go to setting Turn ON the Microphone.", title: "Microphone")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        stopListening()
        
        if _speechSynthesizer != nil {
            speechSynthesizer.stopSpeaking(at: .immediate)
            _speechSynthesizer = nil
        }
        
        _pocketsphinxController = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
    }
    
    func setupButtons() {
        
        startButton.setTitle(String.fontIconString(fromEnum: .FAPlay), for: .normal)
        startButton.titleLabel?.font = UIFont(name: "FontAwesome", size: buttonFont)
        
        repeatButton.setTitle(String.fontIconString(fromEnum: .FARepeat), for: .normal)
        repeatButton.titleLabel?.font = UIFont(name: "FontAwesome", size: buttonFont)
        
        volumeButton.setTitle(String.fontIconString(fromEnum: .FAVolumeUp), for: .normal)
        volumeButton.titleLabel?.font = UIFont(name: "FontAwesome", size: buttonFont)
        
        microphoneButton.setTitle(String.fontIconString(fromEnum: .FAMicrophone), for: .normal)
        microphoneButton.titleLabel?.font = UIFont(name: "FontAwesome", size: buttonFont)
    }
    
    func reloadData() {
        
        setupContentText(instruction: instructions[selectedIndex])
        startSpeech(instructionString: instructions[selectedIndex])
    }
    
    @objc func setupContentText(instruction : String) {
        
        let resetTop = self.view.frame.height - 100
        
        let descSize = instruction.sizeWithConstrainedWidth(self.view.frame.width-60, font: UIFont.systemFont(ofSize: contentFont)).height + 10
        
        contentTextHeight.constant = descSize
        contentText.text = instruction
        contentTextTop.constant = resetTop/2 - contentTextHeight.constant/2
        
        if contentTextHeight.constant > self.view.frame.height - 90 {
            contentTextHeight.constant = self.view.frame.height - 90
            contentTextTop.constant = 5.0
        }
        self.view.layoutIfNeeded()
    }
    
    //Play beep sound when Alert shown
    func playBeepSound() {
        
        let alertSound = URL(fileURLWithPath: Bundle.main.path(forResource: "beep-06", ofType: "wav")!)
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try! AVAudioSession.sharedInstance().setActive(true)
        
        do {
            try audioPlayer = AVAudioPlayer(contentsOf: alertSound)
            audioPlayer!.prepareToPlay()
            audioPlayer!.play()
        } catch let err {
            print("ERROR : \(err.localizedDescription)")
        }
    }
    
    func setupOpenEars() {
        
        let lmGenerator = OELanguageModelGenerator()
        lmGenerator.verboseLanguageModelGenerator = false
        
        let err : Error? = lmGenerator.generateLanguageModel(fromTextFile: Bundle.main.path(forResource: "word", ofType: "txt"), withFilesNamed: "openEars", forAcousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"))
        
        if err != nil {
            print("Error while creating initial language model: \(err!)")
        } else {
            lmPath = lmGenerator.pathToSuccessfullyGeneratedLanguageModel(withRequestedName: "openEars")
            lmDic = lmGenerator.pathToSuccessfullyGeneratedDictionary(withRequestedName: "openEars")
            
            do {
                try pocketsphinxController.setActive(true)
            }catch let error {
                print("Error: it wasn't possible to set the shared instance to active: \"\(error)\"")
            }
        }
    }
    
    var pocketsphinxController : OEPocketsphinxController {
        
        if _pocketsphinxController != nil {
            return _pocketsphinxController!
        }
        
        _pocketsphinxController = OEPocketsphinxController.sharedInstance()
        _pocketsphinxController?.verbosePocketSphinx = false
        _pocketsphinxController?.returnNbest = true
        
        return _pocketsphinxController!
    }
    
    var _pocketsphinxController : OEPocketsphinxController?
    
    func pocketsphinxDidReceiveHypothesis(_ hypothesis: String!, recognitionScore: String!, utteranceID: String!) {
        
        if ["next","previous","repeat"].contains(hypothesis) && Int(recognitionScore!)! > -150000  {
            filterSpeechString(speechString: hypothesis!)
        }
        
        print("OPENEARS : The received hypothesis is \(hypothesis!) recognitionScore: \(recognitionScore) utteranceID;\(utteranceID)")
        
    }
    
    func pocketsphinxDidStartListening() {
        print("OPENEARS : Starts Listening")
    }
    
    func pocketsphinxDidStopListening() {
        print("OPENEARS : Stops Listening")
    }
    
    func pocketSphinxContinuousTeardownDidFail(withReason reasonForFailure: String!) {
        
        print("OPENEARS : Tearing down the continuous recognition loop has failed for the reason \(reasonForFailure)")
        
    }
    
    func micPermissionCheckCompleted(withResult: Bool) {
        print("OPENEARS: mic check completed.")
        if(!pocketsphinxController.isListening) {
            pocketsphinxController.startListeningWithLanguageModel(atPath: lmPath, dictionaryAtPath: lmDic, acousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"), languageModelIsJSGF: false)
        }
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    //SpeechSynthesizer to read the Instructions.
    func startSpeech(instructionString : String) {
        
        if isStopSpeaking == false {
            
            let utterance = AVSpeechUtterance(string: instructionString)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            
            if (UIDevice.current.systemVersion as NSString).floatValue < 9.0 {
                utterance.rate = 0.09
            }
            else if ((UIDevice.current.systemVersion as NSString).floatValue < 10.0) {
                utterance.rate = 0.5
            }
            else if ((UIDevice.current.systemVersion as NSString).floatValue > 9.0) {
                utterance.rate = 0.4
            }
            else {
                utterance.rate = 0.4
            }
            speechSynthesizer.speak(utterance)
            changeAndEnableMicrophone(enable: false)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        changeAndEnableMicrophone(enable: true)
        startListening()
    }
    
    @objc func startListening() {
        
        if !pocketsphinxController.isListening && speechSynthesizer.isSpeaking == false {
            
            pocketsphinxController.startListeningWithLanguageModel(atPath: lmPath, dictionaryAtPath: lmDic, acousticModelAtPath: OEAcousticModel.path(toModel: "AcousticModelEnglish"), languageModelIsJSGF: false)
        }
    }
    
    func stopListening() {
        // To stop the speech recognition from listening.
        if pocketsphinxController.isListening {
            pocketsphinxController.stopListening()
        }
    }
    
    func filterSpeechString(speechString : String) {
        
        if speechString == "next" {
            nextPressed()
        }
        else if speechString == "previous" {
            previousPressed()
        }
        else if speechString == "repeat" {
            repeatClicked()
        }
    }
    
    func changeAndEnableMicrophone(enable : Bool) {
        
        if isStopSpeaking == false {
            microphoneButton.isEnabled = enable
            if enable {
                microphoneButton.setTitle(String.fontIconString(fromEnum: .FAMicrophone), for: .normal)
            } else {
                microphoneButton.setTitle(String.fontIconString(fromEnum: .FAMicrophoneSlash), for: .normal)
            }
        }
    }
    
    @IBAction func repeatClicked() {
        
        //To repeat the current Instruction which is showing on screen.
        stopListening()
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        startSpeech(instructionString: instructions[selectedIndex])
    }
    
    @IBAction func volumeTapped() {
        
        //To stop the speechSynthesizer
        if isStopSpeaking == false {
            
            if speechSynthesizer.isSpeaking == true {
                speechSynthesizer.stopSpeaking(at: .immediate)
            }
            
            volumeButton.setTitle(String.fontIconString(fromEnum: .FAVolumeOff), for: .normal)
            changeAndEnableMicrophone(enable: true)
            self.perform(#selector(startListening), with: nil, afterDelay: 0.3)
            isStopSpeaking = true
        } else {
            
            volumeButton.setTitle(String.fontIconString(fromEnum: .FAVolumeUp), for: .normal)
            isStopSpeaking = false
        }
    }
    
    @IBAction func microphoneTapped() {
        
        if isStopListening == false {
            
            stopListening()
            isStopListening = true
            microphoneButton.setTitle(String.fontIconString(fromEnum: .FAMicrophoneSlash), for: .normal)
        } else {
            startListening()
            isStopListening = false
            microphoneButton.setTitle(String.fontIconString(fromEnum: .FAMicrophone), for: .normal)
            
        }
    }
    
    @IBAction func startPressed(sender:UIButton) {
        
        if sender.tag == 1 {
            sender.tag = 2
            startButton.setTitle(String.fontIconString(fromEnum: .FAStop), for: .normal)
            reloadData()
        }
        else {
            sender.tag = 1
            startButton.setTitle(String.fontIconString(fromEnum: .FAPlay), for: .normal)
            setupContentText(instruction: "Press 'Play' to Start. Speak once Text Speech done (Supported Commands ie., Next, Previous, Repeat)")
            stopListening()
            if speechSynthesizer.isSpeaking {
                speechSynthesizer.stopSpeaking(at: .immediate)
            }
        }
    }
    
    func nextPressed() {
        //Move to next instruction.
        if selectedIndex < instructions.count - 1 {
            stopListening()
            selectedIndex += 1
            speechSynthesizer.stopSpeaking(at: .immediate)
            reloadData()
        }else {
            startSpeech(instructionString: "Your recipe has been finished")
        }
    }
    
    func previousPressed() {
        //Move to Previous instruction.
        if selectedIndex > 0 {
            
            stopListening()
            selectedIndex -= 1
            speechSynthesizer.stopSpeaking(at: .immediate)
            reloadData()
        }
        else {
            startSpeech(instructionString: "No more data available")
        }
    }
    
    func showAlertController(message : String , title : String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okButton = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okButton)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

