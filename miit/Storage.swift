//
//  Storage.swift
//  miit
//
//  Created by Ken Sun on 2018/10/4.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation

class Storage {
    
    static let iCloud = Cloud()
}

class Cloud {
    
    static let pickDocumentTypes = ["public.json", "public.movie", "public.image", "com.adobe.pdf"]
    
    var containerUrl: URL? {
        return FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.tech.nabawan.miit")?.appendingPathComponent("Documents")
    }
    
    init() {
        if let url = containerUrl, !FileManager.default.fileExists(atPath: url.path, isDirectory: nil) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func save(data: Data, filename: String) -> Bool {
        guard let dirUrl = containerUrl else {
            Alert.showError(title: "Save Failed", message: "iCloud is not connected.")
            return false
        }
        do {
            try data.write(to: dirUrl.appendingPathComponent(filename), options: [.atomic])
            return true
        } catch {
            Alert.showError(title: "Save Failed", message: error.localizedDescription)
        }
        return false
    }
}
