# Test simple case

  $ cat > import.ml <<EOF
  > let x = "helloworld"
  > EOF

  $ tocaml -  <<EOF
  > module M = [% import "import.ml"] ;;
  > M.x.txt;;
  > EOF
  - : string = "helloworld"

  $ tocaml -  <<EOF
  > module M = [% import "import.ml" "7f2f2c5002cb0a5c9643675b06d2fa72"] ;;
  > M.x.txt;;
  > EOF
  - : string = "helloworld"

  $ tocaml -  <<EOF
  > module M = [% import "import.ml" "error"] ;;
  > M.x.txt;;
  > EOF
  File "-", line 1, characters 11-41:
  Error: File import.ml has a different digest "7f2f2c5002cb0a5c9643675b06d2fa72" than expected "error"
  [2]


  $ tocaml -  <<EOF
  > [% import "import.ml"].x.txt;;
  > EOF
  - : string = "helloworld"

  $ tocaml -  <<EOF
  > print_string [% import "import.ml"].x.txt;;
  > [% import "import.ml"].x.txt;;
  > EOF
  - : string = "helloworld"
  helloworld

  $ tocaml -  <<EOF
  > [% import "https://raw.githubusercontent.com/bobot/tocaml/1f851efe8361d6f047fb2af96bcbef451074681c/tests/ppx/import.ml" "7f2f2c5002cb0a5c9643675b06d2fa72"].x.txt;;
  > EOF
  - : string = "helloworld"

  $ tocaml -  <<EOF
  > let s = "Helloworld" in
  > s.loc;;
  > EOF
  - : Tocaml_ppx_loc_cst_runtime.location =
  {Tocaml_ppx_loc_cst_runtime.loc_start =
    {Lexing.pos_fname = ""; pos_lnum = 1; pos_bol = 0; pos_cnum = 8};
   loc_end = {Lexing.pos_fname = ""; pos_lnum = 1; pos_bol = 0; pos_cnum = 20}}

  $ cat > import.ml <<EOF
  > "helloworld"
  > EOF

  $ tocaml -  <<EOF
  > [%exp "import.ml"].txt ;;
  > EOF
  - : string = "helloworld"
