/* suppose we have a true d-r relationship of RESPONSE = 5 + 10*DOSE  */
/* if we apply a constant to dose, are the resulting BMD and BMDL also constant-adjustable */

data one (drop=ii jj);
	do ii=0 to 5;
		
		do jj=1 to 10;
			if ii>0 then dose = 60 / ii;
			else dose=0;
			response = 5 + 10*dose + (40*rand('uniform') - 20);
			if response<0 then response=0;
			output;
		end;

	end;
run;

proc sgplot data=one;
	scatter x=dose y=response;
run;

proc export data=one outfile="C:\Users\vom8\Desktop\bmdtest.csv" dbms=csv replace;
run;

/*//////////////////////////////////////////////////////////////////////////////////////////////////
///		BMDS Output
///
///                                 Parameter Estimates
///
///                                                         95.0% Wald Confidence Interval
///       Variable         Estimate        Std. Err.     Lower Conf. Limit   Upper Conf. Limit
///          alpha          102.407           18.697             65.7621             139.053
///         beta_0          3.06292          2.04957           -0.954161             7.08001
///         beta_1          10.0242        0.0691631             9.88863             10.1597
///
///             Benchmark Dose Computation
///
///		Specified effect =           100
///
///		Risk Type        =     Point deviation 
///
///		Confidence level =          0.95
///
///             BMD =        9.67032
///
///
///            BMDL =         9.4043
///
//////////////////////////////////////////////////////////////////////////////////////////////////*/

data two;
	set one;
	dose2 = dose*300;
run;
proc export data=two outfile="C:\Users\vom8\Desktop\bmdtest2.csv" dbms=csv replace;
run;


/*//////////////////////////////////////////////////////////////////////////////////////////////////

                                 Parameter Estimates

                                                         95.0% Wald Confidence Interval
       Variable         Estimate        Std. Err.     Lower Conf. Limit   Upper Conf. Limit
          alpha          102.407          18.6969             65.7621             139.053
         beta_0          3.06292          2.04957           -0.954161             7.08001
         beta_1        0.0334139      0.000230544           0.0329621           0.0338658


		              Benchmark Dose Computation

Specified effect =           100

Risk Type        =     Point deviation 

Confidence level =          0.95

             BMD =         2901.1		= 	9.67032 * 300


            BMDL =        2821.29		=   9.4043 * 300
//////////////////////////////////////////////////////////////////////////////////////////////////*/



**	
	so for a simple linear model, BMDS does a good job of estimating the parameters (unsurprising)
	multiplying dose by a constant also shifts parameters multiplying dose by that same constant
		true slope = 10
		true slope when multiplying dose by 300 = 10/300 = 0.03333333

	you can also adjust the BMD and BMDL by that same constant

** ;



/* test for an exponential model

	100010_28_Short
		Mouse
		*dose by 100

	Original Deposited Dose: Exponential4 chosen
		BMD = 0.52237	
		BMDL = 0.00242177

	If adjustable:
		BMD = 52.237
		BMDL = 0.242177

	Yep, matches BMDS output
*/
