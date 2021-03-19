# tocaml

It is completely experimental. The goal of `tocaml` is to allow for ocaml file
to be used for configuration file. So it features the following:
 * An extension `[% import "PATH|URL" "SHA"?]` which allows to directly access
   an ocaml module located localy or remotely. The optional `"SHA"` allows to check that
   the module has not been replaced.
 * A wrapping of every constant with a location. It allows to give precise error
   location of user input even if it come from far from the application point


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
content) are imported only once, so if the define some types they are the same.
Only the implementation file is imported, interface file are not taken into account.

This extension is also available through the ppx rewriter `tocaml.ppx.import`

## Constant wrapping

Every constant that appear inside the file are wrapped in a `'a loc` record:

```
type location = { loc_start : Lexing.position; loc_end : Lexing.position }

type 'a loc = { loc : location; txt : 'a }
```

This transformation is available through the ppx rewriter `tocaml.ppx.loc_cst`
