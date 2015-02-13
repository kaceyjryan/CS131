%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Time Testing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% FD Ken Ken %%%%%%%%%%%
%statistics, kenken(
%   4,
%   [
%   +(6, [1-1, 1-2, 2-1]),
%   *(96, [1-3, 1-4, 2-2, 2-3, 2-4]),
%   -(1, 3-1, 3-2),
%   -(1, 4-1, 4-2),
%   +(8, [3-3, 4-3, 4-4]),
%   *(2, [3-4])
%   ],
%   T
%   ), statistics .
%
% Time range for kenken example above: 0.000s - 0.001s retrieving the 6 different results
%

%%%%%%%%%% Plain Ken Ken %%%%%%%%%%%%
%statistics, plain_kenken(
%   4,
%   [
%   +(6, [1-1, 1-2, 2-1]),
%   *(96, [1-3, 1-4, 2-2, 2-3, 2-4]),
%   -(1, 3-1, 3-2),
%   -(1, 4-1, 4-2),
%   +(8, [3-3, 4-3, 4-4]),
%   *(2, [3-4])
%   ],
%   T
%   ), statistics .
%
% Time range for kenken example above: ~0.200s - 1.462s retrieving the 6 different results

% The plain kenken was significantly slower, as expected.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Start of Ken Ken Solver %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%% Check Constraints %%%%%%%%%%%%%%%%%%%%%%%%%%%

% Addition %
apply(+(Add, []), Answer, _) :- Answer #= Add.
apply(+(Add, [Head | Tail]), Answer, T) :-
    get(Head, T, Entry),
    TempAnswer = Entry + Answer,
    apply(+(Add, Tail), TempAnswer, T) .

% Multiplication %
apply(*(Mult, []), Answer, _) :- Answer #= Mult.
apply(*(Mult, [Head | Tail]), Answer, T) :-
    get(Head, T, Entry),
    TempAnswer = Entry * Answer,
    apply(*(Mult, Tail), TempAnswer, T) .

% Subtraction (Both directions, j-k and k-j)%
apply(-(Sub, J, K), T) :-
    get(J, T, A),
    get(K, T, B),
    A - B #= Sub.
apply(-(Sub, J, K), T) :-
    get(J, T, A),
    get(K, T, B),
    B - A #= Sub.

% Division (Both directions, j/k and k/j)%
apply(/(Div, J, K), T) :-
    get(J, T, A),
    get(K, T, B),
    A rem B #= 0,
    A / B #= Div.
apply(/(Div, J, K), T) :-
    get(J, T, A),
    get(K, T, B),
    B rem A #= 0,
    B / A #= Div.

apply(+(Add, [Head|Tail]), T) :-
    apply(+(Add, [Head|Tail]), 0, T).

apply(*(Mult, [Head|Tail]), T) :-
    apply(*(Mult, [Head|Tail]), 1, T).

%%%% Begin Master Check on Constraints %%%%%

check([], _) .
check([Head|Tail], T) :-
    apply(Head, T),
    check(Tail, T).

%%%%%%%%%%%%%%%%%%%% Check Rows %%%%%%%%%%%%%%%%%%%%%%

rows([]).
rows([Head|Tail]) :-
    fd_all_different(Head),
    rows(Tail).

%%%%%%%%%%%%%%%%%%%% Check Columns %%%%%%%%%%%%%%%%%%%

getHeads([[Head | Tail]], [Head], [Tail]).
getHeads([[TempHead | TempTail] | Tail], Heads, Tails) :-
    getHeads(Tail, HeadsRemaining, TailsRemaining),
    Heads = [TempHead | HeadsRemaining],
    Tails = [TempTail | TailsRemaining].

cols([[] | Tail]).
cols([[Head|Tail]|Tail2]) :-
    getHeads([[Head|Tail]|Tail2], Heads, Tails),
    fd_all_different(Heads),
    cols(Tails).

%%%%%%%%%%%%%%% Start Row/column Checks for FD %%%%%%%%%%%%%%

table(T) :-
    cols(T),
    rows(T).

%%%%%%%%%%%%%%%%% Create Table %%%%%%%%%%%%%%%%%%%%

create_table(N, T) :-
    length(T, N),
    get_rows(N, T).

get_rows(N, []).
get_rows(N, [Head | Tail]) :-
    length(Head, N),
    fd_domain(Head, 1, N),
    get_rows(N, Tail).

