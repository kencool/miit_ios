//
//  Api.swift
//  miit
//
//  Created by Ken Sun on 2018/9/11.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class Api {
    static let baseUrl = "https://miit.tw/miitings/"
    
    // MARK: open room
    
    static func openRoom(roomID: String, token: String, _ closure: @escaping (_ isInitiator: Bool?, _ error: Error?) -> Void) {
        let params: Parameters = [
            roomID: ["token": token]
        ]
        Alamofire.request(baseUrl, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil).validate().responseJSON { response in
            switch response.result {
            case .success:
                closure(response.response?.statusCode == 201, nil)
            case .failure(let error):
                printError(data: response.data, err: error)
                closure(nil, error)
            }
        }
    }
    
    // MARK: send offer
    
    static func sendOffer(roomID: String, token: String, name: String, offerSdp: String, _ closure: @escaping (_ error: Error?) -> Void) {
        let query = ["token": token]
        let body: JSON = ["offer": [
            "name": name,
            "description": offerSdp]
        ]
        var urlCompoments = URLComponents(string: baseUrl + roomID)!
        urlCompoments.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: urlCompoments.url!)
        request.httpMethod = "POST"
        request.httpBody = try? body.rawData()
        request.allHTTPHeaderFields = [ "Content-Type": "application/json" ]
        
        Alamofire.request(request).validate().responseJSON { response in
            switch response.result {
            case .success:
                closure(nil)
            case .failure(let error):
                printError(data: response.data, err: error)
                closure(error)
            }
        }
    }
    
    // MARK: request answer
    
    static func requestAnswer(roomID: String, token: String, _ closure: @escaping (_ name: String?, _ sdp: String?, _ error: Error?) -> Void) {
        let query = ["token": token]
        var urlCompoments = URLComponents(string: baseUrl + roomID + "/answer")!
        urlCompoments.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: urlCompoments.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = TimeInterval(Int.max)
        request.allHTTPHeaderFields = [ "Content-Type": "application/json" ]
        
        Alamofire.request(request).validate().responseJSON { response in
            switch response.result{
            case .success(let value):
                let json = JSON(value)
                closure(json["name"].stringValue, json["description"].stringValue, nil)
            case .failure(let error):
                printError(data: response.data, err: error)
                closure(nil, nil, error)
            }
        }
    }
    
    // MARK: request offer
    
    static func requestOffer(roomID: String, token: String, _ closure: @escaping (_ name: String?, _ sdp: String?, _ error: Error?) -> Void) {
        let query = ["token": token]
        var urlCompoments = URLComponents(string: baseUrl + roomID + "/offer")!
        urlCompoments.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: urlCompoments.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = TimeInterval(Int.max)
        request.allHTTPHeaderFields = [ "Content-Type": "application/json" ]
        
        Alamofire.request(request).validate().responseJSON { response in
            switch response.result{
            case .success(let value):
                let json = JSON(value)
                closure(json["name"].stringValue, json["description"].stringValue, nil)
            case .failure(let error):
                printError(data: response.data, err: error)
                closure(nil, nil, error)
            }
        }
    }
    
    // MARK: send answer
    
    static func sendAnswer(roomID: String, token: String, name: String, answerSdp: String, _ closure: @escaping (_ error: Error?) -> Void) {
        let query = ["token": token]
        let body: JSON = ["answer": [
            "name": name,
            "description": answerSdp]
        ]
        var urlCompoments = URLComponents(string: baseUrl + roomID)!
        urlCompoments.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: urlCompoments.url!)
        request.httpMethod = "POST"
        request.httpBody = try? body.rawData()
        request.allHTTPHeaderFields = [ "Content-Type": "application/json" ]
        
        Alamofire.request(request).validate().responseJSON { response in
            switch response.result {
            case .success:
                closure(nil)
            case .failure(let error):
                printError(data: response.data, err: error)
                closure(error)
            }
        }
    }
    
    // MARK: send ice candidates
    
    static func sendIceCandidates(roomID: String, token: String, type: RTCSdpType, candidates: [RTCIceCandidate], _ closure: @escaping (_ error: Error?) -> Void) {
        let query = ["token": token]
        let body: JSON = [
            "ice_candidates": candidates.map { $0.dictionary }
        ]
        var urlCompoments = URLComponents(string: baseUrl + roomID + (type == .offer ? "/offer" : "/answer"))!
        urlCompoments.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: urlCompoments.url!)
        request.httpMethod = "POST"
        request.httpBody = try? body.rawData()
        request.allHTTPHeaderFields = [ "Content-Type": "application/json" ]
        
        Alamofire.request(request).validate().responseJSON { response in
            switch response.result{
            case .success:
                closure(nil)
            case .failure(let error):
                printError(data: response.data, err: error)
                closure(error)
            }
        }
    }
    
    // MARK: request ice candidates
    
    static func requestIceCandidates(roomID: String, token: String, type: RTCSdpType, _ closure: @escaping (_ candidates: [RTCIceCandidate]?, _ error: Error?) -> Void) {
        let query = ["token": token]
        var urlCompoments = URLComponents(string: baseUrl + roomID + (type == .offer ? "/offer" : "/answer") + "/ice_candidates")!
        urlCompoments.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        var request = URLRequest(url: urlCompoments.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = TimeInterval(Int.max)
        request.allHTTPHeaderFields = [ "Content-Type": "application/json" ]
        
        Alamofire.request(request).validate().responseJSON { response in
            switch response.result{
            case .success(let value):
                let candidates = JSON(value).arrayValue.map { RTCIceCandidate(json: $0) }
                closure(candidates, nil)
            case .failure(let error):
                printError(data: response.data, err: error)
                closure(nil, error)
            }
        }
    }
    
    
    // MARK: keep alive
    
    static func keepAlive(roomID: String, token: String, _ closure: @escaping (_ error: Error?) -> Void) {
        let params: Parameters = [
            "token": token
        ]
        Alamofire.request(baseUrl + roomID, method: .patch, parameters: params, encoding: URLEncoding.queryString, headers: nil).validate().responseJSON { response in
            switch response.result {
            case .success:
                closure(nil)
            case .failure(let error):
                printError(data: response.data, err: error)
                closure(error)
            }
        }
    }
    
    // MARK: close room
    
    static func closeRoom(roomID: String, token: String, _ closure: ((_ error: Error?) -> Void)?) {
        let params: Parameters = [
            "token": token
        ]
        Alamofire.request(baseUrl + roomID, method: .delete, parameters: params, encoding: URLEncoding.queryString, headers: nil).validate().responseJSON { response in
            switch response.result {
            case .success:
                closure?(nil)
            case .failure(let error):
                printError(data: response.data, err: error)
                closure?(error)
            }
        }
    }
}

// MARK: - Error Handler

extension Api {
    
    static func printError(data:Data?, err:Error?) {
        if let d = data {
            let responseData = String(data: d, encoding: String.Encoding.utf8)
            print(responseData ?? "responseData is nil")
        }
        if let e = err {
            print("error:\(e)")
        }
    }
    
    static func getStatusCode(error: Error) -> Int {
        guard let err = error as? AFError else {
            return -1
        }
        switch err {
        case .responseValidationFailed(reason: let reason):
            switch reason {
            case .unacceptableStatusCode(let code):
                return code
            default:
                break
            }
        default:
            break
        }
        return -1
    }
}

extension RTCIceCandidate {
    
    var dictionary: [String: AnyHashable] {
        get {
            return [
                "candidate": sdp,
                "sdpMLineIndex": sdpMLineIndex,
                "sdpMid": sdpMid ?? ""
            ]
        }
    }
    
    convenience init(json: JSON) {
        self.init(sdp: json["candidate"].stringValue, sdpMLineIndex: json["sdpMLineIndex"].int32Value, sdpMid: json["sdpMid"].string)
    }
}
