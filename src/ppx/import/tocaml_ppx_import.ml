open Ppxlib

let last_eval_name = "tocaml_last_eval_name"

let imports = Stack.create ()

type stage =
  | Loaded of { last_eval : bool }
      (** indicate if it can be used as an expression *)
  | Loading

let already_loaded = Hashtbl.create 10

let () =
  let open Driver.Cookies in
  add_handler (fun t ->
      let l =
        get t "tocaml.already_loaded"
          Ast_pattern.(
            elist (pack2 (pexp_tuple (estring __ ^:: eint __ ^:: nil))))
      in
      Option.iter
        (List.iter (fun (s, i) ->
             Hashtbl.replace already_loaded s (Loaded { last_eval = i = 0 })))
        l);
  add_post_handler (fun t ->
      let l =
        Hashtbl.fold
          (fun k s acc ->
            match s with
            | Loading ->
                Location.raise_errorf "Internal error: %s still loading" k
            | Loaded { last_eval } -> (k, if last_eval then 0 else 1) :: acc)
          already_loaded []
      in
      let loc = Location.none in
      set t "tocaml.already_loaded"
        Ast_builder.Default.(
          elist ~loc
            (List.map
               (fun (s, i) -> pexp_tuple ~loc [ estring ~loc s; eint ~loc i ])
               l)))

type uri = Local of string | HTTP of string

let re_http =
  Re.(compile (seq [ start; str "http"; opt (char 's'); str "://" ]))

let get_filename ~ctxt path =
  if Re.execp re_http path then HTTP path
  else
    let source =
      ctxt |> Expansion_context.Base.code_path |> Code_path.file_path
    in
    let dir =
      match source with
      | "//toplevel//" | "-" -> Sys.getcwd ()
      | _ -> Filename.dirname source
    in
    Local (Filename.concat dir path)

let unique_file_name digest = Printf.sprintf "TOCAML_private_%s" digest

let get_sha = function
  | HTTP uri -> (
      match Curly.get uri with
      | Ok { body; _ } -> Digest.to_hex @@ Digest.string body
      | Error error ->
          Location.raise_errorf "Error during import of %S:%a" uri
            Curly.Error.pp error)
  | Local file -> Digest.to_hex @@ Digest.file file

let open_file file =
  match file with
  | HTTP uri -> (
      match Curly.get uri with
      | Ok { body; _ } ->
          let lexbuf = Lexing.from_string ~with_positions:true body in
          Parse.implementation lexbuf
      | Error error ->
          Location.raise_errorf "Error during import of %S:%a" uri
            Curly.Error.pp error)
  | Local file ->
      let cin = open_in file in
      Fun.protect
        ~finally:(fun () -> close_in cin)
        (fun () ->
          let lexbuf = Lexing.from_channel ~with_positions:true cin in
          Parse.implementation lexbuf)

(** Payload pattern for import *)
let pattern mode =
  let name = match mode with `Mod -> "import" | `Expr -> "exp" in
  Ast_pattern.(
    extension (string name)
      (single_expr_payload
         (alt
            (map_result (estring __) ~f:(fun f -> f []))
            (pexp_apply (estring __)
               (many (pair (of_func (fun _ _ _ f -> f)) (estring __)))))))

let bind_last_eval str =
  let rec get_eval acc = function
    | [] -> (List.rev acc, false)
    | [
        ({ Parsetree.pstr_desc = Pstr_eval (expr, attr); pstr_loc = loc } as
        last);
      ] ->
        let b =
          {
            pvb_pat =
              Ast_builder.Default.(ppat_var ~loc { loc; txt = last_eval_name });
            pvb_expr = expr;
            pvb_attributes = attr;
            pvb_loc = loc;
          }
        in
        let a =
          { last with Parsetree.pstr_desc = Pstr_value (Nonrecursive, [ b ]) }
        in
        (List.rev (a :: acc), true)
    | a :: l -> get_eval (a :: acc) l
  in
  get_eval [] str

let convert_direct_access =
  object (self)
    inherit Ast_traverse.map_with_expansion_context as super

    method expand ~ctxt ~loc relative_filename args =
      let sha_expected =
        match args with
        | [] -> None
        | [ sha ] -> Some sha
        | _ -> Location.raise_errorf ~loc "imports \"PATH|URL\" \"sha\"?"
      in
      let uri = get_filename ~ctxt relative_filename in
      let sha = get_sha uri in
      let id = unique_file_name sha in
      Option.iter
        (fun sha_expected ->
          if not (String.equal sha sha_expected) then
            Location.raise_errorf ~loc
              "File %s has a different digest %S than expected %S"
              relative_filename sha sha_expected)
        sha_expected;
      match Hashtbl.find already_loaded id with
      | exception Not_found ->
          Hashtbl.replace already_loaded id Loading;
          let str = open_file uri in
          let str = self#structure ctxt str in
          let str, last_eval = bind_last_eval str in
          Hashtbl.replace already_loaded id (Loaded { last_eval });
          Stack.push (id, loc, str) imports;
          (id, last_eval)
      | Loaded { last_eval } -> (id, last_eval)
      | Loading ->
          Location.raise_errorf ~loc "Loading cycles with %s, sha %s"
            relative_filename sha

    method! expression ctxt e =
      let e = super#expression ctxt e in
      let loc = e.pexp_loc in
      (* let pattern = Ast_pattern.(pexp_field (pexp_extension (pattern ())) __) in *)
      let pattern =
        Ast_pattern.(
          alt
            (pexp_field
               (pexp_extension (pattern `Mod))
               (map ~f:(fun f x -> f (`Mod x)) __))
            (map_result ~f:(fun f -> f `Expr) (pexp_extension (pattern `Expr))))
      in
      Ast_pattern.parse pattern e.pexp_loc
        ~on_error:(fun () -> e)
        e
        (fun file args lid ->
          let rec add_top id = function
            | Lident field -> Ldot (Lident id, field)
            | Ldot (lid, field) -> Ldot (add_top id lid, field)
            | Lapply _ -> (* not in a pexp_field *) assert false
          in
          let id, last_eval = self#expand ~ctxt ~loc file args in
          let lid =
            match lid with
            | `Expr when not last_eval ->
                Location.raise_errorf ~loc
                  "The file is imported as an expression it doesn't end with \
                   one"
            | `Expr -> Ldot (Lident id, last_eval_name)
            | `Mod lid -> add_top id lid
          in
          let loc = e.pexp_loc in
          Ast_builder.Default.pexp_ident ~loc { loc; txt = lid })

    method! module_expr ctxt e =
      let e = super#module_expr ctxt e in
      let loc = e.pmod_loc in
      let pattern = Ast_pattern.(pmod_extension (pattern `Mod)) in
      Ast_pattern.parse pattern e.pmod_loc
        ~on_error:(fun () -> e)
        e
        (fun file args ->
          let id, _ = self#expand ~ctxt ~loc file args in
          Ast_builder.Default.pmod_ident ~loc { loc; txt = Lident id })
  end

let preprocess_impl ctxt (stritem : structure) =
  let stritem = convert_direct_access#structure ctxt stritem in
  let fold acc (id, loc, str) =
    Ast_builder.Default.(
      pstr_module ~loc
      @@ module_binding ~loc ~name:{ loc; txt = Some id }
           ~expr:(pmod_structure ~loc str))
    :: acc
  in
  let start = Stack.fold fold [] imports in
  Stack.clear imports;
  start @ stritem

let () = Driver.V2.register_transformation ~preprocess_impl "tocaml_ppx_import"
