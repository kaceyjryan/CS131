(* Homework 2 Implementation *)

open List;;

type ('nonterminal, 'terminal) symbol = 
  | N of 'nonterminal
  | T of 'terminal

(* helper funtions for convert_grammar *)

(* left_rules: This helper function takes in the rules list from gram1 and 
a list of known values on the left side of this list. It returns a combined 
list of all left side values. *)
let rec left_rules rules left_list =
    match rules with 
      | [] -> left_list
      | h::t -> match h with (* find head and its left side *)
                  | (a,b) -> 
                        if (List.mem a left_list) (* check if its already on the list *)
                        then left_rules t left_list (* recursively call on tail *)
                        else left_rules t (left_list@[a]);; (* add to list then recursively call on tail *)

(* match_grammer: This function matches the rules on the rules list to their 
respective left sides forming the new grammar *)
let rec match_grammar rules match_list = 
    match rules with 
      | [] -> []
      | h::t -> match h with (* find head and its left side *)
                  | (a,b) ->
                        if (a = match_list) (* if the left side matches *)
                        then b::(match_grammar t match_list) (* then append it *)
                        else match_grammar t match_list;; (* otherwise move on *)

(* convert_grammar: This creates a new grammar from a hw1 style grammar by 
matching all of the right side values with their respective left side values
and then combines the list with the added rule *)

let rec convert_grammar gram1 = 
    match gram1 with 
      | (start, rules) ->
          let left_list = left_rules rules [] in
          let added_rule = List.map (match_grammar rules) left_list in
          let combined = List.combine left_list added_rule in
          (start, (function a -> List.assoc a combined));;

(* analyze_rules: Checks that the rules are of an okay length. If T, checks if the first rule
has a string match with the fragment, if true then it is supposed to call the acceptor but as
 of now I haven't been able to get this to work. If it is false, then it returns None. Otherwise
the first_rule is N and it must restart the checks with this nonterm *)
let rec analyze_rules rules first_rule other_rules frag derivation =
    if List.length other_rules >= List.length frag (* rules list is too long *)
    then None (* Can't match a fragment so return None *)
    else (* rules is an okay length *)
      match first_rule with
        | T term -> 
              if (term = (List.hd frag)) (* There is a match *)
              then Some(derivation, List.tl frag) (* Should call acceptor with other_rules but not implemented correctly)*)
              (*  Attempted call to check_and with other_rules but it FAILED *)
              else None (* no match *)
        | N nonterm -> 
              start_checks rules nonterm frag derivation (* restart with N rule *)

(* start_checks: Calls check_or on the symbol and rules to see if it can in fact return Some.
If none of them succeed then it just returns None*)
and start_checks rules symbol frag derivation = 
   match (rules symbol) with
     |  []  -> None (* Nothing succeeded so return None automatically*)
     |  other_rules ->
          check_or rules symbol other_rules frag derivation  (* Only one value needs to return Some *)

(* check_or: Calls check_and on the head and if all the values on the right side return "Some"
then it can do the same. It then appends the rule to the derivative and returns it and the fragment *)
and check_or rules symbol a_list frag derivation = 
   match a_list with
     | []   -> None
     | h::t ->
        let rule_check = check_and rules symbol h frag derivation in
        match rule_check with
          |  None -> 
                check_or rules symbol t frag derivation
          |  Some(deriv,fragment) ->(* matched part of the fragment *) 
                let der = List.append [(symbol,h)] deriv in (*get the derivation set *)
                Some(der, fragment)

(* check_and: Analyzes the head of the list with the tail. The tail is supposed to be checked in the acceptor
but this was never implemented correctly. If it succeeds in the analyze then it should continue with the tail
but there were issues in returning the derivative and the fragment *)
and check_and rules symbol a_list frag derivation  = 
    match a_list with
      | [] -> Some(derivation, frag)
      | h::t -> 
         let rule_check = analyze_rules rules h t frag derivation in (* check if there is a successful path with acceptor *)
         match rule_check with
           |  None -> 
                    None 
           |  Some(deriv,fragment) -> 
                    check_and rules symbol t (List.tl frag) deriv;; (* Not implemented correctly; should call on tail *)     

(*  parse_prefix:  Creates a grammar and then it calls start_checks if it returns none then the value is none,
otherwise the acceptor is applied and that value is returned. *)
let rec parse_prefix gram accept frag = 
    match gram with 
      | (start, rules) ->
          let derivation = [] in
          let b = start_checks rules start frag derivation in (* makes the fragments and derivation for acceptor below *)
          match b with
            |  None -> None
            |  Some(deriv, fragment) -> accept deriv fragment;;