%%%%%%%%%%%%%% Get Entry %%%%%%%%%%%%%%%%%%%%%

get(R-C, T, Entry) :-
    nth1(R, T, Row),
    nth1(C, Row, Entry) .

%%%%%%%%%%%%%% Ken Ken Solver %%%%%%%%%%%%%%%%%

labeling([]).
labeling([Head | Tail]) :-
    fd_labeling(Head),
    labeling(Tail).

kenken(N, C, T) :-
    create_table(N, T),
    check(C, T),
    table(T),
    labeling(T).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% Start of Plain Ken Ken (No more FD predicates) %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%% Check Plain Constraints %%%%%%%%%%%%%%%%%%%%%%%

% Addition %
plain_apply(+(Add, []), Answer, _) :- Answer =:= Add.
plain_apply(+(Add, [Head | Tail]), Answer, T) :-
    get(Head, T, Entry),
    TempAnswer = Entry + Answer,
    plain_apply(+(Add, Tail), TempAnswer, T).

% Multiplication %
plain_apply(*(Mult, []), Answer, _) :- Answer =:= Mult.
plain_apply(*(Mult, [Head | Tail]), Answer, T) :-
    get(Head, T, Entry),
    TempAnswer = Entry * Answer,
    plain_apply(*(Mult, Tail), TempAnswer, T).

% Subtraction (Both directions, j-k and k-j) %
plain_apply(-(Sub, J, K), T) :-
    get(J, T, A),
    get(K, T, B),
    Sub is A - B.
plain_apply(-(Sub, J, K), T) :-
    get(J, T, A),
    get(K, T, B),
    Sub is B - A.

% Division (Both directions, j/k and k/j)%
plain_apply(/(Div, J, K), T) :-
    get(J, T, A),
    get(K, T, B),
    0 =:= A rem B,
    Div is A // B.
plain_apply(/(Div, J, K), T) :-
    get(J, T, A),
    get(K, T, B),
    B rem A =:= 0,
    Div is B // A.

plain_apply(+(Add, [Head|Tail]), T) :-
    plain_apply(+(Add, [Head|Tail]), 0, T).

plain_apply(*(Mult, [Head|Tail]), T) :-
    plain_apply(*(Mult, [Head|Tail]), 1, T).

%% Replace fd_all_different %%%
plain_diff(L) :-
    \+ (select(X,L,R), memberchk(X,R)).

%%%% Column Checks %%%%%
plain_cols([[] | T]).
plain_cols([[Head|Tail]|Tail2]) :-
    getHeads([[Head|Tail]|Tail2], Heads, Tails),
    plain_diff(Heads),
    plain_cols(Tails).

%%%%% Row Checks %%%%%%
plain_rows([]).
plain_rows([Head|Tail]) :-
    plain_diff(Head),
    plain_rows(Tail).

%%%%%%%% Start Row/Column checks for Plain %%%%%%%%%%

plain_table(T) :-
    plain_rows(T),
    plain_cols(T).

%%%%%%%%%% Create Domain %%%%%%%%%%%%%%

set_domain(L, L, _).
set_domain(X, Min, Max) :-
    N is Min + 1,
    N =< Max,
    set_domain(X, N, Max).

set_list_domain([], _, _).
set_list_domain([Head | Tail], Min, Max) :-
    set_domain(Head, Min, Max),
    set_list_domain(Tail, Min, Max).

%%%%%%%%%%%%%% Create the Plain Table %%%%%%%%%%%%%%%

create_plain_table(N, T) :-
    length(T, N),
    create_plain_rows(N, T).

create_plain_rows(N, []).
create_plain_rows(N, [Head | Tail]) :-
    length(Head, N),
    set_list_domain(Head, 1, N),
    plain_diff(Head),
    create_plain_rows(N, Tail).

%%%%% Begin Master Check on Plain Constraints %%%%%

plain_check([], _).
plain_check([Head|Tail], T) :-
    plain_apply(Head, T),
    plain_check(Tail, T).

%%%%%%%%%%%%%%% Plain Ken Ken Solver %%%%%%%%%%%%%%%%%%%%%%%%%%%%

plain_kenken(N, C, T) :-
    create_plain_table(N, T),
    plain_check(C, T),
    plain_table(T).