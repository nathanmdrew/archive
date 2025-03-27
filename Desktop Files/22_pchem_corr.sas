options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";


proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\DB\physiochemical_database_01mar2016.csv" out=pchem1
			dbms=csv replace;
run;


data pchem2;
	set pchem1;

	if Diameter = . then diameter = -99;
	if Length = . then Length = -99;
	if Median_Aerodynamic_Diameter = . then Median_Aerodynamic_Diameter = -99;
	if Aerodynamic_Diameter_GSD = . then Aerodynamic_Diameter_GSD = -99;
	if Surface_Area = . then Surface_Area = -99;
	if Density = . then Density = -99;
	if Zeta_Potential = . then Zeta_Potential = -99;
	if Contaminant_Amount = . then Contaminant_Amount = -99;
     
run;

proc corr data=pchem1 out=corr1;
run;

proc corr data=pchem2 out=corr2;
run;

proc contents data=pchem2 out=cont1;
run;
data cont2 (keep=NAME);
	set cont1;
	if type=1 then delete;
run;
data cont3;
	set cont2;
	index = _N_;
run;

proc freq data=pchem2;
   *table material * material_category / chisq exact expected;   * cramer V = 1, perfect corr? ;
   table material * material_type / chisq exact expected;		 * cramer V = 1, perfect corr? ;
   ods output chisq=chi1;
run;

%macro cat_corr;

	%do ii=1 %to 31;

		%let sup = &ii+1;

		%do jj=&sup %to 32;

			data vars;
				set cont3;

				if index = &ii then call symput('var1', name);
				if index = &jj then call symput('var2', name);
			run;

			proc freq data=pchem2;
				table &var1 * &var2 / chisq exact expected;
				ods output chisq=chi1;
			run;

			data chi2 (keep=statistic value var1 var2);
				set chi1;

				if statistic ne "Cramer's V" then delete;

				var1 = "&var1";
				var2 = "&var2";
			run;

			%if &ii=1 and &jj=2 %then %do;
				data chi_all;
					set chi2;	
				run;
			%end;

			%else %do;
				data chi_all;
					set chi_all chi2;
				run;
			%end;

		%end;

	%end;

%mend;

%cat_corr;		

data chi_all2;
	set chi_all;

	if var1 in ("Aerodynamic_Diameter_Units", "Diameter_Units", "Length_Units", "Material_Lot_Number",
				"Material_Manufacturer", "Solubility_Method", "StudyRef", "Surface_Area_Method", "Surface_Area_Units",
				"Zeta_Potential_Units") then delete;

	if var2 in ("Aerodynamic_Diameter_Units", "Diameter_Units", "Length_Units", "Material_Lot_Number",
				"Material_Manufacturer", "Solubility_Method", "StudyRef", "Surface_Area_Method", "Surface_Area_Units",
				"Zeta_Potential_Units") then delete;
run;

proc freq data=pchem2;
	table agglomerated_ rigidity solubility surface_charge volume ground_type;
run;
/* all missing or 1 value --- also remove reported_length and reported_diameter, as the numeric versions length and diameter
   are included in the PROC CORR */

data chi_all3;
	set chi_all2;

	if var1 in ("Agglomerated_", "Rigidity", "Solubility", "Surface_Charge", "Volume", "reported_length", 
				"reported_diameter", "Ground_Type") then delete;
	if var2 in ("Agglomerated_", "Rigidity", "Solubility", "Surface_Charge", "Volume", "reported_length", 
				"reported_diameter", "Ground_Type") then delete;
run;

data qc;
	set chi_all3;
	if var2="material_type";
run;

data storage2.pchem_cat_corr;
	set chi_all3;
run;
