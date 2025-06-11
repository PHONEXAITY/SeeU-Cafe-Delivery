import SwiftUI

struct ContentView: View {
    @StateObject private var apiService = APIService.shared
    @StateObject private var mapBoxManager = MapBoxManager.shared
    @State private var employeeId = ""

    var body: some View {
        Group {
            if apiService.isAuthenticated {
                MainTabView()
                    .environmentObject(apiService)
                    .environmentObject(mapBoxManager)
            } else {
                LoginView()
                    .environmentObject(apiService)
            }
        }
        .onAppear {
            // Check if already authenticated
            if apiService.isAuthenticated && apiService.currentEmployee != nil {
                print("User already authenticated")
            }
        }
    }
}

// MARK: - Login View with API Integration
struct LoginView: View {
    @EnvironmentObject var apiService: APIService
    @State private var inputEmployeeId = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated background
                AnimatedBackground()

                VStack(spacing: 0) {
                    Spacer()

                    // Floating card
                    VStack(spacing: 32) {
                        // Logo section
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.orange, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)

                                Image(systemName: "scooter")
                                    .font(.system(size: 50, weight: .light))
                                    .foregroundColor(.white)
                            }

                            VStack(spacing: 8) {
                                Text("SeeU Cafe")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Text("Delivery Partner")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Login form
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ລະຫັດພະນັກງານ")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)

                                HStack {
                                    Image(systemName: "person.badge.key")
                                        .font(.system(size: 18))
                                        .foregroundColor(.orange)
                                        .frame(width: 24)

                                    TextField("ປ້ອນລະຫັດພະນັກງານ", text: $inputEmployeeId)
                                        .font(.system(size: 16, weight: .medium))
                                        .keyboardType(.numberPad)
                                        .disabled(isLoading)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(LinearGradient(
                                            colors: [.orange.opacity(0.3), .pink.opacity(0.3)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ), lineWidth: 1)
                                )
                            }

                            Button(action: login) {
                                HStack(spacing: 12) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.9)
                                    } else {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.system(size: 18))
                                    }

                                    Text(isLoading ? "ກຳລັງເຂົ້າສູ່ລະບົບ..." : "ເຂົ້າສູ່ລະບົບ")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(inputEmployeeId.isEmpty || isLoading)
                            .scaleEffect(inputEmployeeId.isEmpty ? 0.95 : 1.0)
                            .animation(.spring(response: 0.3), value: inputEmployeeId.isEmpty)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 40)
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 24)

                    Spacer()
                    Spacer()
                }
            }
        }
        .alert("ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ", isPresented: $showError) {
            Button("ຕົກລົງ") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func login() {
         guard !inputEmployeeId.isEmpty else { return }
         
         isLoading = true
         errorMessage = ""
         
         apiService.login(employeeId: inputEmployeeId)
             .sink(
                 receiveCompletion: { completion in
                     DispatchQueue.main.async {
                         self.isLoading = false
                         
                         if case .failure(let error) = completion {
                             self.errorMessage = "ບໍ່ສາມາດເຊື່ອມຕໍ່ກັບເຊີເວີໄດ້: \(error.localizedDescription)"
                             self.showError = true
                         }
                     }
                 },
                 receiveValue: { response in
                     DispatchQueue.main.async {
                         self.isLoading = false
                         
                         if response.success {
                             print("Login successful for employee: \(response.employee?.fullName ?? "")")
                         } else {
                             self.errorMessage = response.message ?? "ກະລຸນາກວດສອບລະຫັດພະນັກງານຂອງທ່ານ"
                             self.showError = true
                         }
                     }
                 }
             )
             .store(in: &cancellables)
     }
 }

// MARK: - Animated Background
struct AnimatedBackground: View {
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.8, blue: 0.4),
                    Color(red: 1.0, green: 0.6, blue: 0.8),
                    Color(red: 0.8, green: 0.4, blue: 1.0)
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }

            // Floating circles
            ForEach(0..<6, id: \.self) { i in
                FloatingCircle(delay: Double(i) * 0.5)
            }
        }
    }
}

struct FloatingCircle: View {
    let delay: Double
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(.white.opacity(0.1))
            .frame(width: CGFloat.random(in: 60...120))
            .offset(
                x: isAnimating ? CGFloat.random(in: -100...100) : CGFloat.random(in: -50...50),
                y: isAnimating ? CGFloat.random(in: -200...200) : CGFloat.random(in: -100...100)
            )
            .animation(
                .easeInOut(duration: Double.random(in: 3...6))
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Main Tab View with API Integration
struct MainTabView: View {
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var mapBoxManager: MapBoxManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DeliveryListView()
                .environmentObject(apiService)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "list.bullet.circle.fill" : "list.bullet.circle")
                    Text("ລາຍການສົ່ງ")
                }
                .tag(0)

