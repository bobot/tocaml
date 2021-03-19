let () =
  let cmi = Cmi_format.read_cmi Sys.argv.(1) in
  let data = Marshal.to_string cmi [] in
  let filename = Sys.argv.(2) in
  let oc = open_out filename in
  Printf.fprintf oc "let cmi = %S\n" data;
  close_out oc
