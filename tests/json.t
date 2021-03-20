  $ tocaml --v0 --json -  <<EOF
  > "a";;
  > EOF
  {
    "loc": {
      "loc_start": {
        "pos_fname": "",
        "pos_lnum": 1,
        "pos_bol": 0,
        "pos_cnum": 0
      },
      "loc_end": {
        "pos_fname": "",
        "pos_lnum": 1,
        "pos_bol": 0,
        "pos_cnum": 3
      }
    },
    "txt": "a"
  }

  $ tocaml --v0 --json -  <<EOF
  > "a".txt;;
  > EOF
  "a"

  $ tocaml --v0 --json -  <<EOF
  > type r = { a: string; b: string };;
  > { a = "a".txt; b = "b".txt };;
  > EOF
  { "a": "a", "b": "b" }
