# tocaml

It is completely experimental. The goal of `tocaml` is to allow for ocaml file
to be used for configuration file. So it features the following:
 * An extension `[% import "PATH|URL" "SHA"?]` which allows to directly access
   an ocaml module located localy or remotely. The optional `"SHA"` allows to check that
   the module has not been replaced.


## Import

The `import` extension point can be used:
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
