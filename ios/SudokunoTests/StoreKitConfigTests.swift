import StoreKit
import StoreKitTest
import XCTest

/// Vérifie le fichier Tips.storekit dans le processus de test : identifiants, prix et achat d'un don.
final class StoreKitConfigTests: XCTestCase {
    func testTipProductsAndPurchase() async throws {
        let session = try SKTestSession(configurationFileNamed: "Tips")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true

        let ids = ["com.alexafer.sudokuno.tip.small", "com.alexafer.sudokuno.tip.medium", "com.alexafer.sudokuno.tip.large"]
        let products = try await Product.products(for: ids).sorted { $0.price < $1.price }
        // En ligne de commande (xcodebuild), la session StoreKit de test n'est pas toujours active : lancer avec ⌘U dans Xcode.
        if products.isEmpty { throw XCTSkip("StoreKit de test inactif dans cet environnement") }
        XCTAssertEqual(products.map(\.id), ids)
        XCTAssertEqual(products.map(\.price), [Decimal(string: "0.99")!, Decimal(string: "2.99")!, Decimal(string: "4.99")!])
        XCTAssertTrue(products.allSatisfy { $0.type == .consumable })

        let result = try await products[0].purchase()
        guard case .success(let verification) = result, case .verified(let transaction) = verification else {
            return XCTFail("Achat attendu : \(result)")
        }
        XCTAssertEqual(transaction.productID, ids[0])
        await transaction.finish()

        // Montant libre : 3 petits cafés en un seul achat.
        let multi = try await products[0].purchase(options: [.quantity(3)])
        guard case .success(let v2) = multi, case .verified(let t2) = v2 else { return XCTFail("Achat multiple attendu") }
        XCTAssertEqual(t2.purchasedQuantity, 3)
        await t2.finish()
    }
}
