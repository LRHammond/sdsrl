% Prolog model for one

% Libraries
:- use_module(library(planning)).
:- use_module(library(lists)).
:- use_module(library(system)).
:- use_module(library(dcpf)).
:- use_module(library(distributionalclause)).
:- use_module(library(sst)).

% Options
:- set_options(default).
:- set_query_propagation(true).
:- set_inference(backward(lazy)).
:- set_current2nextcopy(false).

% Parameters
maxV(D,50):t <- true.
getparam(params) :- bb_put(user:spant,0),
                    setparam(
                        % Enable abstraction
                        true,
                        % Ratio of the samples reserved for the first action
                        1.0,
                        % Use correct formula (leave true)
                        true,
                        % Strategy to store V function
                        max,
                        % Execute action
                        best,
                        % most,
                        % Domain
                        propfalse,
                        % relfalse,
                        % Discount
                        0.95,
                        % Probability to explore in the beginning (first sample)
                        0.25,
                        % Probability to explore in the end (last sample)
                        0.15,
                        % Number of previous samples to use to estimate Q (larger is better but slower)
                        100,
                        % Max horizon span
                        100,
                        % Lambda init
                        0.9,
                        % Lambda final
                        0.9,
                        % UCBV
                        false,
                        % Decay
                        0.015,
                        % Action selection
                        softmax,
                        % egreedy,
                        % Pruning
                        0,
                        % WHeuInit
                        -0.1,
                        % WHeuFinal
                        -0.1),
                    !.

% Core Functions
Var:t+1 ~ val(Val) <- observation(Var) ~= Val.
observation(Var):t+1 ~ val(Val) <- Var:t+1 ~= Val.

% Helper Functions
dist(Obj1, Obj2):t ~ val(D) <- x_pos(Obj1):t ~= X1, y_pos(Obj1):t ~= Y1, x_pos(Obj2):t ~= X2, y_pos(Obj2):t ~= Y2, D is sqrt((X1 - X2)^2 + (Y1 - Y2)^2).
dist_gt(Obj1, Obj2, V):t <- dist(Obj1, Obj2):t ~= D, D > V.
dist_lt(Obj1, Obj2, V):t <- dist(Obj1, Obj2):t ~= D, D < V.
dist_eq(Obj1, Obj2, V):t <- dist(Obj1, Obj2):t ~= D, D = V.
right_of(Obj1, Obj2):t <- x_pos(Obj1):t ~= X1, x_pos(Obj2):t ~= X2, X1 > X2.
left_of(Obj1, Obj2):t <- x_pos(Obj1):t ~= X1, x_pos(Obj2):t ~= X2, X1 < X2.
above(Obj1, Obj2):t <- y_pos(Obj1):t ~= Y1, y_pos(Obj2):t ~= Y2, Y1 > Y2.
below(Obj1, Obj2):t <- y_pos(Obj1):t ~= Y1, y_pos(Obj2):t ~= Y2, Y1 < Y2.
bigger_x(Obj1, Obj2):t <- x_size(Obj1):t ~= XS1, x_size(Obj2):t ~= XS2, XS1 > XS2.
bigger_y(Obj1, Obj2):t <- y_size(Obj1):t ~= YS1, y_size(Obj2):t ~= YS2, YS1 > YS2.
bigger(Obj1, Obj2):t <- x_size(Obj1):t ~= XS1, x_size(Obj2):t ~= XS2, y_size(Obj1):t ~= YS1, y_size(Obj2):t ~= YS2, (XS1 * YS1) > (XS2 * YS2).
occupied_pos(X, Y):t <- is_object(Obj), map(X, Y, Obj):t.
unoccupied_pos(X, Y):t <- map(X, Y, no_object):t.
same_x_pos(Obj1, Obj2):t <- x_pos(Obj1):t ~= X1, x_pos(Obj2):t ~= X2, X1 = X2.
same_y_pos(Obj1, Obj2):t <- y_pos(Obj1):t ~= Y1, y_pos(Obj2):t ~= Y2, Y1 = Y2.
same_x_size(Obj1, Obj2):t <- x_size(Obj1):t ~= XS1, x_size(Obj2):t ~= XS2, XS1 = XS2.
same_y_size(Obj1, Obj2):t <- y_size(Obj1):t ~= YS1, y_size(Obj2):t ~= YS2, YS1 = YS2.
same_colour(Obj1, Obj2):t <- colour(Obj1):t ~= C1, colour(Obj2):t ~= C2, C1 = C2.
same_shape(Obj1, Obj2):t <- shape(Obj1):t ~= S1, shape(Obj2):t ~= S2, S1 = S2.
attributes(Obj, X_pos, Y_pos, X_size, Y_size, Colour, Shape, Nothing):t <- x_pos(Obj):t ~= X_pos, 
                                                                           y_pos(Obj):t ~= Y_pos, 
                                                                           x_size(Obj):t ~= X_size, 
                                                                           y_size(Obj):t ~= Y_size, 
                                                                           colour(Obj):t ~= Colour,
                                                                           shape(Obj):t ~= Shape,
                                                                           nothing(Obj):t ~= Nothing.

