%%% @author Sebastian Horoszkiewicz, id: C00156243
%%% @copyright (C) 2015, Sebastian Horoszkiewicz
%%% @doc This module takes in string and performs the following operations on it: 
%%%			parses string into internal representation,
%%%			evaluates equation from tree,
%%%			compiles from tree into stack and
%%%			simulatesfrom stack to integer.			
%%% @date 25/02/2015			
%%% @end

-module(main).

-export([parser/1, eval/1, compiler/1, simulator/1,
		 tryAll/0, parser_test_/0, eval_test_/0, compiler_test_/0, simulator_test_/0]).

%% ====================================================================
%% Tests
%% ====================================================================

%% Test 1 - Run everything 

%% This test takes inputs from previous parts and outputs the final results from simulator
tryAll()->
	io:fwrite("1. ~p~n",[runEverything("(3+2)")]),
	io:fwrite("2. ~p~n",[runEverything("(9/3)")]),
	io:fwrite("3. ~p~n",[runEverything("(4*3)")]),
	io:fwrite("4. ~p~n",[runEverything("(4~3)")]),
    io:fwrite("5. ~p~n",[runEverything("((2+3)*4)")]),
    io:fwrite("6. ~p~n",[runEverything("(8~(4/2))")]),
    io:fwrite("7. ~p~n",[runEverything("(8/(2~(1+(9~(9*1)))))")]),
	io:fwrite("8. ~p~n",[runEverything("(4~8)")]).

%% This function runs each part of whole program 
runEverything(EquationStr) ->
	{Tree,[]}=parser(EquationStr),
	eval(Tree),
	StackIn=compiler(Tree),
	simulator(StackIn).

%% Test 2 - Testing Parser Only

parser_test_() ->
	[	
		parser("(1+2)") =:= {{add,{num,1},{num,2}},[]},
		parser("(9/3)") =:= {{divide,{num,9},{num,3}},[]},
		parser("(4*3)") =:= {{mul,{num,4},{num,3}},[]},
	 	parser("(4~8)") =:= {{sub,{num,4},{num,8}},[]},
		parser("(8~(4/2))") =:= {{sub,{num,8},{divide,{num,4},{num,2}}},[]},
		parser("(8/(2~(1+(9~(9*1)))))") =:= {{divide,{num,8},{sub,{num,2},{add,{num,1},{sub,{num,9},{mul,{num,9},{num,1}}}}}},[]}
	].

%% Test 3 - Testing Evaluator Only

eval_test_() ->
	[	
		eval({add,{num,1},{num,2}}) =:= 3,
		eval({divide,{num,9},{num,3}}) =:= 3.0,
		eval({mul,{num,4},{num,3}}) =:= 12,
		eval({sub,{num,4},{num,8}}) =:= -4,
		eval({sub,{num,8},{divide,{num,4},{num,2}}}) =:= 6.0,
		eval({divide,{num,8},{sub,{num,2},{add,{num,1},{sub,{num,9},{mul,{num,9},{num,1}}}}}}) =:= 8.0
	].

%% Test 4 - Testing Compiler Only

compiler_test_() ->
	[	
		compiler({add,{num,1},{num,2}}) =:= [{push,{num,1}},{push,{num,2}},{add},{pop},{ret}],
		compiler({divide,{num,9},{num,3}}) =:= [{push,{num,9}},{push,{num,3}},{divide},{pop},{ret}],
		compiler({mul,{num,4},{num,3}}) =:= [{push,{num,4}},{push,{num,3}},{mul},{pop},{ret}],
		compiler({sub,{num,4},{num,8}}) =:= [{push,{num,4}},{push,{num,8}},{sub},{pop},{ret}],
		compiler({sub,{num,8},{divide,{num,4},{num,2}}}) =:= [{push,{num,8}},{push,{num,4}},{push,{num,2}},{divide},{sub},{pop},{ret}],
		compiler({divide,{num,8},{sub,{num,2},{add,{num,1},{sub,{num,9},{mul,{num,9},{num,1}}}}}}) =:= 
			[{push,{num,8}},{push,{num,2}},{push,{num,1}},{push,{num,9}},{push,{num,9}},{push,{num,1}},{mul},{sub},{add},{sub},{divide},{pop},{ret}]
	].

%% Test 5 - Testing Simulator Only

