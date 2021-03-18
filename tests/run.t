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