% Actions
adm(action(A)):t <- member(A, [u,l,d,r]).
\+(action_performed:0) <- true.
action_performed:t+1 <- action(A), member(A, [u,l,d,r]).

% Neighbours
nb1(Obj,Nb):t <- x_pos(Obj):t ~= X, y_pos(Obj):t ~= Y, NbX is X - 1, NbY is Y + 1, map(NbX, NbY, Nb):t.
nb2(Obj,Nb):t <- x_pos(Obj):t ~= X, y_pos(Obj):t ~= Y, NbX is X,     NbY is Y + 1, map(NbX, NbY, Nb):t.
nb3(Obj,Nb):t <- x_pos(Obj):t ~= X, y_pos(Obj):t ~= Y, NbX is X + 1, NbY is Y + 1, map(NbX, NbY, Nb):t.
nb4(Obj,Nb):t <- x_pos(Obj):t ~= X, y_pos(Obj):t ~= Y, NbX is X + 1, NbY is Y    , map(NbX, NbY, Nb):t.
nb5(Obj,Nb):t <- x_pos(Obj):t ~= X, y_pos(Obj):t ~= Y, NbX is X + 1, NbY is Y - 1, map(NbX, NbY, Nb):t.
nb6(Obj,Nb):t <- x_pos(Obj):t ~= X, y_pos(Obj):t ~= Y, NbX is X,     NbY is Y - 1, map(NbX, NbY, Nb):t.
nb7(Obj,Nb):t <- x_pos(Obj):t ~= X, y_pos(Obj):t ~= Y, NbX is X - 1, NbY is Y - 1, map(NbX, NbY, Nb):t.
nb8(Obj,Nb):t <- x_pos(Obj):t ~= X, y_pos(Obj):t ~= Y, NbX is X - 1, NbY is Y    , map(NbX, NbY, Nb):t.

% Map
map(X, Y, Obj):t <- x_pos(Obj):t ~= X, y_pos(Obj):t ~= Y.
map(X, Y, no_object):t <- \+((map(X, Y, obj0):t)), \+((map(X, Y, obj1):t)), \+((map(X, Y, obj2):t)), \+((map(X, Y, obj3):t)), \+((map(X, Y, obj4):t)), \+((map(X, Y, obj5):t)), \+((map(X, Y, obj6):t)), \+((map(X, Y, obj7):t)), \+((map(X, Y, obj8):t)), \+((map(X, Y, obj9):t)), \+((map(X, Y, obj10):t)), \+((map(X, Y, obj11):t)), \+((map(X, Y, obj12):t)), \+((map(X, Y, obj13):t)), \+((map(X, Y, obj14):t)), \+((map(X, Y, obj15):t)), \+((map(X, Y, obj16):t)), \+((map(X, Y, obj17):t)), \+((map(X, Y, obj18):t)), \+((map(X, Y, obj19):t)).

% Nothing
nothing(no_object):t+1 ~ val(Curr) <- nothing(no_object):t ~= Curr.

