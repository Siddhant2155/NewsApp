//
//  NetworkManager.swift
//  WeatherApp
//
//  Created by Siddhant Kumar on 14/07/21.
//

import Foundation
import Alamofire
import ConfigurationModule


class NetworkManager {
    
    private init() { }
    static let sharedInstance = NetworkManager()
    
    func fetchData(endPoint: APIEndPoint,
                   params: [String: Any],
                   method: APIMethodsType,
                   completion: @escaping ((Result<AnyObject, NewsAPIError>) -> Void)) {
        
        let fullyQualifiedURL = NewsAppConfigurator.BASE_URL.rawValue + endPoint.rawValue
        
        var finalParam = [String: Any]()
        finalParam = params
        finalParam["apiKey"] = NewsAppConfigurator.APIKey.rawValue
        
        debugPrint(fullyQualifiedURL)
        debugPrint(finalParam)
        
        AF.request(fullyQualifiedURL,
                   method: APIMethod(method),
                   parameters: finalParam)
            .validate()
            .responseJSON { [self] response in
                switch getStatusCode(code: response.response?.statusCode) {
                case .success(_) :
                    switch response.result {
                    case .success(let responseData):
                        if let jsonDict = responseData as? [String: Any],
                           let statusKey = jsonDict["status"] as? String,
                           statusKey == "error",
                           let errorCode = jsonDict["code"] as? String {
                            completion(.failure(APIErrorCode(key: errorCode).getError))
                            return
                        }
                        completion(.success(responseData as AnyObject))
                    case .failure(let error):
                        debugPrint(error)
                        break
                    //FIXME: need to handle network error
                    }
                    
                case .failure(let error):
                    if error.showErrorMessage.isEmpty {
                        //FIXME: need to handle network error
                    }
                    completion(.failure(error))
                    return
                }
                
            }
    }
    
}

//MARK:- Enum Lists
extension NetworkManager {
    enum APIMethodsType {
        case GET,
             PUT,
             POST,
             DELETE
    }
    
    enum ResponseStatusCode: Int {
        
        init(_ code: Int) {
            switch code {
            case 200:
                self = .OK
            case 400:
                self = .BadRequest
            case 401:
                self = .Unauthorized
            case 429:
                self = .TooManyRequests
            case 500:
                self = .ServerError
            default:
                self = .OK
            }
        }
        
        case OK = 200
        case BadRequest = 400
        case Unauthorized = 401
        case TooManyRequests = 429
        case ServerError = 500
    }
}

//MARK:- UTILs Methods
extension NetworkManager {
    private func APIMethod(_ mtd:APIMethodsType) -> HTTPMethod {
        switch mtd {
        case .GET:
            return .get
        case .POST:
            return .post
        case .DELETE:
            return .delete
        case .PUT:
            return .put
        }
    }
    
    
    private func getStatusCode(code: Int?) -> Result<ResponseStatusCode, NewsAPIError> {
        guard let code = code else {
            return .failure(NewsAPIError.unknownError)
        }
        let respCode = ResponseStatusCode(code)
        if respCode == .OK {
            return .success(.OK)
        }
        if let error = APIStatusCode(rsc: respCode) {
            return .failure(error.getError)
        }
        return .failure(NewsAPIError.unknownError)
    }
}