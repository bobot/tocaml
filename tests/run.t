# Test simple case

  $ cat > import.ml <<EOF
  > let x = "helloworld"
  > EOF

  $ tocaml -  <<EOF
  > module M = [% import "import.ml"] ;;
  > let y = M.x.txt;;
  > EOF
  module TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 :
    sig val x : string Tocaml_ppx_loc_cst_runtime.loc end
  module M = TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72
  val y : string = "helloworld"

  $ tocaml -  <<EOF
  > module M = [% import "import.ml" "7f2f2c5002cb0a5c9643675b06d2fa72"] ;;
  > print_string M.x.txt;;
  > EOF
  module TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 :
    sig val x : string Tocaml_ppx_loc_cst_runtime.loc end
  module M = TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72
  helloworld

  $ tocaml -  <<EOF
  > module M = [% import "import.ml" "error"] ;;
  > print_string M.x.txt;;
  > EOF
  File "-", line 1, characters 11-41:
  Error: File import.ml has a different digest "7f2f2c5002cb0a5c9643675b06d2fa72" than expected "error"
  [2]


  $ tocaml -  <<EOF
  > print_string [% import "import.ml"].x.txt;;
  > EOF
  module TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 :
    sig val x : string Tocaml_ppx_loc_cst_runtime.loc end
  helloworld

  $ tocaml -  <<EOF
  > print_string [% import "import.ml"].x.txt;;
  > print_string [% import "import.ml"].x.txt;;
  > EOF
  module TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 :
    sig val x : string Tocaml_ppx_loc_cst_runtime.loc end
  helloworldhelloworld

  $ tocaml -  <<EOF
  > print_string [% import "https://raw.githubusercontent.com/bobot/tocaml/1f851efe8361d6f047fb2af96bcbef451074681c/tests/ppx/import.ml" "7f2f2c5002cb0a5c9643675b06d2fa72"].x.txt;;
  > EOF
  module TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 :
    sig val x : string Tocaml_ppx_loc_cst_runtime.loc end
  helloworld

  $ tocaml -  <<EOF
  > let s = "Helloworld" in
  > print_string s.loc.loc_start.pos_fname;;
  > EOF
  - : unit = ()
