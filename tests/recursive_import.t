# Test simple case

  $ cat > import0.ml <<EOF
  > let x = "helloworld"
  > EOF

  $ cat > import1.ml <<EOF
  > module M = [% import "import0.ml"] ;;
  > EOF

  $ tocaml - <<EOF
  > [% import "import1.ml"].M.x.txt ;;
  > EOF
  helloworld

  $ cat > import1.ml <<EOF
  > let x = [% import "import0.ml"].x ;;
  > EOF

  $ tocaml - <<EOF
  > [% import "import1.ml"].x ;;
  > EOF
  ((loc((loc_start((pos_fname"")(pos_lnum 1)(pos_bol 0)(pos_cnum 8)))(loc_end((pos_fname"")(pos_lnum 1)(pos_bol 0)(pos_cnum 20)))))(txt helloworld))


# Test cycle

  $ cat > import0.ml <<EOF
  > module M = [% import "import1.ml"]
  > EOF

  $ cat > import1.ml <<EOF
  > module M = [% import "import0.ml"] ;;
  > EOF

  $ tocaml - <<EOF
  > module M = [% import "import1.ml"] ;;
  > EOF
  File "-", line 1, characters 11-34:
  Error: Loading cycles with import1.ml, sha 429efa79e0f9e471b8e618a2d4177abc
  [2]
