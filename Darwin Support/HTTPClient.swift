//
//  HTTPClient.swift
//  SwiftFoundation
//
//  Created by Alsey Coleman Miller on 9/02/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation

// Dot notation syntax for class
public extension HTTP {
    
    /// Loads HTTP requests
    public struct Client: URLClient {
        
        public init(session: NSURLSession = NSURLSession.sharedSession()) {
            
            self.session = session
        }
        
        /// The backing ```NSURLSession```.
        public let session: NSURLSession
        
        public func sendRequest(request: HTTP.Request) throws -> HTTP.Response {
            
            var dataTask: NSURLSessionDataTask?
            
            return try sendRequest(request, dataTask: &dataTask)
        }
        
        public func sendRequest(request: HTTP.Request, inout dataTask: NSURLSessionDataTask?) throws -> HTTP.Response {
            
            // build request... 
            
            guard request.version == HTTP.Version(1, 1) else { throw Error.BadRequest }
            
            guard let url = NSURL(string: request.URL) else { throw Error.BadRequest }
            
            let urlRequest = NSMutableURLRequest(URL: url)
            
            urlRequest.timeoutInterval = request.timeoutInterval
            
            if let data = request.body {
                
                urlRequest.HTTPBody = NSData(bytes: data)
            }
            
            for (headerName, headerValue) in request.headers {
                
                urlRequest.addValue(headerValue, forHTTPHeaderField: headerName)
            }
            
            urlRequest.HTTPMethod = request.method.rawValue
            
            // execute request
            
            let semaphore = dispatch_semaphore_create(0);
            
            var error: NSError?
            
            var responseData: NSData?
            
            var urlResponse: NSHTTPURLResponse?
            
            dataTask = self.session.dataTaskWithRequest(urlRequest) { (data: NSData?, response: NSURLResponse?, responseError: NSError?) -> Void in
                
                responseData = data
                
                urlResponse = response as? NSHTTPURLResponse
                
                error = responseError
                
                dispatch_semaphore_signal(semaphore);
            }
            
            dataTask!.resume()
            
            // wait for task to finish
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            
            guard urlResponse != nil else { throw error! }
            
            var response = HTTP.Response()
            
            response.statusCode = urlResponse!.statusCode
            
            if let data = responseData where data.length > 0 {
                
                response.body = data.arrayOfBytes()
            }
            
            for (header, headerValue) in urlResponse!.allHeaderFields as! [String: String] {
                
                response.headers[header] = headerValue
            }
            
            return response
        }
    }
}


public extension HTTP.Client {
    
    public enum Error: ErrorType {
        
        /// The provided request was malformed.
        case BadRequest
    }
}
