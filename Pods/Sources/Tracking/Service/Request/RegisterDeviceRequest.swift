import Foundation

// https://customer.io/docs/api/#operation/add_device
public struct RegisterDeviceRequest<T: Encodable>: Encodable {
    public let device: Device<T>

    public init(device: Device<T>) {
        self.device = device
    }
}
