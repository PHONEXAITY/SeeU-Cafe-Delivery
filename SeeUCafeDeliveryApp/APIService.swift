//
//  APIService.swift
//  SeeUCafeDeliveryApp
//

import Foundation
import Combine

// MARK: - API Models
struct LoginRequest: Codable {
    let employeeId: String
}

struct LoginResponse: Codable {
    let success: Bool
    let employee: Employee?
    let message: String?
}

struct Employee: Codable, Identifiable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let phone: String?
    let position: String
    let status: String
    let profilePhoto: String?
    let employeeId: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phone
        case position
        case status
        case profilePhoto = "profile_photo"
        case employeeId = "Employee_id"
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}

struct Delivery: Codable, Identifiable {
    let id: Int
    let orderId: Int
    let status: String
    let deliveryId: String
    let deliveryAddress: String?
    let customerLatitude: Double?
    let customerLongitude: Double?
    let customerLocationNote: String?
    let phoneNumber: String?
    let employeeId: Int?
    let deliveryFee: Double?
    let estimatedDeliveryTime: String?
    let actualDeliveryTime: String?
    let pickupFromKitchenTime: String?
    let customerNote: String?
    let order: Order
    let employee: Employee?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case status
        case deliveryId = "delivery_id"
        case deliveryAddress = "delivery_address"
        case customerLatitude = "customer_latitude"
        case customerLongitude = "customer_longitude"
        case customerLocationNote = "customer_location_note"
        case phoneNumber = "phone_number"
        case employeeId = "employee_id"
        case deliveryFee = "delivery_fee"
        case estimatedDeliveryTime = "estimated_delivery_time"
        case actualDeliveryTime = "actual_delivery_time"
        case pickupFromKitchenTime = "pickup_from_kitchen_time"
        case customerNote = "customer_note"
        case order
        case employee
    }
}

struct Order: Codable, Identifiable {
    let id: Int
    let orderId: String
    let userId: Int?
    let createAt: String
    let totalPrice: Double
    let user: User?
    let orderDetails: [OrderDetail]?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case userId = "User_id"
        case createAt = "create_at"
        case totalPrice = "total_price"
        case user
        case orderDetails = "order_details"
    }
}

struct User: Codable {
    let id: Int
    let email: String
    let firstName: String?
    let lastName: String?
    let phone: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case phone
    }
    
    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
}

struct OrderDetail: Codable, Identifiable {
    let id: Int
    let quantity: Int
    let price: Double
    let notes: String?
    let foodMenu: FoodMenu?
    let beverageMenu: BeverageMenu?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case quantity
        case price
        case notes
        case foodMenu = "food_menu"
        case beverageMenu = "beverage_menu"
    }
    
    var itemName: String {
        return foodMenu?.name ?? beverageMenu?.name ?? "ບໍ່ລະບຸຊື່"
    }
}

struct FoodMenu: Codable {
    let id: Int
    let name: String
}

struct BeverageMenu: Codable {
    let id: Int
    let name: String
}

struct DeliveryResponse: Codable {
    let data: [Delivery]
    let pagination: Pagination?
}

struct Pagination: Codable {
    let page: Int
    let limit: Int
    let totalCount: Int
    let totalPages: Int
    let hasNextPage: Bool
    let hasPreviousPage: Bool
    
    private enum CodingKeys: String, CodingKey {
        case page
        case limit
        case totalCount
        case totalPages
        case hasNextPage
        case hasPreviousPage
    }
}

struct UpdateStatusRequest: Codable {
    let status: String
    let notes: String?
}

struct LocationUpdate: Codable {
    let latitude: Double
    let longitude: Double
    let locationNote: String?
    let notifyCustomer: Bool?
}

// MARK: - API Service
class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:3000/api"
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isAuthenticated = false
    @Published var currentEmployee: Employee?
    @Published var authToken: String?
    
    private init() {
        loadAuthToken()
    }
    
    // MARK: - Authentication
    func login(employeeId: String) -> AnyPublisher<LoginResponse, Error> {
        guard let url = URL(string: "\(baseURL)/auth/employee-login") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        let request = LoginRequest(employeeId: employeeId)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .decode(type: LoginResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] response in
                if response.success {
                    self?.currentEmployee = response.employee
                    self?.isAuthenticated = true
                    // In real implementation, you'd get token from response
                    self?.authToken = "dummy_token_\(employeeId)"
                    self?.saveAuthToken()
                }
            })
            .eraseToAnyPublisher()
    }
    
    func logout() {
        currentEmployee = nil
        isAuthenticated = false
        authToken = nil
        clearAuthToken()
    }
    
    // MARK: - Deliveries
    func getEmployeeDeliveries(employeeId: Int, status: String? = nil) -> AnyPublisher<DeliveryResponse, Error> {
        var components = URLComponents(string: "\(baseURL)/deliveries")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "employeeId", value: "\(employeeId)")
        ]
        
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        return makeAuthenticatedRequest(url: url)
            .decode(type: DeliveryResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func updateDeliveryStatus(deliveryId: Int, status: String, notes: String? = nil) -> AnyPublisher<Delivery, Error> {
        guard let url = URL(string: "\(baseURL)/deliveries/\(deliveryId)/status") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        let request = UpdateStatusRequest(status: status, notes: notes)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .decode(type: Delivery.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func updateDeliveryLocation(deliveryId: Int, latitude: Double, longitude: Double, notes: String? = nil) -> AnyPublisher<Data, Error> {
        guard let url = URL(string: "\(baseURL)/deliveries/\(deliveryId)/location") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        let locationUpdate = LocationUpdate(
            latitude: latitude,
            longitude: longitude,
            locationNote: notes,
            notifyCustomer: true
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(locationUpdate)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    private func makeAuthenticatedRequest(url: URL) -> AnyPublisher<Data, Error> {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .mapError { $0 as Error }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Token Management
    private func saveAuthToken() {
        UserDefaults.standard.set(authToken, forKey: "auth_token")
        UserDefaults.standard.set(isAuthenticated, forKey: "is_authenticated")
        
        if let employee = currentEmployee,
           let employeeData = try? JSONEncoder().encode(employee) {
            UserDefaults.standard.set(employeeData, forKey: "current_employee")
        }
    }
    
    private func loadAuthToken() {
        authToken = UserDefaults.standard.string(forKey: "auth_token")
        isAuthenticated = UserDefaults.standard.bool(forKey: "is_authenticated")
        
        if let employeeData = UserDefaults.standard.data(forKey: "current_employee"),
           let employee = try? JSONDecoder().decode(Employee.self, from: employeeData) {
            currentEmployee = employee
        }
    }
    
    private func clearAuthToken() {
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults.standard.removeObject(forKey: "is_authenticated")
        UserDefaults.standard.removeObject(forKey: "current_employee")
    }
}

// MARK: - Delivery Status Extensions
extension String {
    var deliveryStatusColor: String {
        switch self.lowercased() {
        case "pending": return "blue"
        case "preparing": return "blue"
        case "out_for_delivery": return "orange"
        case "delivered": return "green"
        case "cancelled": return "red"
        default: return "gray"
        }
    }
    
    var deliveryStatusDisplayText: String {
        switch self.lowercased() {
        case "pending": return "ລໍຖ້າ"
        case "preparing": return "ກຳລັງກຽມ"
        case "out_for_delivery": return "ກຳລັງສົ່ງ"
        case "delivered": return "ສົ່ງແລ້ວ"
        case "cancelled": return "ຍົກເລີກ"
        default: return self
        }
    }
}
