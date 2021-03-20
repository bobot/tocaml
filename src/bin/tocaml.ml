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

module JSON = struct
  open Yojson

  let print_out_value ppf tree =
    let open Outcometree in
    let open Format in
    let rec conv_ident = function
      | Oide_ident s -> s.printed_name
      | Oide_dot (_, id) -> id
      | Oide_apply (_, id) -> conv_ident id
    in
    let atom fmt = Format.kasprintf (fun s -> `String s) fmt in
    let rec conv : _ -> Safe.t = function
      | Oval_int i -> `Int i
      | Oval_int32 i -> `Intlit (asprintf "%lil" i)
      | Oval_int64 i -> `Intlit (asprintf "%LiL" i)
      | Oval_nativeint i -> `Intlit (asprintf "%nin" i)
      | Oval_float f -> `Float f
      | Oval_char c -> atom "%C" c
      | Oval_string (s, _, _) -> `String s
      | Oval_list tl | Oval_array tl -> `List (List.map conv tl)
      | Oval_tuple tl -> `Tuple (List.map conv tl)
      | Oval_constr (name, []) -> `Variant (conv_ident name, None)
      | Oval_constr (name, tl) ->
          `Variant (conv_ident name, Some (`List (List.map conv tl)))
      | Oval_variant (name, arg) -> `Variant (name, Option.map conv arg)
      | Oval_stuff s -> `String s
      | Oval_record fel ->
          `Assoc (List.map (fun (s, v) -> (conv_ident s, conv v)) fel)
      | Oval_ellipsis -> assert false (* max depth and step set to maxint *)
      | Oval_printer f -> atom "%t" f
    in
    let sexp = conv tree in
    Safe.pretty_print ppf sexp

  let print_out_phrase ppf = function
    | Outcometree.Ophr_eval (outv, _) -> print_out_value ppf outv
    | Ophr_signature [] -> ()
    | Ophr_signature _ | Ophr_exception (_, _) -> assert false
end

let run file mode `V0 =
  try
    let cin, file =
      match file with
      | Some "-" | None -> (stdin, "-")
      | Some file -> (open_in file, file)
    in
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
    let print_out =
      match mode with
      | `Sexp -> Sexp.print_out_phrase
      | `JSON -> JSON.print_out_phrase
      | `OCaml -> !Oprint.out_phrase
    in
    Oprint.out_phrase := print_out;
    Location.input_name := file;
    Sys.catch_break true;
    Toploop.run_hooks Toploop.After_setup;
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

open Cmdliner

let () =
  let file = Arg.(value & pos 1 (some string) None (info ~docv:"Info" [])) in
  let mode =
    Arg.(
      value
      & vflag `Sexp
          [
            (`Sexp, info ~doc:"Output the result using s-expression" [ "sexp" ]);
            (`JSON, info ~doc:"Output the result using JSON format" [ "json" ]);
            (`OCaml, info ~doc:"Output the result as OCaml values" [ "ocaml" ]);
          ])
  in
  let version =
    Arg.(
      required
      & vflag None [ (Some `V0, info ~doc:"Version 0 (experimental)" [ "v0" ]) ])
  in
  let cmd = Term.(const run $ file $ mode $ version) in
  let res =
    Term.(
      eval
        ( cmd,
          info
            ~doc:
              "Print the result of the execution of configuration file written \
               in OCaml"
            "tocaml" ))
  in
  Term.exit res
