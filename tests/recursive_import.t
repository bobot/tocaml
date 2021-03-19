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
  module TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 =
    struct
      let x =
        {
          Tocaml_loc_cst_runtime.loc =
            {
              Tocaml_loc_cst_runtime.loc_start =
                {
                  Lexing.pos_fname = "";
                  pos_lnum = 1;
                  pos_bol = 0;
                  pos_cnum = 8
                };
              Tocaml_loc_cst_runtime.loc_end =
                {
                  Lexing.pos_fname = "";
                  pos_lnum = 1;
                  pos_bol = 0;
                  pos_cnum = 20
                }
            };
          Tocaml_loc_cst_runtime.txt = "helloworld"
        }
    end
  module TOCAML_private_429efa79e0f9e471b8e618a2d4177abc =
    struct module M = TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 end
  module M = TOCAML_private_429efa79e0f9e471b8e618a2d4177abc

  $ cat > import1.ml <<EOF
  > let x = [% import "import0.ml"].x ;;
  > EOF

  $ tocaml - -impl  <<EOF
  > module M = [% import "import1.ml"] ;;
  > EOF
  module TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 =
    struct
      let x =
        {
          Tocaml_loc_cst_runtime.loc =
            {
              Tocaml_loc_cst_runtime.loc_start =
                {
                  Lexing.pos_fname = "";
                  pos_lnum = 1;
                  pos_bol = 0;
                  pos_cnum = 8
                };
              Tocaml_loc_cst_runtime.loc_end =
                {
                  Lexing.pos_fname = "";
                  pos_lnum = 1;
                  pos_bol = 0;
                  pos_cnum = 20
                }
            };
          Tocaml_loc_cst_runtime.txt = "helloworld"
        }
    end
  module TOCAML_private_4679bb1c87936d3926cca30aca9de584 =
    struct let x = TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72.x end
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
  [1]
