{ name =
    "lib2"
, dependencies =
    [ "effect"
    , "console"
    , "prelude"
    , "lib1"            -- Note the dependency here
    ]
, sources =
    [ "src/**/*.purs" ]
, packages =
    ../packages.dhall
}
