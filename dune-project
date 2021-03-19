(lang dune 2.7)
(cram enable)
(generate_opam_files true)

(license MPL)
(authors "François Bobot")
(maintainers "François Bobot")
(source (github bobot/tocaml))

(package (name tocaml) (synopsis "Set of tools and ppx to use OCaml files as configuration files")
(depends
        ppxlib
        ocaml-compiler-libs
        )
)
