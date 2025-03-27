/* Lottery Sim

		Is it better to randomly choose or stick with the same numbers?
        Long run time

        15DEC2015:
			Random: 994,088 wins (0.99%)
			Same  : 999,541 wins (1.00%)
*/

data one; /* 1.5 GB */

	do ii=1 to 100000000;
		winningNumber = round(100*rand('unif'));
		output;
	end;

run;


data two;
	
	do ii=1 to 100000000;
		pickRandom = round(100*rand('unif'));
		pickSame = 19;
		output;
	end;

run;

data three;
	merge one two;
	by ii;

	RandomWin=0;
	SameWin=0;

	if winningNumber=pickRandom then RandomWin=1;
	if winningNumber=pickSame then SameWin=1;
run;

proc freq data=three;
	*table RandomWin * SameWin / list nocum;
	table randomwin samewin;
run;
