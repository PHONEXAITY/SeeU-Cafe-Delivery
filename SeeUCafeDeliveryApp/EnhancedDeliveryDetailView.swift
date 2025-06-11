//
//  EnhancedDeliveryDetailView.swift
//  SeeUCafeDeliveryApp
//

import SwiftUI
import MapboxMaps
import CoreLocation
import Combine

// MARK: - Enhanced Delivery Detail View
struct EnhancedDeliveryDetailView: View {
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var mapBoxManager: MapBoxManager
    
    let delivery: Delivery
    @State private var showingCallAlert = false
    @State private var showingNavigationOptions = false
    @State private var showingPhotoCapture = false
    @State private var isUpdatingStatus = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var deliveryProofImage: UIImage?
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Real-time status card
                RealTimeStatusCard(delivery: delivery)

                // Customer card with call functionality
                CustomerContactCard(delivery: delivery, showingCallAlert: $showingCallAlert)

                // Items card with API data
                ApiItemsCard(orderDetails: delivery.order.orderDetails ?? [])

                // Live location tracking card
                LiveLocationCard(delivery: delivery)

                // Action buttons based on status
                StatusActionButtons(
                    delivery: delivery,
                    isUpdatingStatus: $isUpdatingStatus,
                    showingNavigationOptions: $showingNavigationOptions,
                    showingPhotoCapture: $showingPhotoCapture,
                    deliveryProofImage: $deliveryProofImage
                )
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
                Text("ລາຍລະອຽດການສົ່ງ")
                    .font(.system(size: 18, weight: .bold))
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Refresh delivery data
                    refreshDeliveryData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
        }
        .alert("ໂທຫາລູກຄ້າ", isPresented: $showingCallAlert) {
            Button("ໂທ") {
                makePhoneCall()
            }
            Button("ຍົກເລີກ", role: .cancel) { }
        } message: {
            Text("ໂທຫາ \(delivery.order.user?.fullName ?? "ລູກຄ້າ") ທີ່ເບີ \(delivery.order.user?.phone ?? "")?")
        }
        .actionSheet(isPresented: $showingNavigationOptions) {
            ActionSheet(
                title: Text("ເລືອກແອັບນຳທາງ"),
                buttons: [
                    .default(Text("Apple Maps")) {
                        openAppleMaps()
                    },
                    .default(Text("Google Maps")) {
                        openGoogleMaps()
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingPhotoCapture) {
            PhotoCaptureView(capturedImage: $deliveryProofImage)
        }
    }
    
    private func refreshDeliveryData() {
        // TODO: Implement refresh functionality
        print("Refreshing delivery data for ID: \(delivery.id)")
    }
    
    private func makePhoneCall() {
        guard let phoneNumber = delivery.order.user?.phone,
              let url = URL(string: "tel://\(phoneNumber)") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openAppleMaps() {
        guard let lat = delivery.customerLatitude,
              let lng = delivery.customerLongitude else { return }
        
        NavigationHelper.openInMaps(
            latitude: lat,
            longitude: lng,
            destinationName: delivery.order.user?.fullName ?? "ປາຍທາງ"
        )
    }
    
    private func openGoogleMaps() {
        guard let lat = delivery.customerLatitude,
              let lng = delivery.customerLongitude else { return }
        
        let googleMapsURL = URL(string: "comgooglemaps://?daddr=\(lat),\(lng)&directionsmode=driving")
        let webURL = URL(string: "https://maps.google.com/?daddr=\(lat),\(lng)&directionsmode=driving")
        
        if let url = googleMapsURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = webURL {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Real-Time Status Card
struct RealTimeStatusCard: View {
    let delivery: Delivery
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("ສະຖານະການສົ່ງ")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                
                // Live status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(), value: true)
                    
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            
            VStack(spacing: 12) {
                ApiInfoRow(
                    icon: "number.circle.fill",
                    label: "ລະຫັດອໍເດີ້",
                    value: delivery.order.orderId,
                    color: .blue
                )
                
                ApiInfoRow(
                    icon: "banknote.fill",
                    label: "ຍອດລວມ",
                    value: "\(Int(delivery.order.totalPrice).formatted()) LAK",
                    color: .green
                )
                
                ApiInfoRow(
                    icon: "flag.fill",
                    label: "ສະຖານະ",
                    value: delivery.status.deliveryStatusDisplayText,
                    color: Color(delivery.status.deliveryStatusColor)
                )
                
                if let timeString = delivery.estimatedDeliveryTime {
                    let formatter = ISO8601DateFormatter()
                    let date = formatter.date(from: timeString) ?? Date()
                    
                    ApiInfoRow(
                        icon: "clock.fill",
                        label: "ເວລາໂດຍປະມານ",
                        value: date.formatted(date: .omitted, time: .shortened),
                        color: .orange
                    )
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Customer Contact Card
struct CustomerContactCard: View {
    let delivery: Delivery
    @Binding var showingCallAlert: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("ຂໍ້ມູນລູກຄ້າ")
                    .font(.system(size: 20, weight: .bold))
                Spacer()

                if let phone = delivery.order.user?.phone, !phone.isEmpty {
                    Button(action: { showingCallAlert = true }) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(.green)
                            .cornerRadius(18)
                    }
                }
            }

            VStack(spacing: 12) {
                if let user = delivery.order.user {
                    ApiInfoRow(
                        icon: "person.fill",
                        label: "ຊື່",
                        value: user.fullName.isEmpty ? "ບໍ່ລະບຸຊື່" : user.fullName,
                        color: .blue
                    )
                    
                    if let phone = user.phone, !phone.isEmpty {
                        ApiInfoRow(
                            icon: "phone.fill",
                            label: "ເບີໂທ",
                            value: phone,
                            color: .green
                        )
                    }
                    
                    ApiInfoRow(
                        icon: "envelope.fill",
                        label: "ອີເມວ",
                        value: user.email,
                        color: .purple
                    )
                }
                
                if let address = delivery.deliveryAddress {
                    ApiInfoRow(
                        icon: "location.fill",
                        label: "ທີ່ຢູ່",
                        value: address,
                        color: .orange
                    )
                }
                
                if let note = delivery.customerNote, !note.isEmpty {
                    ApiInfoRow(
                        icon: "note.text",
                        label: "ຫມາຍເຫດ",
                        value: note,
                        color: .gray
                    )
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - API Items Card
struct ApiItemsCard: View {
    let orderDetails: [OrderDetail]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("ລາຍການສິນຄ້າ")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Text("\(orderDetails.count) ລາຍການ")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            ForEach(orderDetails.indices, id: \.self) { index in
                let item = orderDetails[index]
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
                        Text(item.itemName)
                            .font(.system(size: 16, weight: .semibold))
                        Text("ລາຍການທີ \(index + 1)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        if let notes = item.notes, !notes.isEmpty {
                            Text("ຫມາຍເຫດ: \(notes)")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                                .italic()
                        }
                    }

                    Spacer()

                    Text("\(Int(item.price).formatted()) LAK")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.vertical, 8)

                if index < orderDetails.count - 1 {
                    Divider()
                }
            }
            
            // Total calculation
            let totalAmount = orderDetails.reduce(0) { sum, item in
                sum + (item.price * Double(item.quantity))
            }
            
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("ລວມທັງໝົດ")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(Int(totalAmount).formatted()) LAK")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Live Location Card
struct LiveLocationCard: View {
    @EnvironmentObject var mapBoxManager: MapBoxManager
    let delivery: Delivery
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("ຕຳແໜ່ງປະຈຸບັນ")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                
                // Location status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(mapBoxManager.currentLocation != nil ? .green : .red)
                        .frame(width: 8, height: 8)
                    
                    Text(mapBoxManager.currentLocation != nil ? "ເຊື່ອມຕໍ່" : "ບໍ່ເຊື່ອມຕໍ່")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(mapBoxManager.currentLocation != nil ? .green : .red)
                }
            }
            
            // Mini map preview
            ZStack {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .frame(height: 120)
                    .cornerRadius(12)
                
                // TODO: Implement MapBox mini map here
                VStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    Text("ແຜນທີ່ນຳທາງ")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            // Coordinates info
            VStack(spacing: 8) {
                if let currentLocation = mapBoxManager.currentLocation {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.blue)
                        Text("ຕຳແໜ່ງຂອງຂ້ອຍ: \(currentLocation.coordinate.latitude, specifier: "%.4f"), \(currentLocation.coordinate.longitude, specifier: "%.4f")")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                if let lat = delivery.customerLatitude, let lng = delivery.customerLongitude {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.red)
                        Text("ປາຍທາງ: \(lat, specifier: "%.4f"), \(lng, specifier: "%.4f")")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Status Action Buttons
struct StatusActionButtons: View {
    @EnvironmentObject var apiService: APIService
    
    let delivery: Delivery
    @Binding var isUpdatingStatus: Bool
    @Binding var showingNavigationOptions: Bool
    @Binding var showingPhotoCapture: Bool
    @Binding var deliveryProofImage: UIImage?
    
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 12) {
            switch delivery.status.lowercased() {
            case "pending", "preparing":
                Button(action: { updateStatus(to: "out_for_delivery") }) {
                    ActionButtonContent(
                        icon: "bicycle",
                        text: "ຮັບອໍເດີ້ແລ້ວ",
                        isLoading: isUpdatingStatus,
                        colors: [.orange, .pink]
                    )
                }
                .disabled(isUpdatingStatus)

            case "out_for_delivery":
                VStack(spacing: 12) {
                    Button(action: { showingNavigationOptions = true }) {
                        ActionButtonContent(
                            icon: "map.fill",
                            text: "ເປີດແຜນທີ່ນຳທາງ",
                            colors: [.blue, .cyan]
                        )
                    }
                    
                    Button(action: { showingPhotoCapture = true }) {
                        ActionButtonContent(
                            icon: "camera.fill",
                            text: "ຖ່າຍຮູບຢືນຢັນ",
                            colors: [.purple, .pink]
                        )
                    }

                    Button(action: { updateStatus(to: "delivered") }) {
                        ActionButtonContent(
                            icon: "checkmark.circle.fill",
                            text: "ຢືນຢັນສົ່ງສຳເລັດ",
                            isLoading: isUpdatingStatus,
                            colors: [.green, .mint]
                        )
                    }
                    .disabled(isUpdatingStatus)
                }
                
            case "delivered":
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                    Text("ວຽກນີ້ສຳເລັດແລ້ວ")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(.green.opacity(0.1))
                .cornerRadius(16)
                
            default:
                EmptyView()
            }
        }
    }
    
    private func updateStatus(to newStatus: String) {
        isUpdatingStatus = true
        
        apiService.updateDeliveryStatus(
            deliveryId: delivery.id,
            status: newStatus,
            notes: newStatus == "delivered" ? "ສົ່ງສຳເລັດແລ້ວ" : nil
        )
        .sink(
            receiveCompletion: { completion in
                DispatchQueue.main.async {
                    self.isUpdatingStatus = false
                    
                    if case .failure(let error) = completion {
                        print("Failed to update status: \(error)")
                        // TODO: Show error alert
                    }
                }
            },
            receiveValue: { updatedDelivery in
                DispatchQueue.main.async {
                    self.isUpdatingStatus = false
                    print("Status updated successfully to: \(updatedDelivery.status)")
                    
                    // Update location if going out for delivery
                    if newStatus == "out_for_delivery" {
                        self.startLocationTracking()
                    }
                }
            }
        )
        .store(in: &cancellables)
    }
    
    private func startLocationTracking() {
        // Start location tracking when going out for delivery
        MapBoxManager.shared.startLocationUpdates()
    }
}

// MARK: - Action Button Content
struct ActionButtonContent: View {
    let icon: String
    let text: String
    var isLoading: Bool = false
    let colors: [Color]
    
    var body: some View {
        HStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
            }
            
            Text(isLoading ? "ກຳລັງອັບເດດ..." : text)
                .font(.system(size: 18, weight: .bold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(
            LinearGradient(
                colors: colors,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .shadow(color: colors.first?.opacity(0.3) ?? .clear, radius: 10, x: 0, y: 5)
    }
}

// MARK: - API Info Row
struct ApiInfoRow: View {
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
                    .lineLimit(nil)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Photo Capture View
struct PhotoCaptureView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoCaptureView
        
        init(_ parent: PhotoCaptureView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
