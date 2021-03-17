{ name =
    "app1"
, dependencies =
    -- Note: the app does not include all the dependencies that the lib included
    [ "prelude"
    , "simple-json" -- Note: this dep was not used by the library, only the app uses it
    , "lib2"        -- Note: we add `lib2` as dependency
    ]
, packages =
    -- We also refer to the top-level packages file here, so deps stay in sync for all packages
    ../packages.dhall
}
