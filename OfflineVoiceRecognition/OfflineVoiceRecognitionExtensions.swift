//
//  OfflineVoiceRecognitionExtensions.Swift
//  OfflineVoiceRecognition
//
//  Created by Saravanakumar on 04/08/17.
//  Copyright © 2017 Saravanakumar. All rights reserved.
//

import UIKit
import Foundation
import CoreData

let SegFontSize : CGFloat = UI_USER_INTERFACE_IDIOM() == .pad ? 27.0 : 19.0
let titleFontSize : CGFloat = UI_USER_INTERFACE_IDIOM() == .pad ? 25.0 : 19.0
let descFontSize : CGFloat = UI_USER_INTERFACE_IDIOM() == .pad ? 20.0 : 15.0
let appTitleFont : CGFloat = UI_USER_INTERFACE_IDIOM() == .pad ? 45.0 : 40.0
let recipeTitleFont : CGFloat = UI_USER_INTERFACE_IDIOM() == .pad ? 38.0 : 30.0
let buttonFont : CGFloat = UI_USER_INTERFACE_IDIOM() == .pad ? 32.0 : 28.0


extension String {
    
    enum FAIcon : Int {
        case FARefresh , FAHeart_O , FAHeart , FAClock_O , FAChevronLeft , FAUser , FAArrowRight , FAArrowLeft , FACutlery , FARepeat , FAMicrophoneSlash , FAMicrophone , FAClock , FALongArrowLeft , FALongArrowRight , FAEllipsis_v, FAVolumeUp , FAVolumeOff , FAPlay , FAStop
    }
    
    static func fontIconString(fromEnum value: FAIcon) -> String {
        return String.fontAwesomeUnicodeString()[value.rawValue] as! String
    }
    
    static func fontAwesomeUnicodeString() -> NSArray {
        let fontAwesomeUnicodeStrings: NSArray!
        
        fontAwesomeUnicodeStrings = ["\u{f021}","\u{f08a}","\u{f004}","\u{f017}" ,"\u{f053}" ,"\u{f007}","\u{f061}" ,"\u{f060}" ,"\u{f0f5}" ,"\u{f01e}" ,"\u{f131}" ,"\u{f130}" ,"\u{f017}" ,"\u{f177}" ,"\u{f178}" ,"\u{f142}" ,"\u{f028}" , "\u{f026}","\u{f04b}","\u{f28e}"]
        
        return fontAwesomeUnicodeStrings
    }
    
    func sizeWithConstrainedWidth(_ width: CGFloat, font: UIFont) -> CGSize
    {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        
        return CGSize(width: ceil(boundingBox.width), height: ceil(boundingBox.height))
    }
    
}
