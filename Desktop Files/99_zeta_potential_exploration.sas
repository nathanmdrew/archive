data one;
	set storage.skeleton_pchem1_v2;
	label samppmnper="% PMN"
		  zeta_potential="Zeta Potential (mV)";
run;

proc sgplot data=one;
	title "Association of Zeta Potential vs. PMN%";
	title2 "n = 666 (of 1929 --> 65% missing)";
	scatter x=zeta_potential y=samppmnper / group=studyref markerattrs=(symbol=DiamondFilled);
	where zeta_potential ne .;
run;

proc sgplot data=one;
	title "Association of Zeta Potential vs. PMN%";
	title2 "n = 666 (of 1929 --> 65% missing)";
	scatter x=zeta_potential y=samppmnper / group=material markerattrs=(symbol=DiamondFilled);
	where zeta_potential ne .;
run;

title "";
title2 "";

data two;
	set one;
	if zeta_potential = . then zeta_potential=99;
run;
proc sql;
	create table zp as
	select distinct study_key
					,studyref
					,material
					,material_type
					,zeta_potential
	from one;
quit;
data zp;
	set zp;
	if zeta_potential ne .;
run;
