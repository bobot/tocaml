open Ppxlib

let build_pos ~loc (pos : Lexing.position) =
  Ast_builder.Default.(
    [%expr
      {
        Lexing.pos_fname = [%e estring ~loc pos.pos_fname];
        pos_lnum = [%e eint ~loc pos.pos_lnum];
        pos_bol = [%e eint ~loc pos.pos_bol];
        pos_cnum = [%e eint ~loc pos.pos_cnum];
      }])

let build_location ~loc (loc' : Location.t) =
  [%expr
    {
      Tocaml_ppx_loc_cst_runtime.loc_start = [%e build_pos ~loc loc'.loc_start];
      Tocaml_ppx_loc_cst_runtime.loc_end = [%e build_pos ~loc loc'.loc_end];
    }]

let build_loc ~loc (loc' : Location.t) v =
  [%expr
    {
      Tocaml_ppx_loc_cst_runtime.loc = [%e build_location ~loc loc'];
      Tocaml_ppx_loc_cst_runtime.txt = [%e v];
    }]

open Ppxlib

let var =
  Re.(
    compile
      (seq
         [
           char '$';
           alt
             [
               seq [ char '{'; group (rep1 @@ compl [ char '}' ]); char '}' ];
               group (rep1 alnum);
             ];
         ]))

let subst ~loc str =
  let l = Re.split_full var str in
  let l =
    List.map
      Ast_builder.Default.(
        function
        | `Text s -> estring ~loc s
        | `Delim g ->
            let (i, _), s =
              if Re.Group.test g 1 then (Re.Group.offset g 1, Re.Group.get g 1)
              else (Re.Group.offset g 2, Re.Group.get g 2)
            in
            let lb = Lexing.from_string s in
            lb.lex_start_p <-
              { loc.loc_start with pos_cnum = loc.loc_start.pos_cnum + i };
            lb.lex_curr_p <- lb.lex_start_p;
            [%expr [%e Parse.expression lb].txt])
      l
  in
  let e =
    match l with
    | [] -> Ast_builder.Default.estring ~loc ""
    | [ e ] -> e
    | l ->
        [%expr
          Tocaml_ppx_loc_cst_runtime.concat
            [%e Ast_builder.Default.elist ~loc l]]
  in
  build_loc ~loc loc e

let add_loc_to_cst =
  object
    inherit Ast_traverse.map as super

    val pattern = Ast_pattern.(estring __)

    method! expression e =
      let e = super#expression e in
      Ast_pattern.parse pattern e.pexp_loc
        ~on_error:(fun () -> e)
        e
        (fun s -> subst ~loc:e.pexp_loc s)

    method! payload e = e
  end

let impl (stritem : structure) = add_loc_to_cst#structure stritem

let instrument = Driver.Instrument.make ~position:Before impl

(** Note: enclose_impl can't be used because it is evaluated before the rule are run even if the result should be inserted after *)
let () = Driver.register_transformation ~instrument "tocaml_ppx_loc_cst"
