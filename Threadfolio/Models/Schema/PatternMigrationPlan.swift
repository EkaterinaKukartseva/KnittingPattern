//
//  PatternMigrationPlan.swift
//  KnittingPattern
//
//  Created by Ekaterina on 27.10.2026.
//

import SwiftData

/// Порядок версий хранилища и шаги перехода между ними.
/// Новая версия добавляется в конец `schemas`, а переход к ней — в `stages`:
/// `.lightweight` для простых изменений, `.custom` если данные нужно преобразовать.
nonisolated enum PatternMigrationPlan: SchemaMigrationPlan {

    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
