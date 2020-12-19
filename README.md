# FirebaseImage

## Installation
```swift
.package(name: "FirebaseImage", url: "https://github.com/tera-ny/FirebaseImage.git", from: "0.1.2"),
```

## Usage
```swift
struct ContentView: View {
    let reference: StorageReference
    var body: some View {
        FirebaseImage(reference: reference)
            .scaledToFill()
    }
}
```
