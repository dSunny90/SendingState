//
//  RealWorldScenariosTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 26.06.2023.
//

import XCTest
@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
final class RealWorldScenariosTests: XCTestCase {
    var handler: TestActionHandler!

    override func setUp() {
        super.setUp()
        handler = TestActionHandler()
    }

    override func tearDown() {
        handler = nil
        super.tearDown()
    }

    // MARK: - List Scenarios

    /// Scenario: TableView cell binding with multiple items
    func test_tableView_cellBinding_withMultipleItems() {
        // Given: Simulate TableView cell pattern
        class ProductCell: UITableViewCell, EventForwardingProvider, Configurable {
            struct Model: Equatable, Sendable {
                let id: Int
                let name: String
                let price: Double
            }

            let cartButton = UIButton()
            let clipButton = UIButton()
            var lastModel: Model?
            var configureCount = 0

            var configurer: (ProductCell, Model) -> Void {
                { cell, model in
                    cell.lastModel = model
                    cell.configureCount += 1
                    cell.cartButton.tag = model.id
                    cell.clipButton.tag = model.id
                }
            }

            var eventForwarder: EventForwardable {
                SenderGroup {
                    EventForwarder(cartButton) { sender, ctx in
                        ctx.control(.touchUpInside) {
                            [TestAction.custom("cart_\(sender.tag)")]
                        }
                    }
                    EventForwarder(clipButton) { sender, ctx in
                        ctx.control(.touchUpInside) {
                            [TestAction.custom("clip_\(sender.tag)")]
                        }
                    }
                }
            }

            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                contentView.addSubview(cartButton)
                contentView.addSubview(clipButton)
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }

        let products = [
            ProductCell.Model(id: 1, name: "iPhone", price: 1290000),
            ProductCell.Model(id: 2, name: "iPad Pro", price: 1599000),
            ProductCell.Model(id: 3, name: "MacBook Pro", price: 2390000)
        ]

        var cells: [ProductCell] = []
        for product in products {
            let cell = ProductCell(style: .default, reuseIdentifier: "Product")
            cell.ss.configure(product)
            cell.ss.addActionHandler(to: handler)
            cells.append(cell)
        }

        // When: Simulate user tapping cart on second product
        TestActionTrigger.simulateControl(cells[1].cartButton, for: .touchUpInside)

        // Then: Assert action handled correctly
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .custom("cart_2"))
    }

    /// Scenario: CollectionView dynamic updates
    func test_collectionView_dynamicUpdates() {
        // Given
        class ImageCell: UICollectionViewCell, EventForwardingProvider, Configurable {
            struct Model: Sendable {
                let imageId: Int
                let isSelected: Bool
            }

            let selectButton = UIButton()
            var lastModel: Model?

            var configurer: (ImageCell, Model) -> Void {
                { cell, model in
                    cell.lastModel = model
                    cell.selectButton.tag = model.imageId
                    cell.selectButton.isSelected = model.isSelected
                }
            }

            var eventForwarder: EventForwardable {
                EventForwarder(selectButton) { sender, ctx in
                    ctx.control(.touchUpInside) {
                        [TestAction.custom("select_\(sender.tag)")]
                    }
                }
            }

            override init(frame: CGRect) {
                super.init(frame: frame)
                contentView.addSubview(selectButton)
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }

        let cell = ImageCell()
        cell.ss.configure(ImageCell.Model(imageId: 90, isSelected: false))
        cell.ss.addActionHandler(to: handler)

        XCTAssertEqual(cell.lastModel?.imageId, 90)
        XCTAssertFalse(cell.lastModel?.isSelected ?? true)

        // When: Update state (simulating selection)
        cell.ss.configure(ImageCell.Model(imageId: 90, isSelected: true))

        // Then: Assert selection state updated
        XCTAssertTrue(cell.lastModel?.isSelected ?? false)

        // When: Tap to toggle selection
        TestActionTrigger.simulateControl(cell.selectButton, for: .touchUpInside)

        // Then: Assert action received
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .custom("select_90"))
    }

    // MARK: - Form Scenarios

    /// Scenario: User input → validation → submission
    func test_form_inputValidationAndSubmission() {
        // Given
        class LoginFormView: UIView, EventForwardingProvider {
            let usernameField = UITextField()
            let passwordField = UITextField()
            let submitButton = UIButton()

            var isValid: Bool {
                let username = usernameField.text ?? ""
                let password = passwordField.text ?? ""
                return username.count >= 4 && password.count >= 10
            }

            var eventForwarder: EventForwardable {
                SenderGroup {
                    EventForwarder(usernameField) { _, ctx in
                        ctx.control(.editingChanged) {
                            [TestAction.custom("username_changed")]
                        }
                    }
                    EventForwarder(passwordField) { _, ctx in
                        ctx.control(.editingChanged) {
                            [TestAction.custom("password_changed")]
                        }
                    }
                    EventForwarder(submitButton) { [weak self] _, ctx in
                        ctx.control(.touchUpInside) {
                            guard let self = self else { return [] }
                            if self.isValid {
                                return [TestAction.custom("submit_valid")]
                            } else {
                                return [TestAction.custom("submit_invalid")]
                            }
                        }
                    }
                }
            }
        }

        let form = LoginFormView()
        form.ss.addActionHandler(to: handler)

        // When: Try submit with invalid data
        TestActionTrigger.simulateTextField(form.usernameField, text: "SSG")
        TestActionTrigger.simulateTextField(form.passwordField, text: "1q2w3e4r")
        TestActionTrigger.simulateControl(form.submitButton, for: .touchUpInside)

        // Then: Assert submission invalid
        XCTAssertEqual(handler.handledActions.last, .custom("submit_invalid"))

        // When: Fix the data
        TestActionTrigger.simulateTextField(form.usernameField, text: "Jeon")
        TestActionTrigger.simulateTextField(form.passwordField, text: "password1q2w3e4r")

        // When: Submit again
        TestActionTrigger.simulateControl(form.submitButton, for: .touchUpInside)

        // Then: Assert submission valid
        XCTAssertEqual(handler.handledActions.last, .custom("submit_valid"))
    }

    /// Scenario: Dependent fields (password + confirmation)
    func test_form_dependentFields() {
        // Given
        class PasswordFormView: UIView, EventForwardingProvider {
            let passwordField = UITextField()
            let confirmField = UITextField()
            let strengthIndicator = UIProgressView()

            var passwordsMatch: Bool {
                let password = passwordField.text ?? ""
                let confirm = confirmField.text ?? ""
                return !password.isEmpty && password == confirm
            }

            var passwordStrength: Float {
                let password = passwordField.text ?? ""
                if password.count < 6 { return 0.25 }
                if password.count < 10 { return 0.5 }
                if password.count < 14 { return 0.75 }
                return 1.0
            }

            var eventForwarder: EventForwardable {
                SenderGroup {
                    EventForwarder(passwordField) { [weak self] _, ctx in
                        ctx.control(.editingChanged) {
                            guard let self = self else { return [] }
                            return [
                                TestAction.sliderChanged(self.passwordStrength)
                            ]
                        }
                    }
                    EventForwarder(confirmField) { [weak self] _, ctx in
                        ctx.control(.editingChanged) {
                            guard let self = self else { return [] }
                            if self.passwordsMatch {
                                return [TestAction.custom("passwords_match")]
                            } else {
                                return [TestAction.custom("passwords_differ")]
                            }
                        }
                    }
                }
            }
        }

        let form = PasswordFormView()
        form.ss.addActionHandler(to: handler)

        // When: Enter password
        TestActionTrigger.simulateTextField(form.passwordField, text: "mypass")

        // Then: Assert strength indicator
        if case .sliderChanged(let strength) = handler.handledActions.last {
            XCTAssertEqual(strength, 0.5, accuracy: 0.01) // 10 chars
        } else {
            XCTFail("Expected sliderChanged action")
        }

        // When: Enter non-matching confirmation
        TestActionTrigger.simulateTextField(form.confirmField, text: "different")

        // Then: Assert passwords differ
        XCTAssertEqual(handler.handledActions.last, .custom("passwords_differ"))

        // When: Fix confirmation
        TestActionTrigger.simulateTextField(form.confirmField, text: "mypass")

        // Then: Assert passwords match
        XCTAssertEqual(handler.handledActions.last, .custom("passwords_match"))
    }

    // MARK: - Navigation Scenarios

    /// Scenario: Front-Detail data flow
    func test_frontDetail_dataFlow() {
        // Given
        struct Item: Equatable, Sendable {
            let id: Int
            let title: String
            let origin: String
        }

        class FrontCell: UITableViewCell, EventForwardingProvider, Configurable {
            let selectButton = UIButton()
            var currentItem: Item?

            var configurer: (FrontCell, Item) -> Void {
                { cell, item in
                    cell.currentItem = item
                    cell.selectButton.tag = item.id
                }
            }

            var eventForwarder: EventForwardable {
                EventForwarder(selectButton) { sender, ctx in
                    ctx.control(.touchUpInside) {
                        [TestAction.buttonTapped(sender.tag)]
                    }
                }
            }
        }

        class DetailView: UIView, Configurable {
            var displayedItem: Item?
            var configureCount = 0

            var configurer: (DetailView, Item) -> Void {
                { view, item in
                    view.displayedItem = item
                    view.configureCount += 1
                }
            }
        }

        let items = [
            Item(id: 64, title: "Wine", origin: "Italy"),
            Item(id: 69, title: "Beer", origin: "Germany"),
            Item(id: 74, title: "Soju", origin: "Korea")
        ]

        let frontCells = items.map { item -> FrontCell in
            let cell = FrontCell()
            cell.ss.configure(item)
            cell.ss.addActionHandler(to: handler)
            return cell
        }

        // When: User selects second item
        TestActionTrigger.simulateControl(frontCells[1].selectButton, for: .touchUpInside)

        // Then: Assert action received
        XCTAssertEqual(handler.handledActions.count, 1)
        XCTAssertEqual(handler.handledActions.first, .buttonTapped(69))

        // When: Simulate detail view update
        let detailView = DetailView()
        if let selectedId = handler.handledActions.first?.extractButtonTag(),
           let selectedItem = items.first(where: { $0.id == selectedId }) {
            detailView.ss.configure(selectedItem)
        }

        // Then: Assert detail view updated accordingly
        XCTAssertEqual(detailView.displayedItem?.title, "Beer")
        XCTAssertEqual(detailView.displayedItem?.origin, "Germany")
    }

    // MARK: - Complex Binding

    /// Scenario: Multiple Boundables on single view
    func test_multipleBindables_onSingleView() {
        // Given
        class ProfileView: UIView, Configurable {
            struct UserModel: Sendable {
                let name: String
                let bio: String
            }

            var userName: String?
            var userBio: String?
            var configureCount = 0

            var configurer: (ProfileView, UserModel) -> Void {
                { view, model in
                    view.userName = model.name
                    view.userBio = model.bio
                    view.configureCount += 1
                }
            }
        }

        struct UserBoundable: Boundable {
            var contentData: ProfileView.UserModel?
            var binderType: ProfileView.Type { ProfileView.self }
        }

        let view = ProfileView()

        // When: Configure with first user
        let user1 = UserBoundable(
            contentData: ProfileView.UserModel(name: "Sunny", bio: "iOS Developer")
        )
        user1.apply(to: view)

        // Then: Assert first user data applied
        XCTAssertEqual(view.userName, "Sunny")

        // When: Reconfigure with second user
        let user2 = UserBoundable(
            contentData: ProfileView.UserModel(name: "Sherin", bio: "Product Manager")
        )
        user2.apply(to: view)

        // Then: Assert second user data applied
        XCTAssertEqual(view.userName, "Sherin")
        XCTAssertEqual(view.userBio, "Product Manager")
    }

    /// Scenario: Nested view hierarchy binding
    func test_nestedViews_binding() {
        // Given: Parent with child views
        class ParentView: UIView, EventForwardingProvider {
            let headerView = HeaderView()
            let contentView = ContentView()
            let footerView = FooterView()

            var eventForwarder: EventForwardable {
                SenderGroup {
                    headerView.eventForwarder
                    contentView.eventForwarder
                    footerView.eventForwarder
                }
            }

            class HeaderView: UIView, EventForwardingProvider {
                let backButton = UIButton()
                let menuButton = UIButton()

                var eventForwarder: EventForwardable {
                    SenderGroup {
                        EventForwarder(backButton) { _, ctx in
                            ctx.control(.touchUpInside) {
                                [TestAction.custom("back")]
                            }
                        }
                        EventForwarder(menuButton) { _, ctx in
                            ctx.control(.touchUpInside) {
                                [TestAction.custom("menu")]
                            }
                        }
                    }
                }
            }

            class ContentView: UIView, EventForwardingProvider {
                let actionButton = UIButton()

                var eventForwarder: EventForwardable {
                    EventForwarder(actionButton) { _, ctx in
                        ctx.control(.touchUpInside) {
                            [TestAction.custom("action")]
                        }
                    }
                }
            }

            class FooterView: UIView, EventForwardingProvider {
                let shareButton = UIButton()

                var eventForwarder: EventForwardable {
                    EventForwarder(shareButton) { _, ctx in
                        ctx.control(.touchUpInside) {
                            [TestAction.custom("share")]
                        }
                    }
                }
            }
        }

        let parent = ParentView()
        parent.ss.addActionHandler(to: handler)

        // When: Trigger events from different nested views
        TestActionTrigger.simulateControl(parent.headerView.backButton, for: .touchUpInside)
        TestActionTrigger.simulateControl(parent.contentView.actionButton, for: .touchUpInside)
        TestActionTrigger.simulateControl(parent.footerView.shareButton, for: .touchUpInside)
        TestActionTrigger.simulateControl(parent.headerView.menuButton, for: .touchUpInside)

        // Then: Assert all actions received in order
        XCTAssertEqual(handler.handledActions.count, 4)
        XCTAssertEqual(handler.handledActions[0], .custom("back"))
        XCTAssertEqual(handler.handledActions[1], .custom("action"))
        XCTAssertEqual(handler.handledActions[2], .custom("share"))
        XCTAssertEqual(handler.handledActions[3], .custom("menu"))
    }

    // MARK: - Real-World App Patterns

    /// Scenario: Shopping cart with quantity controls
    func test_shoppingCart_quantityControls() {
        // Given
        class CartItemCell: UITableViewCell, EventForwardingProvider, Configurable {
            struct Model: Equatable, Sendable {
                let productId: Int
                let name: String
                var quantity: Int
            }

            let minusButton = UIButton()
            let plusButton = UIButton()
            let removeButton = UIButton()
            var currentModel: Model?

            var configurer: (CartItemCell, Model) -> Void {
                { cell, model in
                    cell.currentModel = model
                    cell.minusButton.tag = model.productId
                    cell.plusButton.tag = model.productId
                    cell.removeButton.tag = model.productId
                }
            }

            var eventForwarder: EventForwardable {
                SenderGroup {
                    EventForwarder(minusButton) { sender, ctx in
                        ctx.control(.touchUpInside) {
                            [TestAction.custom("decrease_\(sender.tag)")]
                        }
                    }
                    EventForwarder(plusButton) { sender, ctx in
                        ctx.control(.touchUpInside) {
                            [TestAction.custom("increase_\(sender.tag)")]
                        }
                    }
                    EventForwarder(removeButton) { sender, ctx in
                        ctx.control(.touchUpInside) {
                            [TestAction.custom("remove_\(sender.tag)")]
                        }
                    }
                }
            }
        }

        let cell = CartItemCell()
        cell.ss.configure(CartItemCell.Model(productId: 119, name: "Milk", quantity: 2))
        cell.ss.addActionHandler(to: handler)

        // When: User interactions
        TestActionTrigger.simulateControl(cell.plusButton, for: .touchUpInside)
        TestActionTrigger.simulateControl(cell.plusButton, for: .touchUpInside)
        TestActionTrigger.simulateControl(cell.minusButton, for: .touchUpInside)

        // Then: Assert actions handled correctly
        XCTAssertEqual(handler.handledActions.count, 3)
        XCTAssertEqual(handler.handledActions[0], .custom("increase_119"))
        XCTAssertEqual(handler.handledActions[1], .custom("increase_119"))
        XCTAssertEqual(handler.handledActions[2], .custom("decrease_119"))
    }

    /// Scenario: Media player controls
    func test_mediaPlayer_controls() {
        // Given
        class PlayerControlsView: UIView, EventForwardingProvider {
            let playPauseButton = UIButton()
            let skipBackButton = UIButton()
            let skipForwardButton = UIButton()
            let progressSlider = UISlider()
            let volumeSlider = UISlider()
            let fullscreenButton = UIButton()

            var eventForwarder: EventForwardable {
                SenderGroup {
                    EventForwarder(playPauseButton) { _, ctx in
                        ctx.control(.touchUpInside) {
                            [TestAction.custom("playPause")]
                        }
                    }
                    EventForwarder(skipBackButton) { _, ctx in
                        ctx.control(.touchUpInside) {
                            [TestAction.custom("skipBack")]
                        }
                    }
                    EventForwarder(skipForwardButton) { _, ctx in
                        ctx.control(.touchUpInside) {
                            [TestAction.custom("skipForward")]
                        }
                    }
                    EventForwarder(progressSlider) { sender, ctx in
                        ctx.control(.valueChanged) {
                            [TestAction.sliderChanged(sender.value)]
                        }
                    }
                    EventForwarder(volumeSlider) { sender, ctx in
                        ctx.control(.valueChanged) {
                            [TestAction.custom("volume_\(Int(sender.value * 100))")]
                        }
                    }
                    EventForwarder(fullscreenButton) { _, ctx in
                        ctx.control(.touchUpInside) {
                            [TestAction.custom("fullscreen")]
                        }
                    }
                }
            }
        }

        let player = PlayerControlsView()
        player.ss.addActionHandler(to: handler)

        // When: Simulate typical usage
        TestActionTrigger.simulateControl(player.playPauseButton, for: .touchUpInside) // Start
        TestActionTrigger.simulateSlider(player.progressSlider, value: 0.1) // Seek
        TestActionTrigger.simulateControl(player.skipForwardButton, for: .touchUpInside) // Skip
        TestActionTrigger.simulateSlider(player.volumeSlider, value: 0.7) // Volume
        TestActionTrigger.simulateControl(player.fullscreenButton, for: .touchUpInside) // Fullscreen

        // Then: Assert all actions received correctly
        XCTAssertEqual(handler.handledActions.count, 5)
        XCTAssertEqual(handler.handledActions[0], .custom("playPause"))

        if case .sliderChanged(let value) = handler.handledActions[1] {
            XCTAssertEqual(value, 0.1, accuracy: 0.01)
        } else {
            XCTFail("Expected sliderChanged")
        }

        XCTAssertEqual(handler.handledActions[2], .custom("skipForward"))
        XCTAssertEqual(handler.handledActions[3], .custom("volume_70"))
        XCTAssertEqual(handler.handledActions[4], .custom("fullscreen"))
    }
}
#endif