            MapView()
                .environmentObject(apiService)
                .environmentObject(mapBoxManager)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "map.fill" : "map")
                    Text("ແຜນທີ່")
                }
                .tag(1)

            ProfileView()
                .environmentObject(apiService)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.circle.fill" : "person.circle")
                    Text("ໂປຣໄຟລ໌")
                }
                .tag(2)
        }
        .accentColor(.orange)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Delivery List View with API Integration
struct DeliveryListView: View {
    @EnvironmentObject var apiService: APIService
    @State private var deliveries: [Delivery] = []
    @State private var isRefreshing = false
    @State private var searchText = ""
    @State private var cancellables = Set<AnyCancellable>()
    @State private var errorMessage = ""
    @State private var showError = false

    var filteredDeliveries: [Delivery] {
        if searchText.isEmpty {
            return deliveries
        }
        return deliveries.filter { delivery in
            delivery.order.orderId.localizedCaseInsensitiveContains(searchText) ||
            (delivery.order.user?.fullName.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ສະບາຍດີ! 👋")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            if let employee = apiService.currentEmployee {
                                Text("ສະບາຍດີ \(employee.firstName)")
                                    .font(.system(size: 24, weight: .bold))
                            } else {
                                Text("ລາຍການສົ່ງມື້ນີ້")
                                    .font(.system(size: 28, weight: .bold))
                            }
                        }
                        Spacer()

                        NotificationBell()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("ຄົ້ນຫາອໍເດີ້...", text: $searchText)
                            .font(.system(size: 16))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)

