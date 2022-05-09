module L = Llvm

let _ =
let context = L.global_context () in
let the_module = L.create_module context "ocaml-llvm-examples" in


(* Get types from the context *)
let i32_t      = L.i32_type    context
and i8_t       = L.i8_type     context
and void_t     = L.void_type   context in


let printf_t : L.lltype =
  L.var_arg_function_type i32_t [| L.pointer_type i8_t |] in
let printf_func : L.llvalue =
  L.declare_function "printf" printf_t the_module in

(* Built-in functions *)
let print_int_func =
  let ftype = L.function_type void_t [|i32_t|] in
  let func = L.define_function "print_int_func" ftype the_module in

  let param = Array.get (L.params func) 0 in
  let entry_block = L.entry_block func in
  let builder = L.builder_at_end context entry_block in
  let int_format_str = L.build_global_stringptr "%d\n" "fmt" builder in
  let _ = L.build_call printf_func [|int_format_str; param|] "res" builder in
  let _ = L.build_ret_void builder in
  func
in

let _ =
  let ftype = L.function_type i32_t [||] in
  let func = L.define_function "main" ftype the_module in
  let entry_block = L.entry_block func in
  let builder = L.builder_at_end context entry_block in
  let arr = L.const_array (L.array_type i32_t 2)
  [|L.const_int i32_t 3; L.const_int i32_t 9|] in
  let arr_ptr = L.build_alloca (L.array_type i32_t 2) "x" builder in
  let _ = L.build_store arr arr_ptr builder in
  let arr_re = L.build_extractvalue arr 1 "y" builder in
  let _ = L.build_call print_int_func [|arr_re|] "" builder in
  L.build_ret (L.const_int i32_t 0) builder
in

print_endline (L.string_of_llmodule the_module)
