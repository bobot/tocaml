{ name =
    "lib1"
, dependencies =
    [ "effect"
    , "console"
    , "prelude"
    ]
, sources =
    [ "src/**/*.purs" ]
, packages =
    ../packages.dhall   -- Note: this refers to the top-level packages file
}
