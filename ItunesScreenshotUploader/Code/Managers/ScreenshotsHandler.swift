//
//  ScreenshotsHandler.swift
//  ItunesScreenshotUploader
//
//  Created by iN on 20/01/16.
//  Copyright © 2016 2tickets2dublin. All rights reserved.
//

import Foundation
import Cocoa

class ScreenshotsHandler {
    
    private let fileManager = NSFileManager.defaultManager()
    
    func splitScreenShotByLangs(rawScreenShots:[ScreenShot], useLangs:Bool) -> [String:[ScreenShot]] {

        var langToScreens = [String:[ScreenShot]]()
        
        for screen in rawScreenShots {
            
            let lang = screen.screenShotLang(useLangs)
            
            var langArray:[ScreenShot]? = langToScreens[lang]
            if langArray == nil {
                langArray = [ScreenShot]()
            }
            
            langArray!.append(screen)
            langToScreens[lang] = langArray
            
        }
        
        return langToScreens
    }
    
    //Lang -> Platform -> Screenshot
    func convertRawScreenShotsToDataSet(rawScreenShots:[ScreenShot], useLangs:Bool) -> [String:[[ScreenShot]]] {
        
        let langToScreens = splitScreenShotByLangs(rawScreenShots, useLangs: useLangs)
        let langScreenShots:[[ScreenShot]] = Array(langToScreens.values)
        
        var final = [String:[[ScreenShot]]]()
        
        for langScreenShot in langScreenShots {
            
            var langPlatforms = [ScreenShotType:[ScreenShot]]()
            
            for screen in langScreenShot {
                
                var platformArray:[ScreenShot]? = langPlatforms[screen.screenType]
                if platformArray == nil {
                    platformArray = [ScreenShot]()
                }
                platformArray!.append(screen)
                langPlatforms[screen.screenType] = platformArray
            }
            
            var platforms = Array(langPlatforms.values)
            platforms = platforms.sort({ (sc1, sc2) -> Bool in
                let screen1 = sc1[0]
                let screen2 = sc2[0]
                
                return screen1.screenType.rawValue < screen2.screenType.rawValue
            })
            
            if useLangs {
                final[langScreenShot[0].langId] = platforms
            } else {
                final[NoLangID] = platforms
            }
        }
        
        return final
    }
    
    func getAllScreenshotsFromDirectory(pathDir:String) -> [ScreenShot] {
        
        var screens = [ScreenShot]()
        let filelist = try? fileManager.contentsOfDirectoryAtPath(pathDir)
        
        if filelist != nil {
            for filename in filelist! {
                if filename == ".DS_Store" {
                    continue
                }
                
                let fullPath = "\(pathDir)/\(filename)"
                
                let (s, isDir) = screenShotForPath(fullPath, name: filename)
                if isDir {
                    screens += getAllScreenshotsFromDirectory(fullPath)
                } else if let screen = s {
                    screens.append(screen)
                }
            }
            
        } else {
            let fullPath = pathDir
            let components = pathDir.componentsSeparatedByString("/")
            if let filename = components.last {
                let (s, isDir) = screenShotForPath(fullPath, name: filename)
                
                if isDir {
                    screens += getAllScreenshotsFromDirectory(fullPath)
                } else if let screen = s {
                    screens.append(screen)
                }
            }
            
        }
        
        return screens
    }
    
    func screenShotForPath(path:String, name:String) -> (screenshot:ScreenShot?, isDirectory:Bool) {
        
        let attributes = try? fileManager.attributesOfItemAtPath(path)
        
        if let a = attributes {
            let type = a["NSFileType"] as! String
            if type == NSFileTypeDirectory {
                return (nil, true)
            } else {
                if let i = imageForPath(path) {
                    let s = ScreenShot()
                    s.path = path
                    s.image = i
                    s.fileSize = a["NSFileSize"] as! Int
                    s.name = name
                    return (s, false)
                }
            }
        }
        
        return (nil, false)
    }
    
    
    func imageForPath(path:String) -> NSImage? {
        let image = NSImage(contentsOfFile: path)
        return image
    }
    
    
    //MARK: - File management helper -
    
    func copyScreenShotsImagesToITMSP(allImagesPlatf:[[[ScreenShot]]]) {
        
        for allImages in allImagesPlatf {
            for img in allImages {
                for i in img {
                    if i.screenType != .iUndefinedScreenShotType {
                        let path = pathForImageOfScreenShot(i)
                        copyScreenShot(i, toPath: path)
                        i.md5 = md5(path) //made it here if for some reason md5 would be changed after copying
                    }
                }
            }
        }
    }
    
    private func copyScreenShot(screenShot:ScreenShot, toPath path:String) {
        do {
            try
                fileManager.copyItemAtPath(screenShot.path, toPath: path)
        } catch {
            assert(false)
        }
    }
    
    func pathForImageOfScreenShot(screenShot:ScreenShot) -> String {
        return "\(ItunesConnectHandler.sharedInstance.itmspPath())/\(screenShot.nameForUpload)"
    }
}


