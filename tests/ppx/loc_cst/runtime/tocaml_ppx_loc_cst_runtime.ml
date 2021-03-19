type location = { loc_start : Lexing.position; loc_end : Lexing.position }

type 'a loc = { loc : location; txt : 'a }
