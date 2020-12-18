import SwiftUI
import Combine
import FirebaseStorage

extension StorageReference {
    struct DownloadURLPublisher: Publisher {
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
    var disposeBag = Set<AnyCancellable>()
    init(reference: StorageReference, useCache: Bool) {
        if useCache, let image = ImageCache.shared.jar[reference.fullPath] {
            self.image = .success(image)
            return
        } else {
            reference.downloadURLPublisher
                .flatMap({ url -> AnyPublisher<Data, Error> in
                    URLSession.shared.dataTaskPublisher(for: url)
                        .map({ $0.data })
                        .mapError({ $0 })
                        .eraseToAnyPublisher()
                })
                .sink { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        ImageCache.shared.jar.removeValue(forKey: reference.fullPath)
                        self?.image = .failure(error)
                    default: break
                    }
                } receiveValue: { [weak self] data in
                    if let image = UIImage(data: data) {
                        ImageCache.shared.jar.updateValue(image, forKey: reference.fullPath)
                        self?.image = .success(image)
                    }
                }
                .store(in: &disposeBag)
        }
    }
    var wrappedImage: UIImage {
        switch image {
        case .success(let image):
            return image
        //Todo: placeholder, failed to load
        default:
            return UIImage()
        }
    }
}

struct FirebaseImage: View {
    @ObservedObject var viewModel: FirebaseImageViewModel
    init(reference: StorageReference, useCache: Bool = true) {
        viewModel = .init(reference: reference, useCache: useCache)
    }
    var body: Image {
        Image(uiImage: viewModel.wrappedImage)
    }
}
