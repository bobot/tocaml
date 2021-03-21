  $ tocaml --v0 -  <<EOF
  > let x = "foo";;
  > "a\$x a".txt;;
  > EOF
  "afoo a"

  $ tocaml --v0 -  <<EOF
  > let x = "foo";;
  > "a\${LocString.of_int 1}a".txt;;
  > EOF
  a1a
