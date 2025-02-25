import UIKit

class APIService {
    
    static let shared = APIService()
    
    func fetchDiskData(oAuthToken: String, completion: @escaping (Result<ProfileModel, Error>) -> Void) {
        guard let url = URL(string: APIEndpoint.baseURL.url) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("OAuth \(oAuthToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 500, userInfo: nil)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let ProfileModel = try decoder.decode(ProfileModel.self, from: data)
                completion(.success(ProfileModel))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func fetchPublicFiles(oAuthToken: String, baseURL: String = APIEndpoint.baseURL.url, limit: Int , offset: Int, type: String, previewSize: String = "S", previewCrop: String = "true",
                          completion: @escaping (Result<[PublishedFile], Error>) -> Void) {

        guard var urlComponents = URLComponents(string: baseURL) else {
            completion(.failure(NSError(domain: "ApiError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let allMediaTypes = "document,image,spreadsheet"
        
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "media_type", value: allMediaTypes),
            URLQueryItem(name: "type", value: type)
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "APIError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL Components"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("OAuth \(oAuthToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "APIError", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response:\n\(jsonString)")
            } else {
                print("Error: Unable to convert data to string.")
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let response = try decoder.decode(PublishedFilesResponse.self, from: data)
                print("Decoded response: \(response)")
                completion(.success(response.items))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    
    func fetchFiles(oAuthToken: String, baseURL: String, limit: Int, offset: Int, completion: @escaping (Result<[PublishedFile], Error>) -> Void) {
        fetchPublicFiles(oAuthToken: oAuthToken, baseURL: baseURL, limit: limit, offset: offset, type: "file", completion: completion)
    }
    
    
    func fetchDirs(oAuthToken: String, baseURL: String, limit: Int, offset: Int, completion: @escaping (Result<[PublishedFile], Error>) -> Void) {
        fetchPublicFiles(oAuthToken: oAuthToken, baseURL: baseURL, limit: limit, offset: offset, type: "dir", completion: completion)
    }
    
    
    func fetchFolderMetadata(oAuthToken: String, baseURL: String = APIEndpoint.baseURL.url, path: String, limit: Int, offset: Int, previewSize: String = "120x120", previewCrop: String = "true", completion: @escaping (Result<[File], Error>) -> Void) {
        guard var urlComponents = URLComponents(string: baseURL) else {
            completion(.failure(NSError(domain: "ApiError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let allMediaTypes = "document,image,spreadsheet"
        
        urlComponents.queryItems = [
            URLQueryItem(name: "path", value: path),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "media_type", value: allMediaTypes),
            URLQueryItem(name: "fields", value: "name,_embedded.items.path,_embedded.items.type,_embedded.items.name,_embedded.items.preview,_embedded.items.created,_embedded.items.modified,_embedded.items.mime_type,_embedded.items.size,_embedded.items.file, _embedded.items.publicURL"),
            URLQueryItem(name: "preview_size", value: previewSize),
            URLQueryItem(name: "preview_crop", value: previewCrop)
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "APIError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL Components"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("OAuth \(oAuthToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request failed with error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "APIError", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response:\n\(jsonString)")
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let response = try decoder.decode(FolderResponseModel.self, from: data)
                print("Decoded response: \(response)")
                completion(.success(response._embedded?.items ?? []))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    
    func fetchImage(from urlString: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        if let cachedImage = ImageCacheManager.shared.image(forKey: urlString) {
            completion(.success(cachedImage))
            return
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let data = data, let image = UIImage(data: data) {
                ImageCacheManager.shared.save(image: image, forKey: urlString)
                completion(.success(image))
            } else {
                completion(.failure(NSError(domain: "Image data invalid", code: 0, userInfo: nil)))
            }
        }
        task.resume()
    }

    
    func unpublishResource(oAuthToken: String, baseURL: String, path: String, completion: @escaping (Result<Void, Error>) -> Void) {

        guard var urlComponents = URLComponents(string: baseURL) else {
            completion(.failure(NSError(domain: "ApiError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "path", value: path)
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "APIError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL Components"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("OAuth \(oAuthToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "APIError", code: 500, userInfo: [NSLocalizedDescriptionKey: "No valid response"])))
                return
            }
            
            if httpResponse.statusCode == 200 {
                print("File unpublished")
                completion(.success(()))
            } else {
                let error = NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unpublish failed with status \(httpResponse.statusCode)"])
                completion(.failure(error))
            }
        }
        
        task.resume()
    }

    func deleteResource(oAuthToken: String, baseURL: String, permanently: String, path: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard var urlComponents = URLComponents(string: baseURL) else {
            completion(.failure(NSError(domain: "APIError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "path", value: path),
            URLQueryItem(name: "permanently", value: permanently)
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "APIError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL Components"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("OAuth \(oAuthToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "APIError", code: 500, userInfo: [NSLocalizedDescriptionKey: "No valid response"])))
                return
            }
            
            if httpResponse.statusCode == 204 || httpResponse.statusCode == 202 {
                print("File deleted")
                completion(.success(()))
            } else {
                let error = NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Delete failed with status \(httpResponse.statusCode)"])
                completion(.failure(error))
            }
        }
        
        task.resume()
    }

    
    }

extension APIService {
    func publishResource(oAuthToken: String,
                         baseURL: String,
                         path: String,
                         allowAddressAccess: Bool = false,
                         publicSettings: [String: Any] = [:],
                         completion: @escaping (Result<Void, Error>) -> Void) {
        guard var urlComponents = URLComponents(string: baseURL) else {
            completion(.failure(NSError(domain: "APIError", code: 400,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "path", value: path),
            URLQueryItem(name: "allow_address_access", value: allowAddressAccess ? "true" : "false")
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "APIError", code: 400,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid URL Components"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("OAuth \(oAuthToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["public_settings": publicSettings]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "APIError", code: 500,
                                            userInfo: [NSLocalizedDescriptionKey: "No valid response"])))
                return
            }
            guard httpResponse.statusCode == 200 else {
                let errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                completion(.failure(NSError(domain: "APIError", code: httpResponse.statusCode,
                                            userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }
            completion(.success(()))
        }
        task.resume()
    }
    
    func fetchResourceDetails(oAuthToken: String,
                              path: String,
                              completion: @escaping (Result<String, Error>) -> Void) {
        guard var urlComponents = URLComponents(string: APIEndpoint.resources.url) else {
            completion(.failure(NSError(domain: "APIError", code: 400,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let encodedPath = path
        
        urlComponents.queryItems = [
            URLQueryItem(name: "path", value: encodedPath),
            URLQueryItem(name: "fields", value: "public_url")
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "APIError", code: 400,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid URL Components"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("OAuth \(oAuthToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, !data.isEmpty else {
                completion(.failure(NSError(domain: "APIError", code: 500,
                                            userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            print("Response data: \(String(data: data, encoding: .utf8) ?? "No readable data")")
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let publicLink = json["public_url"] as? String {
                    completion(.success(publicLink))
                } else {
                    completion(.failure(NSError(domain: "APIError", code: 500,
                                                userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
extension APIService {
    func fetchAllFilesAndFolders(oAuthToken: String,
                                 baseURL: String,
                                 path: String,
                                 limit: Int,
                                 offset: Int,
                                 sort: String = "created",
                                 type: String,
                                 previewSize: String = "S",
                                 previewCrop: String = "true",
                                 completion: @escaping (Result<[File], Error>) -> Void) {
        // Если path не закодирован, закодируем его один раз
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
        
        guard var urlComponents = URLComponents(string: baseURL) else {
            completion(.failure(NSError(domain: "APIError", code: 400,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let allMediaTypes = "document,image,spreadsheet"
        
        urlComponents.queryItems = [
            URLQueryItem(name: "path", value: encodedPath),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "media_type", value: allMediaTypes),
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "sort", value: sort)
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "APIError", code: 400,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid URL Components"])))
            return
        }
        
        print("Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("OAuth \(oAuthToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, !data.isEmpty else {
                completion(.failure(NSError(domain: "APIError", code: 500,
                                            userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            print("Raw JSON response:\n\(String(data: data, encoding: .utf8) ?? "No readable data")")
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let folderResponse = try decoder.decode(FolderResponseModel.self, from: data)
                let items = folderResponse._embedded?.items ?? []
                completion(.success(items))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // Удобные методы для файлов и папок
    func fetchAllFiles(oAuthToken: String,
                       baseURL: String,
                       path: String,
                       limit: Int,
                       offset: Int,
                       sort: String,
                       completion: @escaping (Result<[File], Error>) -> Void) {
        fetchAllFilesAndFolders(oAuthToken: oAuthToken,
                                baseURL: baseURL,
                                path: path,
                                limit: limit,
                                offset: offset,
                                sort: sort,
                                type: "file",
                                completion: completion)
    }
    
    func fetchAllDirs(oAuthToken: String,
                      baseURL: String,
                      path: String,
                      limit: Int,
                      offset: Int,
                      sort: String,
                      completion: @escaping (Result<[File], Error>) -> Void) {
        fetchAllFilesAndFolders(oAuthToken: oAuthToken,
                                baseURL: baseURL,
                                path: path,
                                limit: limit,
                                offset: offset,
                                sort: sort,
                                type: "dir",
                                completion: completion)
    }
}
