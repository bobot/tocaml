type location = { loc_start : Lexing.position; loc_end : Lexing.position }

type 'a loc = { loc : location; txt : 'a }

let dummy_loc = { loc_start = Lexing.dummy_pos; loc_end = Lexing.dummy_pos }

let concat = String.concat ""

let of_int i = { loc = dummy_loc; txt = Stdlib.string_of_int i }
