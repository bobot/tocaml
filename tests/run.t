# Test simple case

  $ cat > import.ml <<EOF
  > let x = "helloworld"
  > EOF

  $ tocaml --v0 -  <<EOF
  > module M = [% import "import.ml"] ;;
  > M.x.txt;;
  > EOF
  helloworld

  $ tocaml --v0 -  <<EOF
  > module M = [% import "import.ml" "7f2f2c5002cb0a5c9643675b06d2fa72"] ;;
  > M.x.txt;;
  > EOF
  helloworld

  $ tocaml --v0 -  <<EOF
  > module M = [% import "import.ml" "error"] ;;
  > M.x.txt;;
  > EOF
  File "-", line 1, characters 11-41:
  Error: File import.ml has a different digest "7f2f2c5002cb0a5c9643675b06d2fa72" than expected "error"
  [2]


  $ tocaml --v0 -  <<EOF
  > [% import "import.ml"].x.txt;;
  > EOF
  helloworld

  $ tocaml --v0 -  <<EOF
  > print_string [% import "import.ml"].x.txt;;
  > [% import "import.ml"].x.txt;;
  > EOF
  helloworldhelloworld

  $ tocaml --v0 -  <<EOF
  > [% import "https://raw.githubusercontent.com/bobot/tocaml/1f851efe8361d6f047fb2af96bcbef451074681c/tests/ppx/import.ml" "7f2f2c5002cb0a5c9643675b06d2fa72"].x.txt;;
  > EOF
  helloworld

  $ tocaml --v0 -  <<EOF
  > let s = "Helloworld" in
  > s.loc;;
  > EOF
  ((loc_start((pos_fname"")(pos_lnum 1)(pos_bol 0)(pos_cnum 8)))(loc_end((pos_fname"")(pos_lnum 1)(pos_bol 0)(pos_cnum 20))))

  $ cat > import.ml <<EOF
  > "helloworld"
  > EOF

  $ tocaml --v0 -  <<EOF
  > [%exp "import.ml"].txt ;;
  > EOF
  helloworld

  $ cat > func.ml <<EOF
  > let f s = Ok s;;
  > f
  > EOF

  $ tocaml --v0 -  <<EOF
  > [%exp "func.ml"] 1 ;;
  > EOF
  (Ok 1)
