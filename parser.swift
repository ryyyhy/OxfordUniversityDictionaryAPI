//
//
//  Created by 新井崚平 on 2017/06/10.
//  Copyright © 2017年 新井崚平. All rights reserved.
//
import Foundation
import Alamofire
import SwiftyJSON


private struct OxfordDictionaryKey {
    static let baseURL = "https://od-api.oxforddictionaries.com/api/v1/entries/"
    static let appId = ""
    static let appKey = ""
}

class DictionaryAPI {

    class func produceRequest(lang: String, searchWord: String) -> URLRequest? {
        if let url = URL(string: OxfordDictionaryKey.baseURL + "\(lang)/\(searchWord)") {
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue(OxfordDictionaryKey.appId, forHTTPHeaderField: "app_id")
            request.addValue(OxfordDictionaryKey.appKey, forHTTPHeaderField: "app_key")
            return request
        }
        return nil
    }

    class func searchDefinition(searchWord: String, language: String, completionHandler: @escaping ((String, [String], [String], Bool) -> Void)) {
        var _id = ""
        var exampleArray = [String]()
        var defArray = [String]()
        _ = searchWord.lowercased()
        
        guard let request = DictionaryAPI.produceRequest(lang: language, searchWord: searchWord) else {
            completionHandler("", [""],[""], false)
            return
        }
        let session = URLSession.shared
        _ = session.dataTask(with: request, completionHandler: {
            data, response, error in
            if let _ = response, let responseData = data{
                
                let jsonParse = JSON(data: responseData)
                print(jsonParse)
                
                let results = jsonParse["results"].array
                results?.forEach({ (json) in
                    let lexicalEntries = json["lexicalEntries"].array
                    lexicalEntries?.forEach({ (lex) in
                        let entries = lex["entries"].array
                        entries?.forEach({ (senses) in
                            let examples = senses["senses"].array
                            examples?.forEach({ (jsondata) in
                               
                                let subsense = jsondata["subsenses"].array
                                subsense?.forEach({ (myjson) in
                                    let examp = myjson["examples"].array
                                    examp?.forEach({ (sometext) in
                                        guard let text = sometext["text"].string else {return}
                                        exampleArray.append(text)
                                    })
                                    
                                    let meaning = myjson["definitions"].array
                                    
                                    print(meaning)
                                    
                                    if meaning != nil {
                                        if (meaning?.count)! > 0 {
                                            if let string = meaning?.first?.rawString() {
                                                print("first object", string)
                                                defArray.append(string)
                                            }
                                        }
                                    } else {
                                        print("Error")
                                        completionHandler("", [""], [""], false)
                                        return
                                    }
                                })
                                
                                guard let example = jsondata["examples"].array else {return}
                                example.forEach({ (text) in
                                    guard let myText = text["text"].string else {return}
                                    exampleArray.append(myText)
                                })
                                let jd = jsondata["definitions"].array
                                
                                if jd != nil {
                                    if (jd?.count)! > 0 {
                                        if let string = jd?.first?.rawString() {
                                            print("first object", string)
                                            defArray.append(string)
                                        }
                                    }
                                } else {
                                    completionHandler("", [""], [""], false)
                                    return
                                    
                                }
                            
                            })
                        })
                    })
                })
                
                print(exampleArray)
                print(defArray)
                
                completionHandler(searchWord, defArray, exampleArray, true)
                
            } else {
                print("error")
                completionHandler("", [""], [""], false)
//                print(NSString.init(data: data!, encoding: String.Encoding.utf8.rawValue)!)
            }
        }).resume()
    }
