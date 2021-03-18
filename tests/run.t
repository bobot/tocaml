# Test simple case

  $ cat > import.ml <<EOF
  > let x = "helloworld"
  > EOF

  $ tocaml - -impl  <<EOF
  > module M = [% import "import.ml"] ;;
  > print_string M.x;;
  > EOF
  module TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 =
    struct let x = "helloworld" end
  module M = TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72
  ;;print_string M.x

  $ tocaml - -impl  <<EOF
  > module M = [% import "import.ml" "7f2f2c5002cb0a5c9643675b06d2fa72"] ;;
  > print_string M.x;;
  > EOF
  module TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 =
    struct let x = "helloworld" end
  module M = TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72
  ;;print_string M.x

  $ tocaml - -impl  <<EOF
  > module M = [% import "import.ml" "error"] ;;
  > print_string M.x;;
  > EOF
  File "-", line 1, characters 11-41:
  Error: File import.ml has a different digest "7f2f2c5002cb0a5c9643675b06d2fa72" than expected "error"
  [1]


  $ tocaml - -impl  <<EOF
  > print_string [% import "import.ml"].x;;
  > EOF
  module TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 =
    struct let x = "helloworld" end
  ;;print_string TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72.x

  $ tocaml - -impl  <<EOF
  > print_string [% import "import.ml"].x;;
  > print_string [% import "import.ml"].x;;
  > EOF
  module TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 =
    struct let x = "helloworld" end
  ;;print_string TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72.x
  ;;print_string TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72.x

  $ tocaml - -impl  <<EOF
  > print_string [% import "https://raw.githubusercontent.com/bobot/tocaml/1f851efe8361d6f047fb2af96bcbef451074681c/tests/ppx/import.ml" "7f2f2c5002cb0a5c9643675b06d2fa72"].x;;
  > EOF
  module TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72 =
    struct let x = "helloworld" end
  ;;print_string TOCAML_private_7f2f2c5002cb0a5c9643675b06d2fa72.x
