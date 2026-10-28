//
//  KnittingPatternUITests.swift
//  KnittingPatternUITests
//
//  Created by Ekaterina on 26.10.2026.
//

import XCTest

/// Сценарии пользователя: создание схемы, рисование, библиотека, профиль.
/// Каждый тест запускает приложение с пустой базой в памяти и английским интерфейсом.
@MainActor
final class KnittingPatternUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
    }

    // MARK: Помощники

    private func launch(withSamples: Bool = false) {
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if withSamples {
            app.launchArguments += ["-seedSamples", "YES"]
        }
        app.launch()
    }

    /// Создаёт схему через мастер и оставляет открытым редактор.
    private func createChart(named name: String) {
        app.tabBars.buttons["Create"].tap()
        app.buttons["Continue"].tap()

        let nameField = app.textFields["Chart name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText(name)
        app.buttons["createChartButton"].tap()

        XCTAssertTrue(app.otherElements["chartCanvas"].waitForExistence(timeout: 3))
    }

    /// Открывает меню карточки долгим нажатием — как контекстное меню у пользователя.
    private func openCardMenu(named name: String) {
        app.staticTexts[name].press(forDuration: 1.2)
    }

    private func goBackToLibrary() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["My Charts"].waitForExistence(timeout: 3))
    }

    // MARK: Создание и редактор

    func testEmptyLibraryOffersToCreateChart() {
        launch()
        XCTAssertTrue(app.staticTexts["Your charts will appear here"].exists)
        XCTAssertTrue(app.buttons["Create Chart"].exists)
    }

    func testCreateChartOpensEditorAndAppearsInLibrary() {
        launch()
        createChart(named: "Scarf")
        XCTAssertTrue(app.navigationBars.staticTexts["Scarf"].exists)

        goBackToLibrary()
        XCTAssertTrue(app.staticTexts["Scarf"].exists)
        XCTAssertFalse(app.staticTexts["Your charts will appear here"].exists)
    }

    func testCancelCreationLeavesLibraryEmpty() {
        launch()
        app.tabBars.buttons["Create"].tap()
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["Your charts will appear here"].waitForExistence(timeout: 3))
    }

    func testDrawingCanBeUndoneAndRedone() {
        launch()
        createChart(named: "Sketch")

        let undo = app.buttons["Undo"]
        let redo = app.buttons["Redo"]
        XCTAssertFalse(undo.isEnabled)

        app.otherElements["chartCanvas"].tap()
        XCTAssertTrue(undo.isEnabled)

        undo.tap()
        XCTAssertFalse(undo.isEnabled)
        XCTAssertTrue(redo.isEnabled)

        redo.tap()
        XCTAssertTrue(undo.isEnabled)
    }

    // MARK: Библиотека

    func testRenameChart() {
        launch()
        createChart(named: "Scarf")
        goBackToLibrary()

        openCardMenu(named: "Scarf")
        app.buttons["Rename"].tap()

        let field = app.alerts.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Scarf".count) + "Mittens")
        app.alerts.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Mittens"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Scarf"].exists)
    }

    func testDuplicateAndDeleteChart() {
        launch()
        createChart(named: "Scarf")
        goBackToLibrary()

        openCardMenu(named: "Scarf")
        app.buttons["Duplicate"].tap()
        let copy = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Scarf ('")).firstMatch
        XCTAssertTrue(copy.waitForExistence(timeout: 3))

        deleteChart(named: copy.label)
        deleteChart(named: "Scarf")
        XCTAssertTrue(app.staticTexts["Your charts will appear here"].waitForExistence(timeout: 3))
    }

    /// Удаляет схему через меню карточки: ждёт диалог подтверждения и исчезновение карточки.
    private func deleteChart(named name: String) {
        openCardMenu(named: name)
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Delete chart “\(name)”?"].waitForExistence(timeout: 3))
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts[name].waitForNonExistence(timeout: 3))
    }

    func testFiltersAndSearch() {
        launch(withSamples: true)
        XCTAssertTrue(app.staticTexts["Heart"].waitForExistence(timeout: 3))

        app.buttons["Knitting"].tap()
        XCTAssertTrue(app.staticTexts["Striped Rib"].exists)
        XCTAssertFalse(app.staticTexts["Heart"].exists)

        app.buttons["Favorites"].tap()
        XCTAssertTrue(app.staticTexts["Little Heart (favorite)"].exists)
        XCTAssertFalse(app.staticTexts["Striped Rib"].exists)

        app.buttons["All"].tap()
        let search = app.textFields["Search"]
        search.tap()
        search.typeText("rib")
        XCTAssertTrue(app.staticTexts["Striped Rib"].exists)
        XCTAssertFalse(app.staticTexts["Heart"].exists)

        search.typeText("bon")
        XCTAssertTrue(app.staticTexts["Nothing found"].waitForExistence(timeout: 3))
    }

    // MARK: Профиль

    func testProfileShowsStatsAndVersion() {
        launch(withSamples: true)
        app.tabBars.buttons["Profile"].tap()

        XCTAssertTrue(app.staticTexts["Version"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["3"].exists, "Total number of sample charts")
        XCTAssertTrue(app.buttons["Theme"].exists || app.staticTexts["Theme"].exists)
    }

    // MARK: Производительность

    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
