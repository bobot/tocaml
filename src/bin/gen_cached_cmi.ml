let () =
  let filename = Sys.argv.(1) in
  let oc = open_out filename in
  let fmt = Format.formatter_of_out_channel oc in
  Format.fprintf fmt "@[<hv 3>@[let cmis = [@]";
  for i = 2 to Array.length Sys.argv - 1 do
    let cmi = Cmi_format.read_cmi Sys.argv.(i) in
    let data = Marshal.to_string cmi [] in
    Format.fprintf fmt "@[%S;@]" data
  done;
  Format.fprintf fmt "@[]@]@]@.";
  close_out oc
