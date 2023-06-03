//
//  OAuth2Services.swift
//  ImageFeed
//
//  Created by Anton Rusetsky on 26.05.2023.
//

import UIKit

final class OAuth2Services {
    static let sharedServices = OAuth2Services()
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    
    private let tokenStorage = OAuth2TokenStorage()
    private (set)  var authToken: String? {
        get {
            return tokenStorage.token
        }
        set {
            tokenStorage.token = newValue
        }
    }
    
    
    func fetchOAuthToken(_ code: String, completion: @escaping(Result<String, Error>) -> Void ) {
        assert(Thread.isMainThread)
        if lastCode == code {return}
        lastCode = code
        
        let request = authTokenRequest(code: code)
        let task = object(for: request) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {return}
                switch result {
                case .success(let body):
                    let authToken = body.accessToken
                    self.authToken = authToken
                    completion(.success(authToken))
                    self.task = nil
                case .failure(let error):
                    completion(.failure(error))
                    self.lastCode = nil
                }
            }
        }
        self.task = task
        task.resume()
    }
}

extension OAuth2Services {
    private func object(for request: URLRequest, completion: @escaping (Result<OAuthTokenResponseBody, Error>) -> Void) -> URLSessionTask {
        let decoder = JSONDecoder()
        return urlSession.data(for: request) { (result: Result<Data, Error>) in
            let response = result.flatMap {data -> Result<OAuthTokenResponseBody, Error> in
                Result { try decoder.decode(OAuthTokenResponseBody.self, from: data) }
            }
            completion(response)
        }
    }
    
    private func authTokenRequest(code: String) -> URLRequest {
        URLRequest.makeHTTPRequest(
            path: "/oauth/token"
            + "?client_id=\(accessKey)"
            + "&&client_secret=\(secretKey)"
            + "&&redirect_uri=\(redirectURI)"
            + "&&code=\(code)"
            + "&&grant_type=authorization_code",
            httpMethod: "POST"
        )
    }
    
    private struct OAuthTokenResponseBody: Decodable {
        let accessToken: String
        let tokenType: String
        let scope: String
        let createdAt: Int
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
            case scope
            case createdAt = "created_at"
        }
    }
    
}

extension URLRequest {
    static func makeHTTPRequest( path: String,
                                 httpMethod: String,
                                 baseURL: URL = URL(string: "https://unsplash.com")!) -> URLRequest {
        var request = URLRequest(url: URL(string: path, relativeTo: baseURL)!)
        request.httpMethod = httpMethod
        return request
    }
}

extension URLSession {
    func data(for request: URLRequest,
              completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionTask  {
        let fulfillCompletion: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        let task = dataTask(with: request, completionHandler: {data, response, error in
            if let data = data,
               let response = response,
               let statusCode = (response as? HTTPURLResponse)?.statusCode
            {
                if 200..<300 ~= statusCode {
                    fulfillCompletion(.success(data))
                } else {
                    fulfillCompletion(.failure(NetworkError.httpStatusCode(statusCode)))
                }
            } else if let error = error {
                fulfillCompletion(.failure(NetworkError.urlRequestError(error)))
            } else {
                fulfillCompletion(.failure(NetworkError.urlSessionError))
            }
        })
        task.resume()
        return task
    }
}
