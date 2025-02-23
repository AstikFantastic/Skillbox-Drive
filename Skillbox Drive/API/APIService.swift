import UIKit

class APIService {
    
    static let shared = APIService()
    
    private let baseURL = "https://cloud-api.yandex.net/v1/disk/"
    
    func fetchDiskData(oAuthToken: String, completion: @escaping (Result<ProfileModel, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
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
    
    func fetchPublicFiles(oAuthToken: String, limit: Int = 10, offset: Int = 0, type: String, previewSize: String = "S", previewCrop: String = "true",
                          completion: @escaping (Result<[PublishedFile], Error>) -> Void) {

        guard var urlComponents = URLComponents(string: "https://cloud-api.yandex.net/v1/disk/resources/public") else {
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
            
            // Отладочный вывод raw JSON
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
    
    
    func fetchFiles(oAuthToken: String, limit: Int = 100, offset: Int = 0, completion: @escaping (Result<[PublishedFile], Error>) -> Void) {
        fetchPublicFiles(oAuthToken: oAuthToken, limit: limit, offset: offset, type: "file", completion: completion)
    }
    
    
    func fetchDirs(oAuthToken: String, limit: Int = 100, offset: Int = 0, completion: @escaping (Result<[PublishedFile], Error>) -> Void) {
        fetchPublicFiles(oAuthToken: oAuthToken, limit: limit, offset: offset, type: "dir", completion: completion)
    }
    
    
    func fetchFolderMetadata(oAuthToken: String, path: String, limit: Int = 20, offset: Int = 0, previewSize: String = "120x120", previewCrop: String = "true", completion: @escaping (Result<[File], Error>) -> Void) {
        guard var urlComponents = URLComponents(string: "https://cloud-api.yandex.net/v1/disk/resources") else {
            completion(.failure(NSError(domain: "ApiError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let allMediaTypes = "document,image,spreadsheet"
        
        urlComponents.queryItems = [
            URLQueryItem(name: "path", value: path),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "media_type", value: allMediaTypes),
            URLQueryItem(name: "fields", value: "name,_embedded.items.path,_embedded.items.type,_embedded.items.name,_embedded.items.preview,_embedded.items.created,_embedded.items.modified,_embedded.items.mime_type,_embedded.items.size,_embedded.items.file"),
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
    
    func fetchAllFiles(oAuthToken: String, limit: Int = 1, offset: Int = 0, completion: @escaping (Result<[PublishedFile], Error>) -> Void) {
        guard var urlComponents = URLComponents(string: "https://cloud-api.yandex.net/v1/disk/resources/files") else {
            completion(.failure(NSError(domain: "APIError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let allMediaTypes = "document,image,spreadsheet"
        
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "media_type", value: allMediaTypes)
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

    
    func fetchLastLoadedFiles(oAuthToken: String, limit: Int = 20, offset: Int = 0, previewSize: String = "25x22", previewCrop: String = "true",  completion: @escaping (Result<[PublishedFile], Error>) -> Void) {
        guard var urlComponents = URLComponents(string: "https://cloud-api.yandex.net/v1/disk/resources/last-uploaded") else {
            completion(.failure(NSError(domain: "APIError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let allMediaTypes = "document,image,spreadsheet"
        
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "media_type", value: allMediaTypes),
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
        
        print("Fetching data from: \(url)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("Error: No data received")
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
    
    func unpublishFiles(oAuthToken: String, path: String,  completion: @escaping (Result<LastLoadedFiles, Error>) -> Void) {
        guard var urlComponents = URLComponents(string: "https://cloud-api.yandex.net/v1/disk/resources/unpublish") else {
            completion(.failure(NSError(domain: "APIError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
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
        
        print("Fetching data from: \(url)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("Error: No data received")
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
                let lastFilesModel = try decoder.decode(LastLoadedFiles.self, from: data)
                completion(.success(lastFilesModel))
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func unpublishResource(oAuthToken: String, path: String, completion: @escaping (Result<Void, Error>) -> Void) {

        guard var urlComponents = URLComponents(string: "https://cloud-api.yandex.net/v1/disk/resources/unpublish") else {
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

    }

