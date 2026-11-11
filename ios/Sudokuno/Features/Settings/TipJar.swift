import Observation
import StoreKit
import SwiftUI

/// Pot à pourboires : dons facultatifs en achat intégré « consommable ». Ils ne débloquent rien.
/// Identifiants à créer à l'identique dans App Store Connect (voir docs/IN_APP_PURCHASES.md).
@Observable
final class TipJar {
    enum Tip: String, CaseIterable {
        case small = "com.alexafer.sudokuno.tip.small"
        case medium = "com.alexafer.sudokuno.tip.medium"
        case large = "com.alexafer.sudokuno.tip.large"

        var emoji: String {
            switch self {
            case .small: "☕️"
            case .medium: "☕️☕️"
            case .large: "☕️🥐"
            }
        }

        /// Nom traduit dans la langue choisie dans l'app (le nom App Store suit la langue du compte).
        var name: String {
            switch self {
            case .small: L("Petit café")
            case .medium: L("Grand café")
            case .large: L("Café et croissant")
            }
        }
    }

    enum Status: Equatable {
        case idle
        case purchasing(String)
        case thanked
        case pending
        case failed
    }

    private(set) var products: [Product] = []
    private(set) var loaded = false
    var status: Status = .idle
    private(set) var tipCount = UserDefaults.standard.integer(forKey: "tipCount")

    private var updates: Task<Void, Never>?

    /// À lancer au démarrage : termine les transactions arrivées en dehors de l'app (paiement validé plus tard).
    func start() {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    self?.recordTip()
                }
            }
        }
    }

    func load() async {
        guard !loaded else { return }
        do {
            let fetched = try await Product.products(for: Tip.allCases.map(\.rawValue))
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            products = []
        }
        loaded = true
    }

    /// Quantité maximale par achat autorisée par l'App Store pour un consommable.
    static let maxQuantity = 10
    static let customID = "custom"

    /// `quantity` > 1 : « montant libre » (plusieurs cafés payés en une fois).
    func buy(_ product: Product, quantity: Int = 1, statusID: String? = nil) async {
        status = .purchasing(statusID ?? product.id)
        do {
            let options: Set<Product.PurchaseOption> = quantity > 1 ? [.quantity(quantity)] : []
            switch try await product.purchase(options: options) {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    recordTip()
                    status = .thanked
                } else {
                    status = .failed
                }
            case .pending:
                status = .pending
            case .userCancelled:
                status = .idle
            @unknown default:
                status = .idle
            }
        } catch {
            status = .failed
        }
    }

    private func recordTip() {
        tipCount += 1
        UserDefaults.standard.set(tipCount, forKey: "tipCount")
    }
}

/// Section « Soutenir Sudokuno » des réglages.
struct TipJarSection: View {
    @Environment(AppModel.self) private var model
    @State private var quantity = 3

    var body: some View {
        let jar = model.tipJar
        Section {
            if !jar.loaded {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else if jar.products.isEmpty {
                Text(L("Dons indisponibles pour le moment."))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(jar.products, id: \.id) { product in
                    let tip = TipJar.Tip(rawValue: product.id)
                    HStack(spacing: 12) {
                        Text(tip?.emoji ?? "💜").font(.title2)
                        Text(tip?.name ?? product.displayName)
                        Spacer()
                        Button {
                            Task { await jar.buy(product) }
                        } label: {
                            if jar.status == .purchasing(product.id) {
                                ProgressView()
                            } else {
                                Text(product.displayPrice).monospacedDigit()
                            }
                        }
                        .buttonStyle(.glassProminent)
                        .tint(Palette.accentStrong)
                        .disabled(isBusy(jar))
                        .accessibilityIdentifier("tip-\(product.id)")
                    }
                }
            }
            if let coffee = jar.products.first(where: { $0.id == TipJar.Tip.small.rawValue }) {
                customAmount(jar, coffee)
            }
            if jar.tipCount > 0 {
                Label(L("Tu as fait %lld dons. Merci ! 💜", jar.tipCount), systemImage: "heart.fill")
                    .foregroundStyle(Palette.accent)
            }
        } header: {
            Text(L("Soutenir Sudokuno"))
        } footer: {
            Text(L("Sudokuno est gratuit et sans publicité. Un don facultatif aide à financer son développement, il ne débloque rien. Merci !"))
        }
        .task { await jar.load() }
        .alert(alertTitle(jar.status), isPresented: Binding(
            get: { [.thanked, .pending, .failed].contains(jar.status) },
            set: { if !$0 { jar.status = .idle } }
        )) {
            Button(L("OK"), role: .cancel) { jar.status = .idle }
        } message: {
            Text(alertMessage(jar.status))
        }
    }

    /// Montant libre : 1 à 10 petits cafés, payés en un seul achat.
    private func customAmount(_ jar: TipJar, _ coffee: Product) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("Montant libre")).font(.headline)
            HStack {
                Text("☕️ × \(quantity)")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Spacer()
                Text((coffee.price * Decimal(quantity)).formatted(coffee.priceFormatStyle))
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("customTotal")
            }
            HStack {
                Stepper(L("%lld cafés", quantity), value: $quantity.animation(.snappy), in: 1...TipJar.maxQuantity)
                    .labelsHidden()
                    .accessibilityLabel(L("%lld cafés", quantity))
                    .accessibilityIdentifier("customStepper")
                Spacer()
                Button {
                    Task { await jar.buy(coffee, quantity: quantity, statusID: TipJar.customID) }
                } label: {
                    if jar.status == .purchasing(TipJar.customID) {
                        ProgressView()
                    } else {
                        Text(L("Offrir"))
                    }
                }
                .buttonStyle(.glassProminent)
                .tint(Palette.accentStrong)
                .disabled(isBusy(jar))
                .accessibilityIdentifier("customTip")
            }
            Text(L("Choisis combien de cafés offrir, jusqu'à %lld en une fois.", TipJar.maxQuantity))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func isBusy(_ jar: TipJar) -> Bool {
        if case .purchasing = jar.status { return true }
        return false
    }

    private func alertTitle(_ status: TipJar.Status) -> String {
        switch status {
        case .thanked: L("Merci ! 💜")
        case .pending: L("Paiement en attente")
        default: L("Don non effectué")
        }
    }

    private func alertMessage(_ status: TipJar.Status) -> String {
        switch status {
        case .thanked: L("Ton soutien compte beaucoup pour Sudokuno.")
        case .pending: L("Le paiement doit encore être validé. Merci de ta patience !")
        default: L("L'achat n'a pas pu aboutir. Aucun montant n'a été débité.")
        }
    }
}
