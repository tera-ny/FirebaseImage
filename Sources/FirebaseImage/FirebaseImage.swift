import SwiftUI
import Combine
import FirebaseStorage

extension StorageReference {
    struct DownloadURLPublisher: Publisher {
        typealias Output = URL
        typealias Failure = Error
        let reference: StorageReference
        func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            reference.downloadURL { (url, error) in
                if let url = url {
                    _ = subscriber.receive(url)
                    subscriber.receive(completion: .finished)
                } else if let error = error {
                    subscriber.receive(completion: .failure(error))
                }
            }
        }
    }
    var downloadURLPublisher: DownloadURLPublisher {
        DownloadURLPublisher(reference: self)
    }
}

class ImageCache {
    var jar: [String: UIImage] = [:]
    static let shared: ImageCache = .init()
}

class FirebaseImageViewModel: ObservableObject {
    @Published var image: Result<UIImage, Error>?
    private var disposeBag = Set<AnyCancellable>()
    init(reference: StorageReference, useCache: Bool) {
        if useCache, let image = ImageCache.shared.jar[reference.fullPath] {
            self.image = .success(image)
            return
        } else {
            reference.downloadURLPublisher
                .flatMap({ url in
                    URLSession.shared.dataTaskPublisher(for: url)
                        .mapError({ $0 })
                })
                .sink { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        #if DEBUG
                        print(error)
                        #endif
                        ImageCache.shared.jar.removeValue(forKey: reference.fullPath)
                        self?.image = .failure(error)
                    default: break
                    }
                } receiveValue: { [weak self] result in
                    if let image = UIImage(data: result.data) {
                        ImageCache.shared.jar.updateValue(image, forKey: reference.fullPath)
                        self?.image = .success(image)
                    }
                }
                .store(in: &disposeBag)
        }
    }
    var wrappedImage: UIImage? {
        switch image {
        case .success(let image):
            return image
        //Todo: failed to load
        default:
            return nil
        }
    }
}

public struct FirebaseImage: View {
    @ObservedObject private var viewModel: FirebaseImageViewModel
    private let placeholder: UIImage
    init(reference: StorageReference, useCache: Bool = true, placeholder: UIImage = .init()) {
        viewModel = .init(reference: reference, useCache: useCache)
        self.placeholder = placeholder
    }
    public var body: Image {
        Image(uiImage: viewModel.wrappedImage ?? placeholder)
    }
}
