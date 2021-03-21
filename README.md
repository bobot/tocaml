# tocaml

It is completely experimental. The goal of `tocaml` is to allow for ocaml file
to be used for configuration file. So it features the following:
 * An extension `[% import "PATH|URL" "SHA"?]` which allows to directly access
   an ocaml module located localy or remotely. The optional `"SHA"` allows to check that
   the module has not been replaced.
 * An extension `[% exp "PATH|URL" "SHA"?]` which allows to directly access
   the last expression defined in an OCaml file (not binded).
 * A wrapping of every constant string with a location. It allows to give precise error
   location of user input even if it come from far from the application point
 * Substitution inside string. `$name` and `${expr}` are replaced in string by
   the value of the variable `name` or the expression `expr`.
 * Output of the result of the evaluation of a tocaml script in JSON (`--json`)
   and S-expresion (`--sexp` default).
 * A mendatory version selection of the tocaml binary currently the last version
   is: `tocaml --v0`


## Import

The `import` extension point, can be used:
 * As a module expression:

```ocaml
module M = [%import "mod.ml"]
```

 * Inside expression, in the context of a field access:

```ocaml
let () = print_string [%import "hello.ml"].world
```

All the imports that refer to the same file (files with the same textual
content) are imported only once, so if they define some types they are the same.
Only the implementation file is imported, interface file are not taken into account.

This extension is also available through the ppx rewriter `tocaml.ppx.import`

## Exp

The `exp` extension point, can be used to access the last expression of an
imported module:

`foo.ml`:

```
let x = ... ;;
expression;;
```

In another file the extension point refer to the value of the `expression`:

```
let y = .... [%exp "foo.ml"] ...
```

This extension is also available through the ppx rewriter `tocaml.ppx.import`


## Constant string wrapping

Every constant string that appear inside the file are wrapped in a `'a loc` record:

```
type location = { loc_start : Lexing.position; loc_end : Lexing.position }

type 'a loc = { loc : location; txt : 'a }
```

Those types are defined in the library `tocaml.locstring`  and accessed in
tocaml as the toplevel module `LocString`.

```
let y = "foo"
"a${y}a"
```

The previous code is evaluated as `"afooa"`.

This transformation is available through the ppx rewriter `tocaml.ppx.loc_cst`


## Discussion

    This section is for discussion of futur extension:

 * Usual OCaml string without wrapping and subsitution could be made available
   withby marking them with a field access `s` : `"this is not $substituted".s`
 * Import are not possible inside string subsitution because they are in two
   different ppx, and import should be applied first.
 * Direct import of git file using `git-http` would be nice.
 * Caching could be implemented, at least so that the tests doesn't access the network
 * Merlin doesn't like the import ppx.
