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

module Sexp = struct
  open Sexplib

  let print_out_value ppf tree =
    let open Outcometree in
    let open Format in
    let rec conv_ident = function
      | Oide_ident s -> Sexp.Atom s.printed_name
      | Oide_dot (_, id) -> Sexp.Atom id
      | Oide_apply (_, id) -> conv_ident id
    in
    let atom fmt = Format.kasprintf (fun s -> Sexp.Atom s) fmt in
    let rec conv = function
      | Oval_int i -> atom "%i" i
      | Oval_int32 i -> atom "%lil" i
      | Oval_int64 i -> atom "%LiL" i
      | Oval_nativeint i -> atom "%nin" i
      | Oval_float f -> atom "%a" pp_print_float f
      | Oval_char c -> atom "%C" c
      | Oval_string (s, _, _) -> Sexp.Atom s
      | Oval_list tl | Oval_array tl | Oval_tuple tl ->
          Sexp.List (List.map conv tl)
      | Oval_constr (name, []) -> conv_ident name
      | Oval_variant (name, None) -> Sexp.Atom name
      | Oval_stuff s -> Sexp.Atom s
      | Oval_record fel ->
          Sexp.List
            (List.map (fun (s, v) -> Sexp.List [ conv_ident s; conv v ]) fel)
      | Oval_ellipsis -> assert false (* max depth and step set to maxint *)
      | Oval_printer f -> atom "%t" f
      | Oval_constr (name, params) ->
          Sexp.List (conv_ident name :: List.map conv params)
      | Oval_variant (name, Some param) ->
          (* possible to improve by doing like for constr *)
          Sexp.List [ Sexp.Atom name; conv param ]
    in
    let sexp = conv tree in
    Sexp.pp ppf sexp

  let print_out_phrase ppf = function
    | Outcometree.Ophr_eval (outv, _) -> print_out_value ppf outv
    | Ophr_signature [] -> ()
    | Ophr_signature _ | Ophr_exception (_, _) -> assert false
end

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
  Toploop.max_printer_depth := max_int;
  Toploop.max_printer_steps := max_int;
  Oprint.out_phrase := Sexp.print_out_phrase;
  Location.input_name := file;
  Sys.catch_break true;
  Toploop.run_hooks Toploop.After_setup;
  try
    let phr = Pparse.apply_rewriters_str ~restore:true ~tool_name:"ocaml" phr in
    let phr = Ppxlib.Selected_ast.Of_ocaml.copy_structure phr in
    let phr = Ppxlib.Driver.map_structure phr in
    let phr = Ppxlib.Selected_ast.To_ocaml.copy_structure phr in
    let rec get_eval acc = function
      | [] -> (List.rev acc, None)
      | [ ({ Parsetree.pstr_desc = Pstr_eval (_, _); _ } as last) ] ->
          (List.rev acc, Some last)
      | a :: l -> get_eval (a :: acc) l
    in
    let phr, last_eval = get_eval [] phr in
    let success =
      Toploop.execute_phrase false Format.err_formatter (Ptop_def phr)
    in
    if not success then exit 1;
    match last_eval with
    | None -> ()
    | Some last_eval ->
        let success =
          Toploop.execute_phrase true Format.err_formatter
            (Ptop_def [ last_eval ])
        in
        if success then exit 0 else exit 1
  with exn ->
    Location.report_exception Format.err_formatter exn;
    exit 2
