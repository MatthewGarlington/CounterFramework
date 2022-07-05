import SwiftUI
import ComposableArchitecture
import PrimeModal


public enum CounterAction {
    case decrCount
    case incrCount
}



public func counterReducer(state: inout Int, action: CounterAction) {
    switch action {
    case .decrCount:
        state -= 1
    case .incrCount:
        state += 1
    }
}




typealias CounterViewState = (count: Int, favorites: [Int])

public enum CounterViewAction {
    case counter(CounterAction)
    case primeModal(PrimeModalAction)
}

public struct CounterView: View {
    @ObservedObject var store: Store<CounterViewState, CounterViewAction>
    @State private var nthPrimeAlert: Int?
    @State private var showModal: Bool = false
    @State private var showAlert: Bool = false
    
    public init(store: Store<CounterViewState, CounterViewAction>) {
        self.store = store
    }
    public var body: some View {
        VStack {
            HStack {
                Button { store.send(.counter(.decrCount))} label: { Text("-") }
                
                Text("\(store.value.count)")
                
                Button { store.send(.counter(.incrCount))} label: { Text("+") }
            }
            
            Button { showModal = true } label: {
                Text("Is this  Prime?")
            }
            
            Button {
                showAlert = true
                nthPrime(store.value.count) { prime in
                    nthPrimeAlert = prime
                }
            } label: {
                Text("What is the \(store.value.count)th prime?")
            }
        }
        .font(.title)
        .navigationTitle(Text("Counter demo"))
        .sheet(isPresented: $showModal) {
            PrimeModal(store: store.view(
                value: { .init(count: $0.count, favorites: $0.favorites) },
                action: { .primeModal($0) })
            )
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(""),
                  message: Text("The \(store.value.count)th prime is \(nthPrimeAlert ?? 0)"),
                  dismissButton: .cancel()
            )
        }
    }
}


func nthPrime(_ n: Int, callback: @escaping (Int?) -> Void) -> Void {
  wolframAlpha(query: "prime \(n)") { result in
    callback(
      result
        .flatMap {
          $0.queryresult
            .pods
            .first(where: { $0.primary == .some(true) })?
            .subpods
            .first?
            .plaintext
        }
        .flatMap(Int.init)
    )
  }
}

func wolframAlpha(query: String, callback: @escaping (WolframAlphaResult?) -> Void) -> Void {
  var components = URLComponents(string: "https://api.wolframalpha.com/v2/query")!
  components.queryItems = [
    URLQueryItem(name: "input", value: query),
    URLQueryItem(name: "format", value: "plaintext"),
    URLQueryItem(name: "output", value: "JSON"),
    URLQueryItem(name: "appid", value: wolframAlphaApiKey),
  ]

  URLSession.shared.dataTask(with: components.url(relativeTo: nil)!) { data, response, error in
    callback(
      data
        .flatMap { try? JSONDecoder().decode(WolframAlphaResult.self, from: $0) }
    )
    }
    .resume()
}


let wolframAlphaApiKey = "3G2GYG-WW3Y23KA7W"

//struct CounterView_Previews: PreviewProvider {
//    static var previews: some View {
//        CounterView(store: .init(initialValue: AppState(), reducer: appReducer))
//    }
//}