% Objects
is_object(Obj) <- member(Obj, [obj0,obj1,obj2,obj3,obj4,obj5,obj6,obj7,obj8,obj9,obj10,obj11,obj12,obj13,obj14,obj15,obj16,obj17,obj18,obj19]).

% Constraints
constraints:t <- true.

% Attribute Schemas
schema_x_pos(Obj, New):t <- nb5(Obj,Nb5):t, nothing(Nb5):t ~= yes, nb7(Obj,Nb7):t, colour(Nb7):t ~= wall, nb8(Obj,Nb8):t, colour(Nb8):t ~= wall, nb4(Obj,Nb4):t, nothing(Nb4):t ~= yes, colour(Obj):t ~= agent, action(r), x_pos(Obj):t ~= Curr, New is Curr + 1.
schema_x_pos(Obj, New):t <- nb5(Obj,Nb5):t, colour(Nb5):t ~= wall, nb4(Obj,Nb4):t, nothing(Nb4):t ~= yes, nb6(Obj,Nb6):t, nothing(Nb6):t ~= yes, nb1(Obj,Nb1):t, colour(Nb1):t ~= wall, nb8(Obj,Nb8):t, nothing(Nb8):t ~= yes, nb3(Obj,Nb3):t, colour(Nb3):t ~= wall, action(r), x_pos(Obj):t ~= Curr, New is Curr + 1.
schema_x_pos(Obj, New):t <- nb8(Obj,Nb8):t, nothing(Nb8):t ~= yes, colour(Obj):t ~= agent, action(l), x_pos(Obj):t ~= Curr, New is Curr - 1.
schema_x_pos(Obj, New):t <- nb8(Obj,Nb8):t, nothing(Nb8):t ~= yes, nb5(Obj,Nb5):t, colour(Nb5):t ~= wall, nb7(Obj,Nb7):t, nothing(Nb7):t ~= yes, nb1(Obj,Nb1):t, colour(Nb1):t ~= wall, action(l), x_pos(Obj):t ~= Curr, New is Curr - 1.
x_pos(Obj):t+1 ~ val(New) <- schema_x_pos(Obj, New):t.
x_pos(Obj):t+1 ~ val(Curr) <- x_pos(Obj):t ~= Curr.
schema_y_pos(Obj, New):t <- nb8(Obj,Nb8):t, nothing(Nb8):t ~= yes, nb6(Obj,Nb6):t, nothing(Nb6):t ~= yes, action(d), y_pos(Obj):t ~= Curr, New is Curr - 1.
schema_y_pos(Obj, New):t <- nb5(Obj,Nb5):t, nothing(Nb5):t ~= yes, nb7(Obj,Nb7):t, nothing(Nb7):t ~= no, nb1(Obj,Nb1):t, colour(Nb1):t ~= wall, nb8(Obj,Nb8):t, colour(Nb8):t ~= wall, action(d), y_pos(Obj):t ~= Curr, New is Curr - 1.
schema_y_pos(Obj, New):t <- nb4(Obj,Nb4):t, colour(Nb4):t ~= goal, action(u), y_pos(Obj):t ~= Curr, New is Curr + 1.
schema_y_pos(Obj, New):t <- nb7(Obj,Nb7):t, colour(Nb7):t ~= hole, action(u), y_pos(Obj):t ~= Curr, New is Curr + 1.
schema_y_pos(Obj, New):t <- nb6(Obj,Nb6):t, colour(Nb6):t ~= hole, action(u), y_pos(Obj):t ~= Curr, New is Curr + 1.
y_pos(Obj):t+1 ~ val(New) <- schema_y_pos(Obj, New):t.
y_pos(Obj):t+1 ~ val(Curr) <- y_pos(Obj):t ~= Curr.
x_size(Obj):t+1 ~ val(Curr) <- x_size(Obj):t ~= Curr.
y_size(Obj):t+1 ~ val(Curr) <- y_size(Obj):t ~= Curr.
colour(Obj):t+1 ~ val(Curr) <- colour(Obj):t ~= Curr.
shape(Obj):t+1 ~ val(Curr) <- shape(Obj):t ~= Curr.
nothing(Obj):t+1 ~ val(Curr) <- nothing(Obj):t ~= Curr.