                    // Status summary
                    DeliveryStatusSummaryView(deliveries: deliveries)
                        .padding(.horizontal, 20)
                }
                .background(.ultraThinMaterial)

                // Delivery list
                if deliveries.isEmpty && !isRefreshing {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "bicycle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("ຍັງບໍ່ມີການສົ່ງວັນນີ້")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Button("ໂຫຼດຂໍ້ມູນໃໝ່") {
                            loadDeliveries()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredDeliveries, id: \.id) { delivery in
                                NavigationLink(destination: DeliveryDetailView(delivery: DeliveryItem(from: delivery))) {
                                    ApiDeliveryCard(delivery: delivery)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .refreshable {
                        await refreshDeliveries()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadDeliveries()
        }
        .alert("ຂໍ້ຜິດພາດ", isPresented: $showError) {
            Button("ຕົກລົງ") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func loadDeliveries() {
        guard let employee = apiService.currentEmployee else { return }
        
        isRefreshing = true
        
        apiService.getEmployeeDeliveries(employeeId: employee.id)
            .sink(
                receiveCompletion: { completion in
                    DispatchQueue.main.async {
                        self.isRefreshing = false
                        
                        if case .failure(let error) = completion {
                            self.errorMessage = "ບໍ່ສາມາດໂຫຼດຂໍ້ມູນການສົ່ງໄດ້: \(error.localizedDescription)"
                            self.showError = true
                        }
                    }
                },
                receiveValue: { response in
                    DispatchQueue.main.async {
                        self.isRefreshing = false
                        self.deliveries = response.data
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func refreshDeliveries() async {
        loadDeliveries()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

// MARK: - API Delivery Card
struct ApiDeliveryCard: View {
    let delivery: Delivery

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(delivery.order.orderId)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text(delivery.order.user?.fullName ?? "ລູກຄ້າ")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    ApiStatusBadge(status: delivery.status)
                    Text("\(Int(delivery.order.totalPrice).formatted()) LAK")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
            }

            // Address
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)

                Text(delivery.deliveryAddress ?? "ບໍ່ລະບຸທີ່ຢູ່")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()
            }

            // Time and items
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    
                    if let timeString = delivery.estimatedDeliveryTime {
                        let formatter = ISO8601DateFormatter()
                        let date = formatter.date(from: timeString) ?? Date()
                        Text(date.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.blue)
                    } else {
                        Text("ບໍ່ລະບຸເວລາ")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    Text("\(delivery.order.orderDetails?.count ?? 0) ລາຍການ")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.green)
                }
            }

            // Action button
            if delivery.status != "delivered" {
                ActionButton(delivery: delivery)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Action Button
struct ActionButton: View {
    @EnvironmentObject var apiService: APIService
    let delivery: Delivery
    @State private var isUpdating = false
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        Button(action: handleAction) {
            HStack {
                if isUpdating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: getActionIcon())
                    Text(getActionText())
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(Color(delivery.status.deliveryStatusColor))
            .cornerRadius(10)
        }
        .disabled(isUpdating)
    }
    
    private func getActionIcon() -> String {
        switch delivery.status.lowercased() {
        case "pending", "preparing":
            return "bicycle"
        case "out_for_delivery":
            return "checkmark.circle"
        default:
            return "checkmark.circle"
        }
    }
    
    private func getActionText() -> String {
        switch delivery.status.lowercased() {
        case "pending", "preparing":
            return "ຮັບວຽກນີ້"
        case "out_for_delivery":
            return "ສົ່ງສຳເລັດແລ້ວ"
        default:
            return "ອັບເດດ"
        }
    }
    
    private func handleAction() {
        let newStatus: String
        
        switch delivery.status.lowercased() {
        case "pending", "preparing":
            newStatus = "out_for_delivery"
        case "out_for_delivery":
            newStatus = "delivered"
        default:
            return
        }
        
        isUpdating = true
        
        apiService.updateDeliveryStatus(
            deliveryId: delivery.id,
            status: newStatus,
            notes: nil
        )
        .sink(
            receiveCompletion: { completion in
                DispatchQueue.main.async {
                    self.isUpdating = false
                    
                    if case .failure(let error) = completion {
                        print("Failed to update status: \(error)")
                    }
                }
            },
            receiveValue: { updatedDelivery in
                DispatchQueue.main.async {
                    self.isUpdating = false
                    print("Status updated successfully to: \(updatedDelivery.status)")
                }
            }
        )
        .store(in: &cancellables)
    }
}

// MARK: - API Status Badge
struct ApiStatusBadge: View {
    let status: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(status.deliveryStatusColor))
                .frame(width: 8, height: 8)

            Text(status.deliveryStatusDisplayText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(status.deliveryStatusColor))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(status.deliveryStatusColor).opacity(0.15))
        .cornerRadius(20)
    }
}

// MARK: - Notification Bell
struct NotificationBell: View {
    @State private var hasNotification = true

    var body: some View {
        Button(action: {
            hasNotification = false
        }) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)

                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)

                if hasNotification {
                    Circle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                        .offset(x: 8, y: -8)
                }
            }
        }
    }
}

// MARK: - Modern Delivery Card
struct ModernDeliveryCard: View {
    let delivery: DeliveryItem

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(delivery.orderID)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text(delivery.customerName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    ModernStatusBadge(status: delivery.status)
                    Text("\(delivery.totalAmount.formatted()) LAK")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
            }