simulator_test_() ->
	[	
		simulator([{push,{num,1}},{push,{num,2}},{add},{pop},{ret}]) =:= 3,
		simulator([{push,{num,9}},{push,{num,3}},{divide},{pop},{ret}]) =:= 3.0,
		simulator([{push,{num,4}},{push,{num,3}},{mul},{pop},{ret}]) =:= 12,
		simulator([{push,{num,4}},{push,{num,8}},{sub},{pop},{ret}]) =:= -4,
		simulator([{push,{num,8}},{push,{num,4}},{push,{num,2}},{divide},{sub},{pop},{ret}]) =:= 6.0,
		simulator([{push,{num,8}},{push,{num,2}},{push,{num,1}},{push,{num,9}},{push,{num,9}},{push,{num,1}},{mul},{sub},{add},{sub},{divide},{pop},{ret}]) =:= 
			8.0
	].

%% ====================================================================
%% The Parser
%% ====================================================================

%% It's divided int two parts 1. tokenising 2. Converting tokens into Internal Representation
parser(EquationStr)->
    TokenList=tokenise(EquationStr),
    toInterRep(TokenList).

%% Converts string into tokens
tokenise([]) -> [];
tokenise([$(|Tail]) -> 
	[{bracket,left}|tokenise(Tail)];
tokenise([$)|Tail]) -> 
	[{bracket,right}|tokenise(Tail)];
tokenise([$*|Tail]) -> 
	[{binOp,mul} |tokenise(Tail)];
tokenise([$/|Tail]) -> 
	[{binOp,divide} |tokenise(Tail)];
tokenise([$~|Tail]) -> 
	[{binOp,sub} |tokenise(Tail)];
tokenise([$+|Tail]) -> 
	[{binOp,add}|tokenise(Tail)];

%%converts only single ASCII value to integer
tokenise([Head|Tail]) when (Head > 47) and (Head < 58) -> 
	[{num, [Head-48]} |tokenise(Tail)].

%% converts to internal representation and stores in Tree
toInterRep([{bracket,left}|Tail]) -> 
	{LeftTree,[{binOp,Op}|Unused]}=toInterRep(Tail),
	{RightTree,[{bracket,right}|Remainder]}=toInterRep(Unused),
	{{Op,LeftTree,RightTree},Remainder};

toInterRep([{num,[X]}|Tail]) -> 
	{{num,X},Tail}.

%% ====================================================================
%% The Evaluator
%% ====================================================================

%% `eval` This takes in tree and performs equation
eval(Tree) ->
	case Tree of
		{num, Val} -> Val;
		{Op, L, R} ->
			performEquation(Op, eval(L),eval(R))
	end.

%% `performEquation` Takes operator, left and right value and performs equation on it
performEquation(Op,L,R) ->
	case Op of
		add -> L + R;
		sub -> L - R;
		mul -> L * R;
		divide -> L / R
	end.

%% ====================================================================
%% The Compiler
%% ====================================================================

%% `compiler` Takes in tree and returns list of instructions
compiler(Tree) ->
	lists:reverse([{ret} | [{pop} | compiler(Tree,[])]]).

%% `compiler` 
compiler(Tree, Instruction) -> 
	case Tree of
		{num, _} ->
			[{push, Tree}|Instruction];
		{Op, L, R} ->
			[{Op}|compiler(R, compiler(L,Instruction))]
	end.

%% ====================================================================
%% The Simulator
%% ====================================================================

%% `simulator` takes in stack list and performs equation
simulator(StackIn) -> 
	simulator(StackIn , []).
simulator([{ret}|[]], [Res| []]) ->	Res;
simulator([{pop}| Tail], Stack) ->
	simulator(Tail, Stack);
simulator([{push, {num, Val}} | Tail], Stack) ->
	simulator(Tail, [Val] ++ Stack);
simulator([{Op} | Tail], Stack) ->
	%% pop top val from the stack, store in R
	[R|StackTail] = Stack,
	simulator(Tail, StackTail, R, Op).
simulator(Tail, Stack, R, Op) ->
	%% pop top val from the stack, store in L 
	[L|StackTail] = Stack,
	%% depending on Operator perform action
	case Op of
		add -> simulator(Tail, [L + R] ++ StackTail);
		sub -> simulator(Tail, [L - R] ++ StackTail);
		mul -> simulator(Tail, [L * R] ++ StackTail);
		divide -> simulator(Tail, [L / R] ++ StackTail)
	end.