% Reward Schemas
reward:t ~ val(100) <- constraints:t, action(A), member(A, [l]), \+action_performed:t.
reward:t ~ val(10) <- constraints:t, is_object(Obj), nb4(Obj,Nb4):t, colour(Nb4):t ~= goal, action(r).
reward:t ~ val(-1) <- constraints:t, is_object(Obj), nb6(Obj,Nb6):t, nothing(Nb6):t ~= yes, colour(Obj):t ~= agent.
reward:t ~ val(-1) <- constraints:t, is_object(Obj), nb4(Obj,Nb4):t, colour(Nb4):t ~= wall, colour(Obj):t ~= agent.
reward:t ~ val(-1) <- constraints:t, is_object(Obj), nb1(Obj,Nb1):t, colour(Nb1):t ~= wall, colour(Obj):t ~= agent.
reward:t ~ val(-1) <- constraints:t, is_object(Obj), nb7(Obj,Nb7):t, colour(Nb7):t ~= wall, nb2(Obj,Nb2):t, nothing(Nb2):t ~= yes, nb3(Obj,Nb3):t, colour(Nb3):t ~= wall, action(u).
reward:t ~ val(-1) <- constraints:t, is_object(Obj), nb6(Obj,Nb6):t, colour(Nb6):t ~= wall, nb2(Obj,Nb2):t, nothing(Nb2):t ~= yes, nb3(Obj,Nb3):t, colour(Nb3):t ~= wall, action(d).

