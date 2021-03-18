let () = Ppxlib.Driver.standalone ()

(* let read_input prompt buffer len =
 *   let prompt =
 *     if prompt <> "" && prompt.[0] = '#' then
 *       String.mapi (fun i c -> if i = 0 then '%' else c) prompt
 *     else prompt
 *   in
 *   output_string stdout prompt;
 *   flush stdout;
 *   let i = ref 0 in
 *   try
 *     while true do
 *       if !i >= len then raise Exit;
 *       let c = input_char stdin in
 *       Bytes.set buffer !i c;
 *       Option.iter (fun b -> Buffer.add_char b c) !Location.input_phrase_buffer;
 *       incr i;
 *       if c = '\n' then raise Exit
 *     done;
 *     (!i, false)
 *   with
 *   | End_of_file -> (!i, true)
 *   | Exit -> (!i, false)
 * 
 * let () =
 *   Toploop.read_interactive_input := read_input;
 *   Topmain.main () *)
