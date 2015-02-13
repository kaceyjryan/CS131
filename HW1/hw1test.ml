(* subset tests *)

let my_subset_test0 = subset [] [];;
let my_subset_test1 = subset ["cat";"dog"] ["fish";"dog";"llama";"cat"];;
let my_subset_test2 = not (subset ["cat";"dog";"fish";"llama"] ["cat";"fish";"llama";"llama"]);;

(* proper_subset tests *)

let my_proper_subset_test0 = not (proper_subset [] []);;
let my_proper_subset_test1 = proper_subset ["llama";"llama";"llama";"llama"] ["llama";"duck"];;
let my_proper_subset_test2 = proper_subset ["cat";"dog";"fish"] ["llama";"dog";"cat";"llama";"fish";"dog"];;

(* equal_sets tests *)

let my_equal_sets_test0 = equal_sets [] [];;
let my_equal_sets_test1 = equal_sets ["llama";"duck"] ["llama";"llama";"llama";"duck"];;
let my_equal_sets_test2 = not (equal_sets ["llama";"llama";"duck"] ["llama";"duck";"cat"]);;

(* set_diff tests *)

let my_set_diff_test0 = equal_sets (set_diff [] []) [];;
let my_set_diff_test1 = equal_sets (set_diff ["llama"] ["llama";"duck"]) [];;
let my_set_diff_test2 = equal_sets (set_diff ["llama";"llama";"duck"] ["llama"]) ["duck"];;
let my_set_diff_test3 = equal_sets (set_diff ["llama";"duck"] []) ["duck";"llama"];;
let my_set_diff_test4 = equal_sets (set_diff [] ["llama"]) [];;

(* computed_fixed_point tests *)

let my_computed_fixed_point_test0 = computed_fixed_point (=) (fun x -> (x*x) - (2*x)) 3 = 3;;
let my_computed_fixed_point_test1 = computed_fixed_point (=) (sin) 0. = 0.;;

(* computed_periodic_point tests *)

let my_computed_periodic_point_test0 = computed_periodic_point (=) (fun x -> x*x - 2*x) 1 3 = 3;;
let my_computed_periodic_point_test1 = computed_periodic_point (=) (sin) 1 0. = 0.;;
let my_computed_periodic_point_test2 = computed_periodic_point (=) (fun x -> -x) 2 1 = 1;;
let my_computed_periodic_point_test2 = computed_periodic_point (=) (fun x -> -x) 4 (-1) = (-1);;
(* filter_blind_alleys tests *)

type non_terminals = 
    | Cat
    | Dog
    | Llama

let rules = 
    [ Cat, [N Dog]; Dog, [N Llama]; Llama, [N Cat]; Llama, [T "terminal"] ]

let my_filter_blind_alleys_test0 = 
filter_blind_alleys (Llama, rules) = (Llama, rules);;

let my_filter_blind_alleys_test1 =
    filter_blind_alleys (Dog, List.tl rules) = (Dog, [Dog, [N Llama]; Llama, [T "terminal"]]);;
