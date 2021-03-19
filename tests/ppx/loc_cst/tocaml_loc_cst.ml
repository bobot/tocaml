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
      Tocaml_loc_cst_runtime.loc_start = [%e build_pos ~loc loc'.loc_start];
      Tocaml_loc_cst_runtime.loc_end = [%e build_pos ~loc loc'.loc_end];
    }]

let build_loc ~loc (loc' : Location.t) v =
  [%expr
    {
      Tocaml_loc_cst_runtime.loc = [%e build_location ~loc loc'];
      Tocaml_loc_cst_runtime.txt = [%e v];
    }]

let add_loc_to_cst =
  object
    inherit Ast_traverse.map as super

    val pattern = Ast_pattern.(pexp_constant __)

    method! expression e =
      let e = super#expression e in
      Ast_pattern.parse pattern e.pexp_loc
        ~on_error:(fun () -> e)
        e
        (fun _ -> build_loc ~loc:e.pexp_loc e.pexp_loc e)

    method! payload e = e
  end

let impl (stritem : structure) = add_loc_to_cst#structure stritem

let instrument = Driver.Instrument.make ~position:Before impl

(** Note: enclose_impl can't be used because it is evaluated before the rule are run even if the result should be inserted after *)
let () = Driver.register_transformation ~instrument "tocaml_ppx_loc_cst"
