%let proj=C:\Users\vom8\Documents\Gebel Correction Project 2014-09\Data\SAS Data\From Randy 26sep2014;
libname c "&Proj";

title "Normalized Dose versus Pearson Residual";
proc sgplot data=c.bin3strat11_pred_lnphat;
	scatter x=normdose y=r_p;
run;

title "Predicted Value versus Pearson Residual";
proc sgplot data=c.bin3strat11_pred_lnphat;
	scatter x=phat y=r_p;
run;