            // Address
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)

                Text(delivery.address)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()
            }

            // Time and items
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    Text(delivery.estimatedTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    Text("\(delivery.items.count) ລາຍການ") // Translated: items
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.green)
                }
            }

            // Action button
            if delivery.status != .delivered {
                Button(action: {
                    // TODO: Quick action
                }) {
                    HStack {
                        Image(systemName: delivery.status == .preparing ? "bicycle" : "checkmark.circle")
                        Text(delivery.status == .preparing ? "ຮັບວຽກນີ້" : "ສົ່ງສຳເລັດແລ້ວ") // Translated: Accept this job / Delivered
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(delivery.status.color)
                    .cornerRadius(10)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Modern Status Badge
struct ModernStatusBadge: View {
    let status: DeliveryStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)

            Text(status.displayText) // Uses DeliveryStatus displayText which will be translated
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(status.color.opacity(0.15))
        .cornerRadius(20)
    }
}

// MARK: - Delivery Status Summary
struct DeliveryStatusSummaryView: View {
    let deliveries: [DeliveryItem]

    private var statusCounts: (preparing: Int, outForDelivery: Int, completed: Int) {
        let preparing = deliveries.filter { $0.status == .preparing }.count
        let outForDelivery = deliveries.filter { $0.status == .outForDelivery }.count
        let completed = deliveries.filter { $0.status == .delivered }.count
        return (preparing, outForDelivery, completed)
    }

    var body: some View {
        HStack(spacing: 12) {
            ModernStatusCard(
                title: "ກຳລັງກຽມ", // Translated: Preparing
                count: statusCounts.preparing,
                color: .blue,
                icon: "clock.fill"
            )

            ModernStatusCard(
                title: "ກຳລັງສົ່ງ", // Translated: Out for Delivery
                count: statusCounts.outForDelivery,
                color: .orange,
                icon: "bicycle"
            )

            ModernStatusCard(
                title: "ສົ່ງສຳເລັດ", // Translated: Completed
                count: statusCounts.completed,
                color: .green,
                icon: "checkmark.circle.fill"
            )
        }
    }
}

struct ModernStatusCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)

            Text("\(count)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Delivery Detail View
struct DeliveryDetailView: View {
    let delivery: DeliveryItem
    @State private var showingCallAlert = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header card
                ModernOrderInfoCard(delivery: delivery)

                // Customer card
                ModernCustomerCard(delivery: delivery, showingCallAlert: $showingCallAlert)

                // Items card
                ModernItemsCard(items: delivery.items)

                // Map preview card
                ModernMapPreviewCard(delivery: delivery)

                // Action buttons
                ModernActionButtons(delivery: delivery)
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.orange)
                }
            }

            ToolbarItem(placement: .principal) {
                Text("ລາຍລະອຽດການສົ່ງ") // Translated: Delivery Details
                    .font(.system(size: 18, weight: .bold))
            }
        }
        .alert("ໂທຫາລູກຄ້າ", isPresented: $showingCallAlert) { // Translated: Call Customer
            Button("ໂທ") { // Translated: Call
                // TODO: Make phone call
            }
            Button("ຍົກເລີກ", role: .cancel) { } // Translated: Cancel
        } message: {
            Text("ໂທຫາ \(delivery.customerName) ທີ່ເບີ \(delivery.customerPhone)?") // Translated: Call ... at ...?
        }
    }
}

