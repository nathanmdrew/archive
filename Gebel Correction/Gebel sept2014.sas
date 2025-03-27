options nocenter nonumber nodate ls=80 formdlim="*" symbolgen mprint mergenoby=error;

libname save "C:\Users\vom8\Documents\Gebel Correction Project 2014-09\Data\SAS Data";

/* ----------------- import the "Database" tab from the reformatted Gebel data workbook ----------------- */
/*PROC IMPORT OUT= WORK.D01 */
/*            DATAFILE= "C:\Users\vom8\Documents\Gebel Correction Project */
/*2014-09\Data\Data Reformatted.xlsx" */
/*            DBMS=EXCEL REPLACE;*/
/*     RANGE="Database$"; */
/*     GETNAMES=YES;*/
/*     MIXED=NO;*/
/*     SCANTEXT=YES;*/
/*     USEDATE=YES;*/
/*     SCANTIME=YES;*/
/*RUN;*/
/**/
/*data save.raw_gebel;*/
/*   set d01;*/
/*run;*/


data d01;
	set save.raw_gebel;
run;

data d02;
	set d01;
	
	proportion_tumors = number_of_tumors/animals_studied;

	cum_exp_lung = cumulative_exposure_in_mg_m_3___ / control_standardized_lung_weight;
run;

proc sql;
   select max(cum_exp_lung) into :max_exp
   from d02;
quit;

%put max exposure is = &max_exp;

data d03;
	set d02;

	norm_cum_exp_lung = cum_exp_lung / &max_exp;

	* retain Control metrics for computing variance ;
	if norm_cum_exp_lung=0 then do;
		ctrl_prop=proportion_tumors;
		ctrl_n=animals_studied;
	end;
	retain ctrl_prop ctrl_n;

	difference_versus_control = proportion_tumors - ctrl_prop;

	* Gebel rounds off the difference in proportions, and also represents them as percentages and does not normalize dose;
	pot_gebel = ( round((difference_versus_control*100), 0.1) / cum_exp_lung);
	v_gebel = (round(proportion_tumors*100, 0.1) * (100 - round(proportion_tumors*100, 0.1))) / (cum_exp_lung**2 * animals_studied)
	          + (round(ctrl_prop*100, 0.1) * (100 - round(ctrl_prop*100, 0.1))) / (cum_exp_lung**2 * ctrl_n);
	inv_v_gebel = 1/v_gebel;

	/*
	// compute potencies --- these use a normalized dose, which Gebel does not use
	*/

	* potency 1 represents the assumption that there is no control response, i.e. dose_ctrl=0 and prop_tumors_ctrl=0 ;
	pot1 = proportion_tumors/norm_cum_exp_lung;
	v_pot1 = (proportion_tumors*(1-proportion_tumors)) / (animals_studied * norm_cum_exp_lung**2);

	* some tumors are observed in control ;
	* potency 2 allows for control responses ;
	v_pot2 = v_pot1 + (ctrl_prop * (1-ctrl_prop)) / (ctrl_n * norm_cum_exp_lung**2);


	inv_v_pot1 = 1/v_pot1;
	inv_v_pot2 = 1/v_pot2;

run;



	* reproduce Gebel's Nano/Micro ratio for Mass (excluding DEE) ;
	proc sql;
   		select mean(pot_gebel) into :avg_pot_gebel_micro
   		from d03
   		where particle_type="micro"
     	  and used_by_gebel_as_being_sig__over=1;

		select mean(pot_gebel) into :avg_pot_gebel_nano
   		from d03
   		where particle_type="nano"
    	  and used_by_gebel_as_being_sig__over=1;
	quit;

	data _NULL_;
		ratio = &avg_pot_gebel_nano / &avg_pot_gebel_micro;
		put ratio;
		call symput('ratio_gebel_mass',ratio);
		*2.8796296296;
		* matches gebel in his response to morfield ;
	run;




/* Get total inverse variance for potencies of interest */
proc sql;
	select sum(inv_v_gebel) into :total_inv_var_gebel_nano
	from d03
	where particle_type in ("nano")
	  and used_by_gebel_as_being_sig__over=1;

	select sum(inv_v_gebel) into :total_inv_var_gebel_micro
	from d03
	where particle_type in ("micro")
	  and used_by_gebel_as_being_sig__over=1;
quit;

data d04;
	set d03;

	if particle_type="nano" then do;
		weight_gebel_nano = inv_v_gebel / &total_inv_var_gebel_nano;
		pot_gebel_weighted_nano = pot_gebel * weight_gebel_nano;
	end;

	if particle_type="micro" then do;
		weight_gebel_micro = inv_v_gebel / &total_inv_var_gebel_micro;
		pot_gebel_weighted_micro = pot_gebel * weight_gebel_micro;
	end;
