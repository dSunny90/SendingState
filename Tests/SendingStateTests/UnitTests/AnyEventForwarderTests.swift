//
//  AnyEventForwarderTests.swift
//  SendingState
//
//  Created by SunSoo Jeon on 23.06.2023.
//

import XCTest
@testable import SendingState

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

@MainActor
final class AnyEventForwarderTests: XCTestCase {
    // MARK: - Type Erasure

    func test_any_event_forwarder_wraps_concrete_forwarder() {
        // Given
        let button = TestFixture.makeButton(tag: 11)
        let forwarder = EventForwarder(button) { sender, ctx in
            ctx.control(.touchUpInside) {
                [TestAction.buttonTapped(sender.tag)]
            }
        }

        // When
        let anyForwarder = AnyEventForwarder(forwarder)

        // Then
        XCTAssertEqual(anyForwarder.allMappings.count, 1)
    }

    func test_any_event_forwarder_forwards_actions() {
        // Given
        let button = TestFixture.makeButton(tag: 30)
        let forwarder = EventForwarder(button) { sender, ctx in
            ctx.control(.touchUpInside) {
                [TestAction.buttonTapped(sender.tag)]
            }
        }
        let anyForwarder = AnyEventForwarder(forwarder)

        // When
        let actions = anyForwarder.actions(
            for: button,
            event: .control(.init(.touchUpInside))
        )

        // Then
        XCTAssertEqual(actions.count, 1)
    }

    // MARK: - All Mappings

