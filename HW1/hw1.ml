(* CS 131 Homework 1 *)

(* 1. Function subset *)

let rec subset a b =
if a == [] 
then true 
else (subset (List.tl a) b && List.mem (List.hd a) b);;

(* 2. Function proper_subset *)

let proper_subset a b =
(subset a b) && not (subset b a);;

(* 3. Function equal_sets *)

let equal_sets a b =
if a != [] || b != [] 
then (subset a b) && (subset b a)
else true;;

(* 4. Function set_diff *)

let set_diff a b =
List.filter (fun x -> (List.mem x b) = false) a;;

(* 5. Function computed_fixed_point *)

let rec computed_fixed_point eq f x =
if eq x (f x) 
then x
else computed_fixed_point eq f (f x);;

(* 6. Function computed_periodic_point *)

(* Works but it uses a list*)
(*
let rec computed_periodic_point_helper eq f p x a =
if List.length a > p && eq (f x) (List.nth a (p-1)) 
then f x
else computed_periodic_point_helper eq f p (f x) ([f x]@a);;

let computed_periodic_point eq f p x =
if p == 0
then x
else computed_periodic_point_helper eq f p x [x];;
*)

(* Doesnt use other data structure *)

let rec computed_periodic_point_helper f p x=
if p <= 0 
then x
else f (computed_periodic_point_helper f (p-1) x);;

let rec computed_periodic_point eq f p x =
if eq x (computed_periodic_point_helper f p x)
then x
else computed_periodic_point eq f p (f x);;

(* 7. Function filter_blind_alleys *)

type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

(* check_terminal: Checks if a value is a terminal*)
let rec check_terminal terminal_list terminal =
    match terminal with 
      (*If nonterminal check if its on the list*)
      | N a -> 
      if List.mem_assoc a terminal_list 
      then true 
      else false
      (* Otherwise its terminal *)
      | T _ -> true ;;

(* parse: Uses check_terminal to parse a rule and flag whether it terminates or not *)
let rec parse terminal_list rule = 
    match rule with 
        | (a, terminals) ->
        if List.for_all (check_terminal terminal_list) terminals 
        then true 
        else false;;

(* find_terminals: finds the known terminals from an initial list of rules *)
let rec find_terminals terminal_list rules init_length = 
    let list_T = List.filter (parse terminal_list) rules 
    in 
    let end_length = List.length list_T 
    in
    if init_length = end_length 
    then list_T 
    else find_terminals list_T rules end_length;;

(* reverse_filter: reverses the parameters of list.Filter to use it in filter_blind_alleys*)
let reverse_filter list1 member = 
    if List.mem member list1 
    then true
    else false;;

(* filter_blind_alleys: The function first finds the terminals of the grammar then it
works in reverse adding the terminals to their list until it stops adding terminals and then
it returns the list.*)

let rec filter_blind_alleys g = 
    match g with 
        | (head, rules) ->
        (*identify terminals*)
	let terminal_rules = find_terminals [] rules 0 
        in
        (* filter g *) 
        let g_rules = List.filter (reverse_filter terminal_rules) rules 
        in
        (head, g_rules);;
