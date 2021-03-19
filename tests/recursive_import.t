# Test simple case

  $ cat > import0.ml <<EOF
  > let x = "helloworld"
  > EOF

  $ cat > import1.ml <<EOF
  > module M = [% import "import0.ml"] ;;
  > EOF

  $ tocaml - -impl  <<EOF
  > module M = [% import "import1.ml"] ;;
  > EOF
  module TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 :
    sig val x : string Tocaml_ppx_loc_cst_runtime.loc end
  module TOCAML_private_429efa79e0f9e471b8e618a2d4177abc :
    sig module M = TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 end
  module M = TOCAML_private_429efa79e0f9e471b8e618a2d4177abc

  $ cat > import1.ml <<EOF
  > let x = [% import "import0.ml"].x ;;
  > EOF

  $ tocaml - -impl  <<EOF
  > module M = [% import "import1.ml"] ;;
  > EOF
  module TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 :
    sig val x : string Tocaml_ppx_loc_cst_runtime.loc end
  module TOCAML_private_4679bb1c87936d3926cca30aca9de584 :
    sig val x : string Tocaml_ppx_loc_cst_runtime.loc end
  module M = TOCAML_private_4679bb1c87936d3926cca30aca9de584


# Test cycle

  $ cat > import0.ml <<EOF
  > module M = [% import "import1.ml"]
  > EOF

  $ cat > import1.ml <<EOF
  > module M = [% import "import0.ml"] ;;
  > EOF

  $ tocaml - -impl  <<EOF
  > module M = [% import "import1.ml"] ;;
  > EOF
  File "-", line 1, characters 11-34:
  Error: Loading cycles with import1.ml, sha 429efa79e0f9e471b8e618a2d4177abc
  [2]
