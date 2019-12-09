//
//  Menu+ContextMenuTests.swift
//  Sheeeeeeeeet
//
//  Created by Daniel Saidi on 2019-09-25.
//  Copyright © 2019 Daniel Saidi. All rights reserved.
//

import Quick
import Nimble
import Mockery
import UIKit
@testable import Sheeeeeeeeet

class Menu_ContextMenuTests: QuickSpec {
    
    override func spec() {
        
        describe("adding as context menu") {
            
            it("enables user interaction") {
                guard #available(iOS 13.0, *) else { return }
                let view = UIView()
                let menu = Menu(title: "title", items: [])
                _ = menu.addAsContextMenu(to: view) { _ in }
                expect(view.isUserInteractionEnabled).to(beTrue())
            }
            
            it("adds interaction") {
                guard #available(iOS 13.0, *) else { return }
                let view = TestView()
                let menu = Menu(title: "title", items: [])
                _ = menu.addAsContextMenu(to: view) { _ in }
                let exec = view.recorder.executions(of: view.addInteraction)
                expect(exec.count).to(equal(1))
            }
            
            it("returns correctly configured delegate") {
                guard #available(iOS 13.0, *) else { return }
                var count = 0
                let view = UIView()
                let menu = Menu(title: "title", items: [])
                let delegate = menu.addAsContextMenu(to: view, configuration: .backgroundDismissable) { _ in count += 1 }
                expect(delegate.menuCreator).to(be(menu))
                expect(delegate.configuration).to(equal(.backgroundDismissable))
                delegate.action(MenuItem(title: ""))
                expect(count).to(equal(1))
            }
        }
        
        describe("adding as retained context menu") {
            
            it("retains correctly configured delegate") {
                guard #available(iOS 13.0, *) else { return }
                var count = 0
                let view = TestView()
                let menu = Menu(title: "title", items: [])
                menu.addAsRetainedContextMenu(to: view, configuration: .backgroundDismissable) { _ in count += 1 }
                let delegate = view.contextMenuDelegate as? ContextMenuDelegate
                expect(delegate?.menuCreator).to(be(menu))
                expect(delegate?.configuration).to(equal(.backgroundDismissable))
                delegate?.action(MenuItem(title: ""))
            }
        }
        
        describe("creating context menu") {
            
            it("succeeds if all non-ignored items can be converted") {
                guard #available(iOS 13.0, *) else { return }
                let items = [MenuItem(title: "item")]
                let menu = Menu(title: "title", items: items)
                let contextMenu = try? menu.toContextMenu(action: { _ in }).get()
                expect(contextMenu).toNot(beNil())
                expect(contextMenu?.children.count).to(equal(1))
                expect(contextMenu?.children[0].title).to(equal("item"))
            }
            
            it("fails if any non-ignored item can't be converted") {
                guard #available(iOS 13.0, *) else { return }
                let items = [MenuItem(title: "item"), OkButton(title: "ok")]
                let menu = Menu(title: "title", items: items)
                let result = menu.toContextMenu(action: { _ in })
                switch result {
                case .success: fail("The operation should fail")
                case .failure(let error):
                    switch error {
                    case .unsupportedItemTypes: return
                    default: fail("The operation failed with an incorrect error")
                    }
                }
            }
        }
        
        describe("Auto dismiss on didEnterBackground") {
            
            it("dismisses menu when both isDismissable and shouldDismissOnDidEnterBackground are true") {
                guard #available(iOS 13.0, *) else { return }
                
                let config = Menu.Configuration(isDismissable: true, shouldDismissOnDidEnterBackground: true)
                
                let view = TestView()
                view.shouldCallSuper = true
                let menu = Menu(title: "title", items: [], configuration: config)
                menu.addAsRetainedContextMenu(to: view) { _ in }
                
                guard let interaction = view.interactions.first as? UIContextMenuInteraction,
                    let delegate = view.contextMenuDelegate as? ContextMenuDelegate else {
                        return fail("interactor or delegate not set")
                }
                
                delegate.activeInteraction = interaction
                delegate.activeMenuConfiguration = menu.configuration
                
                NotificationCenter.default.post(Notification(name: UIApplication.didEnterBackgroundNotification))
                
                let addExecutions = view.recorder.executions(of: view.addInteraction)
                let removeExecutions = view.recorder.executions(of: view.removeInteraction)
                
                expect(addExecutions.count).to(equal(4))
                expect(removeExecutions.count).to(equal(1))
            }
            
            it("does not dismiss menu when shouldDismissOnDidEnterBackground is false") {
                guard #available(iOS 13.0, *) else { return }
                
                let config = Menu.Configuration(isDismissable: true, shouldDismissOnDidEnterBackground: false)
                
                
                let view = TestView()
                view.shouldCallSuper = true
                let menu = Menu(title: "title", items: [], configuration: config)
                menu.addAsRetainedContextMenu(to: view) { _ in }
                
                guard let interaction = view.interactions.first as? UIContextMenuInteraction,
                    let delegate = view.contextMenuDelegate as? ContextMenuDelegate else {
                        return fail("interactor or delegate not set")
                }
                
                delegate.activeInteraction = interaction
                delegate.activeMenuConfiguration = menu.configuration
                
                NotificationCenter.default.post(Notification(name: UIApplication.didEnterBackgroundNotification))
                
                let addExecutions = view.recorder.executions(of: view.addInteraction)
                let removeExecutions = view.recorder.executions(of: view.removeInteraction)
                
                expect(addExecutions.count).to(equal(3))
                expect(removeExecutions.count).to(equal(0))
            }
            
            it("does not dismiss menu when isDismissable is false") {
                guard #available(iOS 13.0, *) else { return }
                
                let config = Menu.Configuration(isDismissable: false, shouldDismissOnDidEnterBackground: true)
                
                let view = TestView()
                view.shouldCallSuper = true
                let menu = Menu(title: "title", items: [], configuration: config)
                menu.addAsRetainedContextMenu(to: view) { _ in }
                
                guard let interaction = view.interactions.first as? UIContextMenuInteraction,
                    let delegate = view.contextMenuDelegate as? ContextMenuDelegate else {
                        return fail("interactor or delegate not set")
                }
                
                delegate.activeInteraction = interaction
                delegate.activeMenuConfiguration = menu.configuration
                
                NotificationCenter.default.post(Notification(name: UIApplication.didEnterBackgroundNotification))
                
                let addExecutions = view.recorder.executions(of: view.addInteraction)
                let removeExecutions = view.recorder.executions(of: view.removeInteraction)
                
                expect(addExecutions.count).to(equal(3))
                expect(removeExecutions.count).to(equal(0))
            }
        }
    }
}

@available(iOS 13.0, *)
private class TestView: UIView, ContextMenuDelegateRetainer {
    
    var recorder = Mock()
    var contextMenuDelegate: Any?
    var shouldCallSuper: Bool = false
    
    override func addInteraction(_ interaction: UIInteraction) {
        recorder.invoke(addInteraction, args: (interaction))
        if shouldCallSuper { super.addInteraction(interaction) }
    }
    
    override func removeInteraction(_ interaction: UIInteraction) {
        recorder.invoke(removeInteraction, args: (interaction))
        if shouldCallSuper { super.addInteraction(interaction) }
    }
}
