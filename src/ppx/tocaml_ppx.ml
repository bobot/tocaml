open Ppxlib

(** todo: should this global variable be removed? *)
let imports = Queue.create ()

let already_loaded = Hashtbl.create 10

let get_filename ctxt path =
  let source =
    ctxt |> Expansion_context.Extension.code_path |> Code_path.file_path
  in
  let dir =
    match source with
    | "//toplevel//" | "-" -> Sys.getcwd ()
    | _ -> Filename.dirname source
  in
  Filename.concat dir path

let unique_file_name file =
  let digest = Digest.file file in
  let digest = Digest.to_hex digest in
  Printf.sprintf "TOCAML_private_%s" digest

let open_file file =
  let cin = open_in file in
  let impl =
    Fun.protect
      ~finally:(fun () -> close_in cin)
      (fun () ->
        let lexbuf = Lexing.from_channel ~with_positions:true cin in
        Parse.implementation lexbuf)
  in
  impl

let expand ~ctxt relative_filename =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let file = get_filename ctxt relative_filename in
  let id = unique_file_name file in
  if not (Hashtbl.mem already_loaded id) then (
    Hashtbl.add already_loaded id ();
    let str = open_file file in
    Queue.push (id, loc, str) imports);
  Ast_builder.Default.pmod_ident ~loc { loc; txt = Lident id }

let my_extension =
  Extension.V3.declare "import" Extension.Context.module_expr
    Ast_pattern.(single_expr_payload (estring __))
    expand

let rule = Ppxlib.Context_free.Rule.extension my_extension

let impl (stritem : structure) =
  let fold acc (id, loc, str) =
    Ast_builder.Default.(
      pstr_module ~loc
      @@ module_binding ~loc ~name:{ loc; txt = Some id }
           ~expr:(pmod_structure ~loc str))
    :: acc
  in
  let start = Queue.fold fold [] imports in
  start @ stritem

(** Note: enclose_impl can't be used because it is evaluated before the rule are run even if the result should be inserted after *)
let () = Driver.register_transformation ~rules:[ rule ] ~impl "my_ext"
