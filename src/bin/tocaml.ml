let () = Printexc.record_backtrace true

let () =
  let old_loader = !Persistent_env.Persistent_signature.load in
  (Persistent_env.Persistent_signature.load :=
     fun ~unit_name ->
       match unit_name with
       | "Tocaml_ppx_loc_cst_runtime" ->
           Some
             {
               Persistent_env.Persistent_signature.filename =
                 Sys.executable_name;
               cmi = Marshal.from_string Embeded_cmi.cmi 0;
             }
       | _ -> old_loader ~unit_name);
  Toploop.add_hook (function
    | Toploop.After_setup ->
        let env = !Toploop.toplevel_env in
        let id = Ident.create_persistent "Tocaml_ppx_loc_cst_runtime" in
        Toploop.toplevel_env := Env.add_persistent_structure id env
    | _ -> ())

exception Ellipsis

let print_out_value ppf tree =
  let open Outcometree in
  let open Format in
  let cautious f ppf arg =
    try f ppf arg with Ellipsis -> Format.fprintf ppf "..."
  in
  let print_lident ppf = function
    | "::" -> pp_print_string ppf "(::)"
    | s -> pp_print_string ppf s
  in
  let rec print_ident ppf = function
    | Oide_ident s -> print_lident ppf s.printed_name
    | Oide_dot (id, s) ->
        print_ident ppf id;
        pp_print_char ppf '.';
        print_lident ppf s
    | Oide_apply (id1, id2) ->
        fprintf ppf "%a(%a)" print_ident id1 print_ident id2
  in
  let parenthesize_if_neg ppf fmt v isneg =
    if isneg then pp_print_char ppf '(';
    fprintf ppf fmt v;
    if isneg then pp_print_char ppf ')'
  in
  let rec print_tree_1 ppf = function
    | Oval_constr (name, [ param ]) ->
        fprintf ppf "@[<1>%a@ %a@]" print_ident name print_constr_param param
    | Oval_constr (name, (_ :: _ as params)) ->
        fprintf ppf "@[<1>%a@ (%a)@]" print_ident name
          (print_tree_list print_tree_1 ",")
          params
    | Oval_variant (name, Some param) ->
        fprintf ppf "@[<2>`%s@ %a@]" name print_constr_param param
    | tree -> print_simple_tree ppf tree
  and print_constr_param ppf = function
    | Oval_int i -> parenthesize_if_neg ppf "%i" i (i < 0)
    | Oval_int32 i -> parenthesize_if_neg ppf "%lil" i (i < 0l)
    | Oval_int64 i -> parenthesize_if_neg ppf "%LiL" i (i < 0L)
    | Oval_nativeint i -> parenthesize_if_neg ppf "%nin" i (i < 0n)
    | Oval_float f ->
        parenthesize_if_neg ppf "%f" f (f < 0.0 || 1. /. f = neg_infinity)
    | Oval_string (_, _, Ostr_bytes) as tree ->
        pp_print_char ppf '(';
        print_simple_tree ppf tree;
        pp_print_char ppf ')'
    | tree -> print_simple_tree ppf tree
  and print_simple_tree ppf = function
    | Oval_int i -> fprintf ppf "%i" i
    | Oval_int32 i -> fprintf ppf "%lil" i
    | Oval_int64 i -> fprintf ppf "%LiL" i
    | Oval_nativeint i -> fprintf ppf "%nin" i
    | Oval_float f -> pp_print_float ppf f
    | Oval_char c -> fprintf ppf "%C" c
    | Oval_string (s, maxlen, kind) -> (
        try
          let len = String.length s in
          let s = if len > maxlen then String.sub s 0 maxlen else s in
          (match kind with
          | Ostr_bytes -> fprintf ppf "Bytes.of_string %S" s
          | Ostr_string -> fprintf ppf "%S" s);
          if len > maxlen then
            fprintf ppf "... (* string length %d; truncated *)" len
        with Invalid_argument _ (* "String.create" *) ->
          fprintf ppf "<huge string>")
    | Oval_list tl ->
        fprintf ppf "@[<1>[%a]@]" (print_tree_list print_tree_1 ";") tl
    | Oval_array tl ->
        fprintf ppf "@[<2>[|%a|]@]" (print_tree_list print_tree_1 ";") tl
    | Oval_constr (name, []) -> print_ident ppf name
    | Oval_variant (name, None) -> fprintf ppf "`%s" name
    | Oval_stuff s -> pp_print_string ppf s
    | Oval_record fel ->
        fprintf ppf "@[<1>{%a}@]" (cautious (print_fields true)) fel
    | Oval_ellipsis -> raise Ellipsis
    | Oval_printer f -> f ppf
    | Oval_tuple tree_list ->
        fprintf ppf "@[<1>(%a)@]" (print_tree_list print_tree_1 ",") tree_list
    | tree -> fprintf ppf "@[<1>(%a)@]" (cautious print_tree_1) tree
  and print_fields first ppf = function
    | [] -> ()
    | (name, tree) :: fields ->
        if not first then fprintf ppf ";@ ";
        fprintf ppf "@[<1>%a@ =@ %a@]" print_ident name (cautious print_tree_1)
          tree;
        print_fields false ppf fields
  and print_tree_list print_item sep ppf tree_list =
    let rec print_list first ppf = function
      | [] -> ()
      | tree :: tree_list ->
          if not first then fprintf ppf "%s@ " sep;
          print_item ppf tree;
          print_list false ppf tree_list
    in
    cautious (print_list true) ppf tree_list
  in
  cautious print_tree_1 ppf tree

let () =
  let file = Sys.argv.(1) in
  let cin = if file = "-" then stdin else open_in file in
  (try Toploop.initialize_toplevel_env ()
   with (Env.Error _ | Typetexp.Error _) as exn ->
     Location.report_exception Format.err_formatter exn;
     exit 2);
  let phr =
    Fun.protect
      ~finally:(fun () -> close_in cin)
      (fun () ->
        let lb = Lexing.from_channel ~with_positions:true cin in
        Parse.implementation lb)
  in
  Location.input_name := file;
  Sys.catch_break true;
  Toploop.run_hooks Toploop.After_setup;
  try
    let phr = Pparse.apply_rewriters_str ~restore:true ~tool_name:"ocaml" phr in
    let phr = Ppxlib.Selected_ast.Of_ocaml.copy_structure phr in
    let phr = Ppxlib.Driver.map_structure phr in
    let phr = Ppxlib.Selected_ast.To_ocaml.copy_structure phr in
    let success =
      Toploop.execute_phrase true Format.err_formatter (Ptop_def phr)
    in
    if success then exit 0 else exit 1
  with exn ->
    Location.report_exception Format.err_formatter exn;
    exit 2
