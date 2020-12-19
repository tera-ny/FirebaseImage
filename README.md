# FirebaseImage

## Installation
```swift
.package(name: "FirebaseImage", url: "https://github.com/tera-ny/FirebaseImage.git", from: "0.1.3"),
```

## Usage
```swift
struct ContentView: View {
    let reference: StorageReference
    var body: some View {
        FirebaseImage(reference: Storage.storage().reference()) {
            $0.resizable()
                .scaledToFit()
                .frame(width: 100)
        }
    }
}
```