run;


	/* Ratio for weighted potencies, using the same differences as Gebel */
	proc sql;
   		select mean(pot_gebel_weighted) into :avg_w_pot_gebel_micro
   		from d04
   		where particle_type="micro"
    	  and used_by_gebel_as_being_sig__over=1;

		select mean(pot_gebel_weighted) into :avg_w_pot_gebel_nano
   		from d04
   		where particle_type="nano"
      	  and used_by_gebel_as_being_sig__over=1;


		select mean(pot_gebel_weighted_micro) into :avg_wmicro_pot_gebel_micro
   		from d04
   		where particle_type="micro"
    	  and used_by_gebel_as_being_sig__over=1;

		select mean(pot_gebel_weighted_nano) into :avg_wnano_pot_gebel_nano
   		from d04
   		where particle_type="nano"
    	  and used_by_gebel_as_being_sig__over=1;
	quit;

	data _NULL_;
		ratio_w = &avg_wnano_pot_gebel_nano / &avg_wmicro_pot_gebel_micro;
		put ratio_w;
		* 4.9230769231 ;
	run;




/*////////////////////////////////////////////////////////////////////////////
  ///////    fit some models for the Nano data
  ///////
  /////*/

title "Nano Dose-Response - Normalized Dose";
title2 "Gebel's Postive Responses Only";
proc sgplot data=d04(where=(particle_type="nano" and used_by_gebel_as_being_sig__over=1));
	scatter x=norm_cum_exp_lung
			y=proportion_tumors;
run;
* not a good view ;

title "Nano Dose-Response - Dose";
title2 "Gebel's Postive Responses Only";
proc sgplot data=d04(where=(particle_type="nano" and used_by_gebel_as_being_sig__over=1));
	scatter x=exposure_mg_m_3
			y=proportion_tumors;
run;

title "Nano Dose-Response - Dose";
title2 "All Responses";
proc sgplot data=d04(where=(particle_type="nano"));
	scatter x=exposure_mg_m_3
			y=proportion_tumors;
run;

title "Nano Dose-Response - Normalized Dose";
title2 "All Responses";
proc sgplot data=d04(where=(particle_type="nano"));
	scatter x=norm_cum_exp_lung
			y=proportion_tumors;
run;



data model_nano;
	set d04(where=(particle_type="nano"));

	* two rat strains --- F344/N  and  Wistar ;
	dummy_strain=0;
	if rat_strain="Wistar" then dummy_strain=1;

	* 4 studies --- CB_Elft12_Nik95  CB_P90_Hein94  CB_P90_Hein95  TiO2_P25_Hein95 ;
	dummy_nik95=0;	dummy_hein94=0;	 dummy_hein95=0;
	if study="CB_Elft12_Nik95" then dummy_nik95=1;
	if study="CB_P90_Hein94" then dummy_hein94=1;
	if study="CB_P90_Hein95" then dummy_hein95=1;

	dummy_female=0;
	if gender="f" then dummy_female=1;
run;

title "Fit a linear model of Prop = Dose";
title2 "Dose = Dose";
proc reg data=model_nano;
 	model proportion_tumors = exposure_mg_m_3;
quit;

title "Fit a linear model of Prop = Dose + Strain";
title2 "Dose = Dose";
proc reg data=model_nano;
 	model proportion_tumors = exposure_mg_m_3 dummy_strain;
quit;
* ---- Strain not significant for nano results even using raw dose, not standardized to a control ---- ;

title "Fit a linear model of Prop = Dose + Study";
title2 "Dose = Dose";
proc reg data=model_nano;
 	model proportion_tumors = exposure_mg_m_3 dummy_nik95 dummy_hein94 dummy_hein95;
quit;
* ---- Studies not significant ----- ;

title "Fit a linear model of Prop = Dose + gender";
title2 "Dose = Dose";
proc reg data=model_nano;
 	model proportion_tumors = exposure_mg_m_3 dummy_female;
quit;
* ---- Gender not significant ----- ;



title "Fit a linear model of Prop = Dose";
title2 "Dose = Normalized Cumulative Dose";
proc reg data=model_nano;
 	model proportion_tumors = norm_cum_exp_lung;
quit;

title "Fit a linear model of Prop = Dose + Strain";
title2 "Dose = Normalized Cumulative Dose";
proc reg data=model_nano;
 	model proportion_tumors = norm_cum_exp_lung dummy_strain;
quit;
* ---- Strain not significant ---- ;

title "Fit a linear model of Prop = Dose + Study";
title2 "Dose = Normalized Cumulative Dose";
proc reg data=model_nano;
 	model proportion_tumors = norm_cum_exp_lung dummy_nik95 dummy_hein94 dummy_hein95;
quit;
* ---- Studies not significant ----- ;

title "Fit a linear model of Prop = Dose + gender";
title2 "Dose = Normalized Cumulative Dose";
proc reg data=model_nano;
 	model proportion_tumors = norm_cum_exp_lung dummy_female;
quit;
* ---- Gender not significant ----- ;






/*////////////////////////////////////////////////////////////////////////////
  ///////    fit some models for the Micro data
  ///////
  /////*/

title "Micro Dose-Response - Dose";
title2 "All Responses";
proc sgplot data=d04(where=(particle_type="micro"));
	scatter x=exposure_mg_m_3
			y=proportion_tumors;
run;

title "Micro Dose-Response - Normalized Dose";
title2 "All Responses";
proc sgplot data=d04(where=(particle_type="micro"));
	scatter x=norm_cum_exp_lung
			y=proportion_tumors;
run;

/*//
  // wow, influential point at Dose=~0.2
  //
*/



