# FirebaseImage

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