% Run command
run :- executedplan_start,executedplan_step(BA,true,[observation(x_pos(obj0)) ~= 0, observation(y_pos(obj0)) ~= 4, observation(x_size(obj0)) ~= 1, observation(y_size(obj0)) ~= 1, observation(colour(obj0)) ~= wall, observation(shape(obj0)) ~= square, observation(nothing(obj0)) ~= no,
observation(x_pos(obj1)) ~= 1, observation(y_pos(obj1)) ~= 4, observation(x_size(obj1)) ~= 1, observation(y_size(obj1)) ~= 1, observation(colour(obj1)) ~= wall, observation(shape(obj1)) ~= square, observation(nothing(obj1)) ~= no,
observation(x_pos(obj2)) ~= 2, observation(y_pos(obj2)) ~= 4, observation(x_size(obj2)) ~= 1, observation(y_size(obj2)) ~= 1, observation(colour(obj2)) ~= wall, observation(shape(obj2)) ~= square, observation(nothing(obj2)) ~= no,
observation(x_pos(obj3)) ~= 3, observation(y_pos(obj3)) ~= 4, observation(x_size(obj3)) ~= 1, observation(y_size(obj3)) ~= 1, observation(colour(obj3)) ~= wall, observation(shape(obj3)) ~= square, observation(nothing(obj3)) ~= no,
observation(x_pos(obj4)) ~= 4, observation(y_pos(obj4)) ~= 4, observation(x_size(obj4)) ~= 1, observation(y_size(obj4)) ~= 1, observation(colour(obj4)) ~= wall, observation(shape(obj4)) ~= square, observation(nothing(obj4)) ~= no,
observation(x_pos(obj5)) ~= 0, observation(y_pos(obj5)) ~= 3, observation(x_size(obj5)) ~= 1, observation(y_size(obj5)) ~= 1, observation(colour(obj5)) ~= wall, observation(shape(obj5)) ~= square, observation(nothing(obj5)) ~= no,
observation(x_pos(obj6)) ~= 4, observation(y_pos(obj6)) ~= 3, observation(x_size(obj6)) ~= 1, observation(y_size(obj6)) ~= 1, observation(colour(obj6)) ~= wall, observation(shape(obj6)) ~= square, observation(nothing(obj6)) ~= no,
observation(x_pos(obj7)) ~= 0, observation(y_pos(obj7)) ~= 2, observation(x_size(obj7)) ~= 1, observation(y_size(obj7)) ~= 1, observation(colour(obj7)) ~= wall, observation(shape(obj7)) ~= square, observation(nothing(obj7)) ~= no,
observation(x_pos(obj8)) ~= 3, observation(y_pos(obj8)) ~= 2, observation(x_size(obj8)) ~= 1, observation(y_size(obj8)) ~= 1, observation(colour(obj8)) ~= wall, observation(shape(obj8)) ~= square, observation(nothing(obj8)) ~= no,
observation(x_pos(obj9)) ~= 4, observation(y_pos(obj9)) ~= 2, observation(x_size(obj9)) ~= 1, observation(y_size(obj9)) ~= 1, observation(colour(obj9)) ~= wall, observation(shape(obj9)) ~= square, observation(nothing(obj9)) ~= no,
observation(x_pos(obj10)) ~= 0, observation(y_pos(obj10)) ~= 1, observation(x_size(obj10)) ~= 1, observation(y_size(obj10)) ~= 1, observation(colour(obj10)) ~= wall, observation(shape(obj10)) ~= square, observation(nothing(obj10)) ~= no,
observation(x_pos(obj11)) ~= 4, observation(y_pos(obj11)) ~= 1, observation(x_size(obj11)) ~= 1, observation(y_size(obj11)) ~= 1, observation(colour(obj11)) ~= wall, observation(shape(obj11)) ~= square, observation(nothing(obj11)) ~= no,
observation(x_pos(obj12)) ~= 0, observation(y_pos(obj12)) ~= 0, observation(x_size(obj12)) ~= 1, observation(y_size(obj12)) ~= 1, observation(colour(obj12)) ~= wall, observation(shape(obj12)) ~= square, observation(nothing(obj12)) ~= no,
observation(x_pos(obj13)) ~= 1, observation(y_pos(obj13)) ~= 0, observation(x_size(obj13)) ~= 1, observation(y_size(obj13)) ~= 1, observation(colour(obj13)) ~= wall, observation(shape(obj13)) ~= square, observation(nothing(obj13)) ~= no,
observation(x_pos(obj14)) ~= 2, observation(y_pos(obj14)) ~= 0, observation(x_size(obj14)) ~= 1, observation(y_size(obj14)) ~= 1, observation(colour(obj14)) ~= wall, observation(shape(obj14)) ~= square, observation(nothing(obj14)) ~= no,
observation(x_pos(obj15)) ~= 3, observation(y_pos(obj15)) ~= 0, observation(x_size(obj15)) ~= 1, observation(y_size(obj15)) ~= 1, observation(colour(obj15)) ~= wall, observation(shape(obj15)) ~= square, observation(nothing(obj15)) ~= no,
observation(x_pos(obj16)) ~= 4, observation(y_pos(obj16)) ~= 0, observation(x_size(obj16)) ~= 1, observation(y_size(obj16)) ~= 1, observation(colour(obj16)) ~= wall, observation(shape(obj16)) ~= square, observation(nothing(obj16)) ~= no,
observation(x_pos(obj17)) ~= 1, observation(y_pos(obj17)) ~= 1, observation(x_size(obj17)) ~= 1, observation(y_size(obj17)) ~= 1, observation(colour(obj17)) ~= hole, observation(shape(obj17)) ~= square, observation(nothing(obj17)) ~= no,
observation(x_pos(obj18)) ~= 3, observation(y_pos(obj18)) ~= 1, observation(x_size(obj18)) ~= 1, observation(y_size(obj18)) ~= 1, observation(colour(obj18)) ~= goal, observation(shape(obj18)) ~= square, observation(nothing(obj18)) ~= no,
observation(x_pos(obj19)) ~= 2, observation(y_pos(obj19)) ~= 1, observation(x_size(obj19)) ~= 1, observation(y_size(obj19)) ~= 1, observation(colour(obj19)) ~= agent, observation(shape(obj19)) ~= square, observation(nothing(obj19)) ~= no,
observation(nothing(no_object))~=yes],50,5,TotalR,T,5,STOP),print(BA).