struct ModernOrderInfoCard: View {
    let delivery: DeliveryItem

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("ຂໍ້ມູນອໍເດີ້") // Translated: Order Information
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                ModernStatusBadge(status: delivery.status)
            }

            VStack(spacing: 12) {
                ModernInfoRow(
                    icon: "number.circle.fill",
                    label: "ລະຫັດອໍເດີ້", // Translated: Order ID
                    value: delivery.orderID,
                    color: .blue
                )
                ModernInfoRow(
                    icon: "banknote.fill",
                    label: "ຍອດລວມ", // Translated: Total Amount
                    value: "\(delivery.totalAmount.formatted()) LAK",
                    color: .green
                )
                ModernInfoRow(
                    icon: "clock.fill",
                    label: "ເວລາໂດຍປະມານ", // Translated: Estimated Time
                    value: delivery.estimatedTime.formatted(date: .omitted, time: .shortened),
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct ModernCustomerCard: View {
    let delivery: DeliveryItem
    @Binding var showingCallAlert: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("ຂໍ້ມູນລູກຄ້າ") // Translated: Customer Information
                    .font(.system(size: 20, weight: .bold))
                Spacer()

                Button(action: { showingCallAlert = true }) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(.green)
                        .cornerRadius(18)
                }
            }

            VStack(spacing: 12) {
                ModernInfoRow(
                    icon: "person.fill",
                    label: "ຊື່", // Translated: Name
                    value: delivery.customerName,
                    color: .blue
                )
                ModernInfoRow(
                    icon: "phone.fill",
                    label: "ເບີໂທ", // Translated: Phone Number
                    value: delivery.customerPhone,
                    color: .green
                )
                ModernInfoRow(
                    icon: "location.fill",
                    label: "ທີ່ຢູ່", // Translated: Address
                    value: delivery.address,
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct ModernItemsCard: View {
    let items: [OrderItem]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("ລາຍການສິນຄ້າ") // Translated: Item List
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Text("\(items.count) ລາຍການ") // Translated: items
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                HStack(spacing: 12) {
                    Circle()
                        .fill(.orange.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("\(item.quantity)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.orange)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name) // Item names are already in Lao from mock data
                            .font(.system(size: 16, weight: .semibold))
                        Text("ລາຍການທີ \(index + 1)") // Translated: Item X
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("\(item.price.formatted()) LAK")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.vertical, 8)

                if index < items.count - 1 {
                    Divider()
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct ModernMapPreviewCard: View {
    let delivery: DeliveryItem

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("ຕຳແໜ່ງລູກຄ້າ") // Translated: Customer Location
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Button(action: {
                    // TODO: Open in Maps
                }) {
                    Text("ເປີດແຜນທີ່") // Translated: Open Map
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }

            // Map preview placeholder
            ZStack {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .frame(height: 120)
                    .cornerRadius(12)

                VStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    Text("ແຜນທີ່ຈະສະແດງຢູ່ບ່ອນນີ້") // Translated: Map will be displayed here
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }

            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.red)
                Text("Lat: \(delivery.latitude, specifier: "%.4f"), Lng: \(delivery.longitude, specifier: "%.4f")")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct ModernActionButtons: View {
    let delivery: DeliveryItem

    var body: some View {
        VStack(spacing: 12) {
            if delivery.status == .preparing {
                Button(action: {
                    // TODO: Mark as picked up
                }) {
                    HStack {
                        Image(systemName: "bicycle")
                            .font(.system(size: 18, weight: .semibold))
                        Text("ຮັບອໍເດີ້ແລ້ວ") // Translated: Order Accepted
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                }

            } else if delivery.status == .outForDelivery {
                VStack(spacing: 12) {
                    Button(action: {
                        // TODO: Open maps
                    }) {
                        HStack {
                            Image(systemName: "map.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("ເປີດແຜນທີ່ນຳທາງ") // Translated: Open Navigation
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }

                    Button(action: {
                        // TODO: Mark as delivered
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("ຢືນຢັນສົ່ງສຳເລັດ") // Translated: Confirm Delivery
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                }
            } else if delivery.status == .delivered {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                    Text("ວຽກນີ້ສຳເລັດແລ້ວ") // Translated: This job is complete
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(.green.opacity(0.1))
                .cornerRadius(16)
            }
        }
    }
}

struct ModernInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Enhanced Map View
struct MapView: View {
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var mapBoxManager: MapBoxManager
    @State private var deliveries: [Delivery] = []
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("ແຜນທີ່ການສົ່ງ")
                            .font(.system(size: 28, weight: .bold))
                        Spacer()

                        Button(action: refreshDeliveries) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Map stats
                    HStack(spacing: 12) {
                        MapStatCard(
                            icon: "location.fill",
                            title: "ປາຍທາງ",
                            value: "\(deliveries.filter { $0.status != "delivered" }.count)",
                            color: .red
                        )

                        MapStatCard(
                            icon: "bicycle",
                            title: "ກຳລັງສົ່ງ",
                            value: "\(deliveries.filter { $0.status == "out_for_delivery" }.count)",
                            color: .orange
                        )

                        MapStatCard(
                            icon: "checkmark.circle.fill",
                            title: "ສຳເລັດ",
                            value: "\(deliveries.filter { $0.status == "delivered" }.count)",
                            color: .green
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .background(.ultraThinMaterial)

                // MapBox Map
                EnhancedMapView(deliveries: deliveries)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadDeliveries()
        }
    }
    
    private func loadDeliveries() {
        guard let employee = apiService.currentEmployee else { return }
        
        apiService.getEmployeeDeliveries(employeeId: employee.id)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to load deliveries for map: \(error)")
                    }
                },
                receiveValue: { response in
                    DispatchQueue.main.async {
                        self.deliveries = response.data
                        self.mapBoxManager.updateDeliveryLocations(from: response.data)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func refreshDeliveries() {
        loadDeliveries()
    }
}

struct MapStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ModernMapCard: View {
    let delivery: DeliveryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ModernStatusBadge(status: delivery.status)
                Spacer()
                Text("\(delivery.totalAmount.formatted()) LAK")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(delivery.orderID)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Text(delivery.customerName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Text(delivery.address)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Button(action: {
                // TODO: Navigate to this delivery
            }) {
                HStack {
                    Image(systemName: "arrow.turn.up.right")
                        .font(.system(size: 12))
                    Text("ນຳທາງ") // Translated: Navigate
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.orange)
                .cornerRadius(16)
            }
        }
        .frame(width: 180, height: 140) // Adjusted height to fit content better if needed
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Profile View with API Integration
struct ProfileView: View {
    @EnvironmentObject var apiService: APIService
    @State private var showingLogoutAlert = false
    @State private var todayStats = (delivered: 0, inProgress: 0, earned: 0)

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .shadow(color: .orange.opacity(0.3), radius: 15, x: 0, y: 8)

                            // Profile image or initials
                            if let employee = apiService.currentEmployee,
                               let photoURL = employee.profilePhoto,
                               !photoURL.isEmpty {
                                AsyncImage(url: URL(string: photoURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                        }

                        VStack(spacing: 8) {
                            if let employee = apiService.currentEmployee {
                                Text(employee.fullName)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(employee.position)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)

                                HStack {
                                    Image(systemName: "person.badge.key.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange)
                                    Text("ລະຫັດ: \(employee.employeeId)")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.orange.opacity(0.1))
                                .cornerRadius(20)
                            } else {
                                Text("ພະນັກງານສົ່ງອາຫານ")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.top, 20)

                    // Today's performance
                    VStack(spacing: 16) {
                        HStack {
                            Text("ຜົນງານມື້ນີ້")
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                            Text(Date().formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 16) {
                            ModernStatCard(
                                icon: "checkmark.circle.fill",
                                title: "ສົ່ງແລ້ວ",
                                value: "\(todayStats.delivered)",
                                color: .green
                            )

                            ModernStatCard(
                                icon: "bicycle",
                                title: "ກຳລັງສົ່ງ",
                                value: "\(todayStats.inProgress)",
                                color: .orange
                            )
                        }

                        ModernEarningsCard(amount: todayStats.earned)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    // Menu options
                    VStack(spacing: 12) {
                        ModernMenuButton(
                            icon: "chart.bar.fill",
                            title: "ສະຖິຕິການເຮັດວຽກ",
                            color: .blue
                        ) {
                            // TODO: Show statistics
                        }

                        ModernMenuButton(
                            icon: "bell.fill",
                            title: "ການແຈ້ງເຕືອນ",
                            color: .purple
                        ) {
                            // TODO: Notification settings
                        }

                        ModernMenuButton(
                            icon: "gear",
                            title: "ຕັ້ງຄ່າ",
                            color: .gray
                        ) {
                            // TODO: Settings
                        }

                        ModernMenuButton(
                            icon: "questionmark.circle.fill",
                            title: "ຊ່ວຍເຫຼືອ",
                            color: .cyan
                        ) {
                            // TODO: Help
                        }
                    }
                    .padding(.horizontal, 20)

                    // Logout button
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                            Text("ອອກຈາກລະບົບ")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(.red.opacity(0.1))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("ອອກຈາກລະບົບ", isPresented: $showingLogoutAlert) {
            Button("ອອກຈາກລະບົບ", role: .destructive) {
                apiService.logout()
            }
            Button("ຍົກເລີກ", role: .cancel) { }
        } message: {
            Text("ທ່ານຕ້ອງການອອກຈາກລະບົບບໍ່?")
        }
    }
}
struct ModernStatCard: View { // This struct is used in ProfileView and needs its titles translated there.
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)

            Text(title) // Title is passed in, already translated
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

struct ModernEarningsCard: View {
    let amount: Int

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: "banknote.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("ລາຍຮັບມື້ນີ້") // Translated: Today's Earnings
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text("\(amount.formatted()) LAK")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.green)
            }

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.green)
        }
        .padding(20)
        .background(.green.opacity(0.1))
        .cornerRadius(16)
    }
}

struct ModernMenuButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }

                Text(title) // Title is passed in, already translated
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Models
struct DeliveryItem: Identifiable {
    let id: Int
    let orderID: String
    let customerName: String // Names are kept as is from mock data (Lao names)
    let customerPhone: String
    let address: String // Addresses are kept as is from mock data (Lao addresses)
    let status: DeliveryStatus
    let items: [OrderItem] // Item names are kept as is from mock data (Lao names)
    let totalAmount: Int
    let estimatedTime: Date
    let latitude: Double
    let longitude: Double
}

struct OrderItem {
    let name: String // Item names are kept as is from mock data (Lao names)
    let quantity: Int
    let price: Int
}

enum DeliveryStatus: CaseIterable {
    case preparing
    case outForDelivery
    case delivered
    case cancelled

    var displayText: String {
        switch self {
        case .preparing: return "ກຳລັງກຽມ" // Translated: Preparing
        case .outForDelivery: return "ກຳລັງສົ່ງ" // Translated: Out for Delivery
        case .delivered: return "ສົ່ງແລ້ວ" // Translated: Delivered
        case .cancelled: return "ຍົກເລີກ" // Translated: Cancelled
        }
    }

    var color: Color {
        switch self {
        case .preparing: return .blue
        case .outForDelivery: return .orange
        case .delivered: return .green
        case .cancelled: return .red
        }
    }
}

#Preview {
    ContentView()
}
