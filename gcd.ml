module L = Llvm

let _ =
let context = L.global_context () in
let the_module = L.create_module context "ocaml-llvm-examples" in


(* Get types from the context *)
let i32_t      = L.i32_type    context
and i8_t       = L.i8_type     context in

let printf_t : L.lltype =
  L.var_arg_function_type i32_t [| L.pointer_type i8_t |] in
let printf_func : L.llvalue =
  L.declare_function "printf" printf_t the_module in

let gcd_ref_func =
  let ftype = L.function_type i32_t [|i32_t; i32_t|] in
  let func = L.define_function "gcd_ref" ftype the_module in

  (* change param names *)
  let a = Array.get (L.params func) 0 in
  let () = L.set_value_name "a" a in
  let b = Array.get (L.params func) 1 in
  let () = L.set_value_name "b" b in

  (* entry *)
  let entry_block = L.entry_block func in
  let whilebb = L.append_block context "while" func in
  let while_bodybb = L.append_block context "while_body" func in
  let thenbb = L.append_block context "then" func in
  let elsebb = L.append_block context "else" func in
  let if_endbb = L.append_block context "if_end" func in
  let while_endbb = L.append_block context "while_end" func in
  let builder = L.builder_at_end context entry_block in
  let a1 = L.build_alloca i32_t "a1" builder in
  let _ = L.build_store a a1 builder in
  let b2 = L.build_alloca i32_t "b2" builder in
  let _ = L.build_store b b2 builder in
  let _ = L.build_br whilebb builder in (* end of entry *) 

  (* while *)
  let builder = L.builder_at_end context whilebb in
  let a3 = L.build_load a1 "a3" builder in
  let b4 = L.build_load b2 "a4" builder in
  let tmp = L.build_icmp L.Icmp.Ne a3 b4 "tmp" builder in
  let _ = L.build_cond_br tmp while_bodybb while_endbb builder in

  (* while_body *)
  let builder = L.builder_at_end context while_bodybb in
  let b5 = L.build_load b2 "b5" builder in
  let a6 = L.build_load a1 "a6" builder in
  let tmp7 = L.build_icmp L.Icmp.Slt b5 a6 "tmp7" builder in
  let _ = L.build_cond_br tmp7 thenbb elsebb builder in

  (* then *)
  let builder = L.builder_at_end context thenbb in
  let a8 = L.build_load a1 "a8" builder in
  let b9 = L.build_load b2 "b9" builder in
  let tmp10 = L.build_sub a8 b9 "tmp10" builder in
  let _ = L.build_store tmp10 a1 builder in
  let _ = L.build_br if_endbb builder in

  (* else *)
  let builder = L.builder_at_end context elsebb in
  let b11 = L.build_load b2 "b11" builder in
  let a12 = L.build_load a1 "a12" builder in
  let tmp13 = L.build_sub b11 a12 "tmp13" builder in
  let _ = L.build_store tmp13 b2 builder in
  let _ = L.build_br if_endbb builder in

  (* if_end *)
  let builder = L.builder_at_end context if_endbb in
  let _ = L.build_br whilebb builder in

  (* while_end *)
  let builder = L.builder_at_end context while_endbb in
  let a14 = L.build_load a1 "a14" builder in

  let int_format_str = L.build_global_stringptr "Running gcd ref\n" "gcd_ref"
  builder in
  let _ = L.build_call printf_func [|int_format_str|] "res" builder in
  let _ = L.build_ret a14 builder in
  func
in

let _ =
  let ftype = L.function_type i32_t [||] in
  let func = L.define_function "main" ftype the_module in
  let entry_block = L.entry_block func in
  let builder = L.builder_at_end context entry_block in
  let mysterious_str = L.build_global_stringptr "Mysterious number: %d\n"
    "mysterious" builder in
  let gcd_res = L.build_call gcd_ref_func [|L.const_int 
  i32_t 10; L.const_int
    i32_t 20|] "gcd_res" builder in
  let _ = L.build_call printf_func [|mysterious_str; gcd_res|]
    "res" builder in
  L.build_ret (L.const_int i32_t 0) builder
in

print_endline (L.string_of_llmodule the_module)