    func test_all_mappings_reflects_underlying_forwarder() {
        // Given
        let button1 = TestFixture.makeButton(tag: 4)
        let button2 = TestFixture.makeButton(tag: 8)

        let group = SenderGroup {
            EventForwarder(button1) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
            }
            EventForwarder(button2) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.buttonTapped(sender.tag)]
                }
            }
        }

        // When
        let anyForwarder = AnyEventForwarder(group)

        // Then
        XCTAssertEqual(anyForwarder.allMappings.count, 2)
    }

    // MARK: - Actions Retrieval

    func test_actions_returns_correct_actions_for_sender() {
        // Given
        let button = TestFixture.makeButton()
        let forwarder = EventForwarder(button) { _, ctx in
            ctx.control(.touchUpInside) {
                [
                    TestAction.buttonTapped(1),
                    TestAction.sendClickLog
                ]
            }
        }
        let anyForwarder = AnyEventForwarder(forwarder)

        // When
        let actions = anyForwarder.actions(
            for: button,
            event: .control(.init(.touchUpInside))
        )

        // Then
        XCTAssertEqual(actions.count, 2)
    }

    func test_actions_returns_empty_for_wrong_sender() {
        // Given
        let button = TestFixture.makeButton()
        let otherButton = TestFixture.makeButton()
        let forwarder = EventForwarder(button) { _, ctx in
            ctx.control(.touchUpInside) {
                [TestAction.buttonTapped(1)]
            }
        }
        let anyForwarder = AnyEventForwarder(forwarder)

        // When
        let actions = anyForwarder.actions(
            for: otherButton,
            event: .control(.init(.touchUpInside))
        )

        // Then
        XCTAssertEqual(actions.count, 0)
    }

    func test_actions_returns_empty_for_wrong_event() {
        // Given
        let button = TestFixture.makeButton()
        let forwarder = EventForwarder(button) { _, ctx in
            ctx.control(.touchUpInside) {
                [TestAction.buttonTapped(90)]
            }
        }
        let anyForwarder = AnyEventForwarder(forwarder)

        // When
        let actions = anyForwarder.actions(
            for: button,
            event: .control(.init(.valueChanged))
        )

        // Then
        XCTAssertEqual(actions.count, 0)
    }

    // MARK: - Heterogeneous Collections

    func test_array_of_any_forwarders() {
        // Given
        let aButton = TestFixture.makeButton()
        let aSwitch = TestFixture.makeSwitch()

        let forwarder1 = EventForwarder(aButton) { _, ctx in
            ctx.control(.touchUpInside) { [TestAction.buttonTapped(12)] }
        }
        let forwarder2 = EventForwarder(aSwitch) { _, ctx in
            ctx.control(.valueChanged) { [TestAction.switchChanged(true)] }
        }

        // When
        let forwarders: [AnyEventForwarder] = [
            AnyEventForwarder(forwarder1),
            AnyEventForwarder(forwarder2)
        ]

        // Then
        XCTAssertEqual(forwarders.count, 2)

        // When
        let buttonActions = forwarders[0].actions(
            for: aButton,
            event: .control(.init(.touchUpInside))
        )
        let switchActions = forwarders[1].actions(
            for: aSwitch,
            event: .control(.init(.valueChanged))
        )

        // Then
        XCTAssertEqual(buttonActions.count, 1)
        XCTAssertEqual(switchActions.count, 1)
    }

    // MARK: - Integration with EventForwarderBuilder

    func test_result_builder_returns_any_forwarders() {
        // Given
        let aButton = TestFixture.makeButton()
        let aSwitch = TestFixture.makeSwitch()

        let buttonForwarder = EventForwarder(aButton) { _, ctx in
            ctx.control(.touchUpInside) { [TestAction.buttonTapped(2)] }
        }
        let switchForwarder = EventForwarder(aSwitch) { _, ctx in
            ctx.control(.valueChanged) { [TestAction.switchChanged(true)] }
        }

        // When
        let group = SenderGroup {
            buttonForwarder
            switchForwarder
        }

        // Then
        let mappings = group.allMappings
        XCTAssertEqual(mappings.count, 2)
    }

    func test_sender_group_wraps_forwarders_as_any() {
        // Given
        let button = TestFixture.makeButton()
        let forwarder = EventForwarder(button) { _, ctx in
            ctx.control(.touchUpInside) { [TestAction.buttonTapped(1)] }
        }

        // When
        let group = SenderGroup {
            forwarder
        }

        // Then
        XCTAssertEqual(group.allMappings.count, 1)
    }

    // MARK: - Type Erasure Benefits

    func test_different_forwarder_types_in_collection() {
        // Given
        let button = TestFixture.makeButton()
        let view = TestFixture.makeView()

        let buttonForwarder = EventForwarder(button) { _, ctx in
            ctx.control(.touchUpInside) { [TestAction.buttonTapped(6)] }
        }
        let viewForwarder = EventForwarder(view) { _, ctx in
            ctx.tapGesture() { [TestAction.viewTapped] }
        }

        // When
        let collection: [AnyEventForwarder] = [
            AnyEventForwarder(buttonForwarder),
            AnyEventForwarder(viewForwarder)
        ]

        // Then
        XCTAssertEqual(collection.count, 2)

        // When
        let totalMappings = collection.flatMap { $0.allMappings }

        // Then
        XCTAssertEqual(totalMappings.count, 2)
    }

    // MARK: - Mapping Preservation

    func test_type_erasure_preserves_sender_reference() {
        // Given
        let button = TestFixture.makeButton(tag: 23)
        let forwarder = EventForwarder(button) { sender, ctx in
            ctx.control(.touchUpInside) {
                [TestAction.buttonTapped(sender.tag)]
            }
        }
        let anyForwarder = AnyEventForwarder(forwarder)

        // When
        let mappings = anyForwarder.allMappings

        // Then
        XCTAssertEqual(mappings.count, 1)

        let mapping = mappings.first!
        XCTAssertTrue(mapping.sender === button)
    }

    func test_type_erasure_preserves_event_details() {
        // Given
        let button = TestFixture.makeButton()
        let forwarder = EventForwarder(button) { _, ctx in
            ctx.control(.touchUpInside) { [TestAction.buttonTapped(4)] }
            ctx.control(.touchDown) { [TestAction.custom("South")] }
        }
        let anyForwarder = AnyEventForwarder(forwarder)

        // When
        let mappings = anyForwarder.allMappings

        // Then
        XCTAssertEqual(mappings.count, 2)

        let events = mappings.map { $0.event }
        XCTAssertTrue(events.contains(.control(.init(.touchUpInside))))
        XCTAssertTrue(events.contains(.control(.init(.touchDown))))
    }

    func test_type_erasure_preserves_actions() {
        // Given
        let button = TestFixture.makeButton()
        let expectedActions = [
            TestAction.buttonTapped(19),
            TestAction.sendClickLog,
            TestAction.custom("Korea")
        ]
        let forwarder = EventForwarder(button) { _, ctx in
            ctx.control(.touchUpInside) { expectedActions }
        }
        let anyForwarder = AnyEventForwarder(forwarder)

        // When
        let actions = anyForwarder.actions(
            for: button,
            event: .control(.init(.touchUpInside))
        )

        // Then
        XCTAssertEqual(actions.count, expectedActions.count)
    }
}
#endif
