/*///////////////////////////////////////////////////
///  analyze gebel's data
///  create various point estimates for each metric
///      mass, surface area, volume
///      cumulative external exposure, cumulative lung burden
///      no weight, sample size weight, inverse variance weight
/*/


%let dir = C:\Users\vom8\Documents\Gebel Correction Project 2014-09\Data\ ;
libname c "&dir.";
libname save "&dir.SAS Data";

/*proc import datafile="&dir.database.csv" dbms=csv out=gebel_data;*/
/*run;*/

data WORK.GEBEL_DATA    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile "&dir.database.csv" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
	informat Evaluation $38. ;
	informat Study $20. ;
	informat rat $8. ;
	informat par_type $5. ;
	informat conc best32. ;
	informat sex $3. ;
	informat hrs_per_week best32. ;
	informat months best32. ;
	informat ctrl_lung_weight best32. ;
	informat cum_conc best32. ;
	informat surface_area best32. ;
	informat Density best32. ;
	informat lung_burden best32. ;
	informat y best32. ;
	informat n best32. ;
	informat i_gebel best32. ;

	format Evaluation $38. ;
	format Study $20. ;
	format rat $8. ;
	format par_type $5. ;
	format conc best12. ;
	format sex $3. ;
	format hrs_per_week best12. ;
	format months best12. ;
	format ctrl_lung_weight best12. ;
	format cum_conc best12. ;
	format surface_area best12. ;
	format Density best12. ;
	format lung_burden best12. ;
	format y best12. ;
	format n best12. ;
	format i_gebel best12. ;

	input
		Evaluation $
		Study $
		rat $
		par_type $
		conc
		sex $
		hrs_per_week
		months
		ctrl_lung_weight
		cum_conc
		surface_area
		Density
		lung_burden
		y
		n
		i_gebel
		;
	if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

data gebel_data;
	set gebel_data;
	/*/////  create standardized cumulative concentration exposure variable ////////*/
	stdzd_cum_conc = cum_conc/ctrl_lung_weight;

	if i_gebel=. then i_gebel=0;
run;

/*///////////////////////////////////////////////////////////////////////////
///  get the maximum standardized cumulative concentration for normalization
/*/
proc summary data=work.gebel_data nway;
	var stdzd_cum_conc;
	output out=temp1 (drop=_type_ _freq_) max()=max_stdzd_cum_conc;
run;
data _null_;
	set temp1;
	call symput('max_stdzd_cum_conc', max_stdzd_cum_conc);
run;
ods output exclude;
proc datasets library=work;	delete temp1; quit;
ods output;
%Put Maximum Standardized Cumulative Concentration is equal to:   &max_stdzd_cum_conc ;

/*///////////////////////
/// get potency estimates
/*/
data gebel_data;
	set gebel_data;
	normdose = stdzd_cum_conc / &max_stdzd_cum_conc;

	pr_obs = y/n;
run;

data controls(rename=(Pr_obs=Pr_obs0 n=n_0)) exposed;
     set work.gebel_data (where=(par_type ne "dee"));
     if Conc=0 then output controls; 
	 else output exposed;
run;
data pot;
     set exposed END=EOF; by Study NOTSORTED Sex NOTSORTED ;
     if first.Study OR first.Sex then DO;
        set controls(keep=Pr_obs0 n_0);
     END;
     retain Pr_obs0;
     Pot=(Pr_obs-Pr_obs0)/NormDose;
     output;

	 label I_Gebel="I(used by Gebel [?])"
           Pot    ="Potency: (Pd-P0)/d  ";

     if EOF then STOP;
run;

proc summary mean data=pot ;
     class I_Gebel Par_type;
     var Pot;
     output out=Gebel_Ests(label="Gebel's estimates if I_Gebel matches Gebel 2012"
                            drop=_TYPE_)
            mean=AvgPot;
run;

proc sort data=Gebel_Ests
          out=Gebel_Ests_nd(label="Gebel's estimates if I_Gebel matches Gebel 2012");
      by DESCENDING I_Gebel DESCENDING Par_type; 
run;

proc print data=Gebel_Ests_nd label;
     id I_Gebel Par_type;
     var AvgPot _FREQ_;
     label _FREQ_="Sample size";
     format AvgPot 6.3;
run;
/*
	i_gebel=1
		nano	1.906	n=7
		micro	0.662	n=7
		ratio	2.879154

	i_gebel - all
		nano	1.669	n=8
		micro	0.417	n=12
		ratio	4.002398
*/



/*///////////////////////////////////////////
/// add the inverse weights
/// assuming binomial variance
///
/// add gebel's weights based on sample size
/*/

data save.pot;
	set pot;
run;

data pot2;
	set pot;

	var_est_test = ( pr_obs  * (1-pr_obs)  )  / (normdose**2 * n  );
	var_est_ctrl = ( pr_obs0 * (1-pr_obs0) )  / (normdose**2 * n_0);
	var_est      = var_est_test + var_est_ctrl;
	inv_var_est = 1 / var_est;
run;


proc sql noprint;
	select sum(inv_var_est) 
    into :micro_inv_var_sum_all
	from work.pot2
	where par_type="micro";

	select sum(inv_var_est) 
    into :micro_inv_var_sum_geb
	from work.pot2
	where par_type="micro"
      and i_gebel=1;

	select sum(inv_var_est)
	into :nano_inv_var_sum_all
	from work.pot2
	where par_type="nano";

	select sum(inv_var_est)
	into :nano_inv_var_sum_geb
	from work.pot2
	where par_type="nano"
      and i_gebel=1;
quit;

%Put Total Micro Inverse Variance (ALL) = &micro_inv_var_sum_all. ;
%Put Total Nano  Inverse Variance (ALL) = &nano_inv_var_sum_all.  ;

%Put Total Micro Inverse Variance (Geb) = &micro_inv_var_sum_geb. ;
%Put Total Nano  Inverse Variance (Geb) = &nano_inv_var_sum_geb.  ;

data pot3;
	set pot2;
	if par_type="micro" then do;
		weight_all = inv_var_est / &micro_inv_var_sum_all.;
		w_pot_all = pot*weight_all;
		if i_gebel=1 then do;
			weight_geb = inv_var_est / &micro_inv_var_sum_geb.;
			w_pot_geb = pot*weight_geb;
		end;
	end;
	else if par_type="nano" then do;
		weight_all = inv_var_est / &nano_inv_var_sum_all.;
		w_pot_all = pot*weight_all;
		if i_gebel=1 then do;
			weight_geb = inv_var_est / &nano_inv_var_sum_geb.;
			w_pot_geb = pot*weight_geb;
		end;
	end;
run;

/*///////////////////////
/// check weight sum is 1
/*/
/*proc means data=pot3 sum;*/
/*	class par_type;*/
/*	var weight;*/
/*run;*/
/*
  Analysis Variable : weight

              N
par_type    Obs             Sum
ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
micro        12       0.9999999   ---- good

nano          8       1.0000000   ---- good	
ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ

*/

/*////////////////////////////////////////////////////////////
/// add weights by sample size - gebel's attempt at correction
/*/
proc sql noprint;
	select sum(n) 
    into :micro_total_n_all
	from work.pot3
	where par_type="micro";

	select sum(n) 
    into :micro_total_n_geb
	from work.pot3
	where par_type="micro"
      and i_gebel=1;

	select sum(n)
	into :nano_total_n_all
	from work.pot3
	where par_type="nano";

	select sum(n)
	into :nano_total_n_geb
	from work.pot3
	where par_type="nano"
      and i_gebel=1;
quit;

%Put Total Micro Sample Size (ALL) = &micro_total_n_all. ;
%Put Total Nano  Sample Size (ALL) = &nano_total_n_all. ;

%Put Total Micro Sample Size (Geb) = &micro_total_n_geb. ;
%Put Total Nano  Sample Size (Geb) = &nano_total_n_geb. ;

data pot4;
	set pot3;
	if par_type="micro" then do;
		n_weight_all = n / &micro_total_n_all.;
		n_w_pot_all = pot*n_weight_all;
		if i_gebel=1 then do;
			n_weight_geb = n / &micro_total_n_geb.;
			n_w_pot_geb = pot*n_weight_geb;
		end;
	end;
	else if par_type="nano" then do;
		n_weight_all = n / &nano_total_n_all.;
		n_w_pot_all = pot*n_weight_all;
		if i_gebel=1 then do;
			n_weight_geb = n / &nano_total_n_geb.;
			n_w_pot_geb = pot*n_weight_geb;
		end;
	end;
run;


/*/////////////////////////////////////////////////////////////   
/// get a variance-weighted relative potency for gebel's values
/*/
proc summary data=pot4 nway missing;
	class par_type;
	var w_pot_geb;
	where i_gebel=1;
	output out=gebel_ests_w1 (drop=_type_) sum()=avg_w_pot_geb;
run;
*
	nano			0.1967440276	n=7
	micro			0.0412240532	n=7
	ratio			4.772554
;



/*////////////////////////////////////////////////////////   
/// get a variance weighted relative potency for all data      
/*/
proc summary data=pot4 nway missing;
	class par_type;
	var w_pot_all;
	output out=gebel_ests_w2 (drop=_type_) sum()=avg_w_pot_all;
run;
*
	nano			0.1630003416	n=8
	micro			0.0243071465	n=12
	ratio			6.705861
;




/*///////////////////////////////////////////////////////   
/// get an n-weighted relative potency for gebel's values
/*/
proc summary data=pot4 nway missing;
	class par_type;
	var n_w_pot_geb;
	where i_gebel=1;
	output out=gebel_ests_n_w1 (drop=_type_) sum()=avg_n_w_pot_geb;
run;
*
	nano			0.2715783552	n=7
	micro			0.0853842714	n=7
	ratio			3.18066
;



/*////////////////////////////////////////////////// 
/// get an n-weighted relative potency for all data      
/*/
proc summary data=pot4 nway missing;
	class par_type;
	var n_w_pot_all;
	output out=gebel_ests_n_w2 (drop=_type_) sum()=avg_n_w_pot_all;
run;
*
	nano			0.2051010876	n=8
	micro			0.0310774345	n=12
	ratio			6.599679
;


/*////////////////////////////////////////////////////////
/// combine all of the cumulative exposure - mass metrics
/*/
data gebel_me_all;
	set gebel_ests_nd   (in=aa)
		gebel_ests_n_w2 (in=bb)
		gebel_ests_n_w1 (in=cc)
		gebel_ests_w2   (in=dd)
		gebel_ests_w1   (in=ee);

	format type $50.;
	if aa then type="Positive Rates - Gebel  &  All Data - Gebel";
	else if bb then type="All Data - Sample Size Weight";
	else if cc then type="Positive Rates - Sample Size Weight";
	else if dd then type="All Data - Inverse Variance Weight";
	else if ee then type="Positive Rates - Inverse Variance Weight";

run;
 





/*////////////////////////////////////////////////////////////
///  repeat the above processes for the remaining metrics
///		surface area exposure		volume exposure
///		mass burden		surface area burden		volume burden
/*/

data pot5;
	set pot4;

	/* create all the metrics */
	sa_exposure = cum_conc * surface_area / 1000;
	stdzd_sa_exposure = sa_exposure / ctrl_lung_weight;

	vol_exposure = cum_conc / density;
	stdzd_vol_exposure = vol_exposure / ctrl_lung_weight;

	/* mass_burden = lung_burden */     /* no formula, just values */
	stdzd_mass_burden = lung_burden / ctrl_lung_weight;

	sa_burden = lung_burden * surface_area * 10;
	stdzd_sa_burden = sa_burden / ctrl_lung_weight;

	vol_burden = lung_burden / density;
	stdzd_vol_burden = vol_burden / ctrl_lung_weight;
run;

proc summary data=pot5 nway missing;
	var stdzd_sa_exposure stdzd_vol_exposure stdzd_mass_burden stdzd_sa_burden stdzd_vol_burden;
	output out=temp1 (drop=_type_ _freq_) max()=max_sa_exposure max_vol_exposure max_mass_burden max_sa_burden max_vol_burden;
run;

data _null_;
	set temp1;
	call symput ('max_sa_exposure', max_sa_exposure);
	call symput ('max_vol_exposure', max_vol_exposure);
	call symput ('max_mass_burden', max_mass_burden);
	call symput ('max_sa_burden', max_sa_burden);
	call symput ('max_vol_burden', max_vol_burden);
run;
%put Max SA Exposure = &max_sa_exposure. ;
%put Max Vol Exposure = &max_vol_exposure. ;
%put Max Mass Burden = &max_mass_burden. ;
%put Max SA Burden = &max_sa_burden. ;
%put Max Vol Burden = &max_vol_burden. ;

proc datasets library=work;	delete temp1; quit;


/*///////////////////////////////////////////////////////
///  normalize each dose type
///  create inverse variance estimates for each dose type
/*/
data pot6;
	set pot5;

	norm_sa_exposure = stdzd_sa_exposure / &max_sa_exposure.;
	norm_vol_exposure = stdzd_vol_exposure / &max_vol_exposure.;
	norm_mass_burden = stdzd_mass_burden / &max_mass_burden.;
	norm_sa_burden = stdzd_sa_burden / &max_sa_burden.;
	norm_vol_burden = stdzd_vol_burden / &max_vol_burden.;

	* surface area - cumulative external exposure ;
	v_sae_1 = ( pr_obs  * (1-pr_obs)  )  / (norm_sa_exposure**2 * n  );
	v_sae_2 = ( pr_obs0 * (1-pr_obs0) )  / (norm_sa_exposure**2 * n_0);
	v_sae   = v_sae_1 + v_sae_2;
	inv_v_sae = 1 / v_sae;

	* volume - cumulative external exposure ;
	v_ve_1 = ( pr_obs  * (1-pr_obs)  )  / (norm_vol_exposure**2 * n  );
	v_ve_2 = ( pr_obs0 * (1-pr_obs0) )  / (norm_vol_exposure**2 * n_0);
	v_ve   = v_ve_1 + v_ve_2;
	inv_v_ve = 1 / v_ve;

	* mass - cumulative lung burden ;
	v_mb_1 = ( pr_obs  * (1-pr_obs)  )  / (norm_mass_burden**2 * n  );
	v_mb_2 = ( pr_obs0 * (1-pr_obs0) )  / (norm_mass_burden**2 * n_0);
	v_mb   = v_mb_1 + v_mb_2;
	inv_v_mb = 1 / v_mb;

	* surface area - cumulative lung burden ;
	v_sab_1 = ( pr_obs  * (1-pr_obs)  )  / (norm_sa_burden**2 * n  );
	v_sab_2 = ( pr_obs0 * (1-pr_obs0) )  / (norm_sa_burden**2 * n_0);
	v_sab   = v_sab_1 + v_sab_2;
	inv_v_sab = 1 / v_sab;

	* volume - cumulative lung burden ;
	v_vb_1 = ( pr_obs  * (1-pr_obs)  )  / (norm_vol_burden**2 * n  );
	v_vb_2 = ( pr_obs0 * (1-pr_obs0) )  / (norm_vol_burden**2 * n_0);
	v_vb   = v_vb_1 + v_vb_2;
	inv_v_vb = 1 / v_vb;

run;

/*//////////////////////////////////////////////////
///  create the inverse variance sums for weighting
/*/
proc sql noprint;

	* surface area - cumulative external exposure ;
	select sum(inv_v_sae) 
    into :micro_inv_var_sae_all
	from work.pot6
	where par_type="micro";

	select sum(inv_v_sae) 
    into :micro_inv_var_sae_geb
	from work.pot6
	where par_type="micro"
      and i_gebel=1;

	select sum(inv_v_sae)
	into :nano_inv_var_sae_all
	from work.pot6
	where par_type="nano";

	select sum(inv_v_sae)
	into :nano_inv_var_sae_geb
	from work.pot6
	where par_type="nano"
      and i_gebel=1;

	* volume - cumulative external exposure ;
	select sum(inv_v_ve) 
    into :micro_inv_var_ve_all
	from work.pot6
	where par_type="micro";

	select sum(inv_v_ve) 
    into :micro_inv_var_ve_geb
	from work.pot6
	where par_type="micro"
      and i_gebel=1;

	select sum(inv_v_ve)
	into :nano_inv_var_ve_all
	from work.pot6
	where par_type="nano";

	select sum(inv_v_ve)
	into :nano_inv_var_ve_geb
	from work.pot6
	where par_type="nano"
      and i_gebel=1;

	* mass - cumulative lung burden ;
	select sum(inv_v_mb) 
    into :micro_inv_var_mb_all
	from work.pot6
	where par_type="micro";

	select sum(inv_v_mb) 
    into :micro_inv_var_mb_geb
	from work.pot6
	where par_type="micro"
      and i_gebel=1;

	select sum(inv_v_mb)
	into :nano_inv_var_mb_all
	from work.pot6
	where par_type="nano";

	select sum(inv_v_mb)
	into :nano_inv_var_mb_geb
	from work.pot6
	where par_type="nano"
      and i_gebel=1;

	* surface area - cumulative lung burden ;
	select sum(inv_v_sab) 
    into :micro_inv_var_sab_all
	from work.pot6
	where par_type="micro";

	select sum(inv_v_sab) 
    into :micro_inv_var_sab_geb
	from work.pot6
	where par_type="micro"
      and i_gebel=1;

	select sum(inv_v_sab)
	into :nano_inv_var_sab_all
	from work.pot6
	where par_type="nano";

	select sum(inv_v_sab)
	into :nano_inv_var_sab_geb
	from work.pot6
	where par_type="nano"
      and i_gebel=1;

	* volume - cumulative lung burden ;
	select sum(inv_v_vb) 
    into :micro_inv_var_vb_all
	from work.pot6
	where par_type="micro";

	select sum(inv_v_vb) 
    into :micro_inv_var_vb_geb
	from work.pot6
	where par_type="micro"
      and i_gebel=1;

	select sum(inv_v_vb)
	into :nano_inv_var_vb_all
	from work.pot6
	where par_type="nano";

	select sum(inv_v_vb)
	into :nano_inv_var_vb_geb
	from work.pot6
	where par_type="nano"
      and i_gebel=1;
quit;

%Put Sum of Micro Inverse Variance (Surface Area Exposure - All) = &micro_inv_var_sae_all. ;
%Put Sum of Micro Inverse Variance (Surface Area Exposure - Geb) = &micro_inv_var_sae_geb. ;
%Put Sum of Nano  Inverse Variance (Surface Area Exposure - All) = &nano_inv_var_sae_all.  ;
%Put Sum of Nano  Inverse Variance (Surface Area Exposure - Geb) = &nano_inv_var_sae_geb.  ;
%Put ;
%Put ;
%Put Sum of Micro Inverse Variance (Volume Exposure - All) = &micro_inv_var_ve_all. ;
%Put Sum of Micro Inverse Variance (Volume Exposure - Geb) = &micro_inv_var_ve_geb. ;
%Put Sum of Nano  Inverse Variance (Volume Exposure - All) = &nano_inv_var_ve_all.  ;
%Put Sum of Nano  Inverse Variance (Volume Exposure - Geb) = &nano_inv_var_ve_geb.  ;
%Put ;
%Put ;
%Put Sum of Micro Inverse Variance (Mass Burden - All) = &micro_inv_var_mb_all. ;
%Put Sum of Micro Inverse Variance (Mass Burden - Geb) = &micro_inv_var_mb_geb. ;
%Put Sum of Nano  Inverse Variance (Mass Burden - All) = &nano_inv_var_mb_all.  ;
%Put Sum of Nano  Inverse Variance (Mass Burden - Geb) = &nano_inv_var_mb_geb.  ;
%Put ;
%Put ;
%Put Sum of Micro Inverse Variance (Surface Area Burden - All) = &micro_inv_var_sab_all. ;
%Put Sum of Micro Inverse Variance (Surface Area Burden - Geb) = &micro_inv_var_sab_geb. ;
%Put Sum of Nano  Inverse Variance (Surface Area Burden - All) = &nano_inv_var_sab_all.  ;
%Put Sum of Nano  Inverse Variance (Surface Area Burden - Geb) = &nano_inv_var_sab_geb.  ;
%Put ;
%Put ;
%Put Sum of Micro Inverse Variance (Volume Burden - All) = &micro_inv_var_vb_all. ;
%Put Sum of Micro Inverse Variance (Volume Burden - Geb) = &micro_inv_var_vb_geb. ;
%Put Sum of Nano  Inverse Variance (Volume Burden - All) = &nano_inv_var_vb_all.  ;
%Put Sum of Nano  Inverse Variance (Volume Burden - Geb) = &nano_inv_var_vb_geb.  ;
%Put ;
%Put ;

/*/////////////////////////////////////////////////////////////
///  create potency estimates
///  create weights based on inverse variances and sample size
///			for all data (_all)
///			for values used by Gebel (_geb)
///  create weighted potencies
/*/
data pot7;
	set pot6;

	* surface area - cumulative external exposure ;
	if par_type="micro" then do;
		sae_Pot=(Pr_obs-Pr_obs0) / norm_sa_exposure;
		sae_weight_all = inv_v_sae / &micro_inv_var_sae_all.;
		sae_w_pot_all = sae_pot * sae_weight_all;
		sae_n_weight_all = n / &micro_total_n_all.;
		sae_n_w_pot_all = sae_pot * sae_n_weight_all;
		if i_gebel=1 then do;
			sae_weight_geb = inv_v_sae / &micro_inv_var_sae_geb.;
			sae_w_pot_geb = sae_pot * sae_weight_geb;
			sae_n_weight_geb = n / &micro_total_n_geb.;
			sae_n_w_pot_geb = sae_pot * sae_n_weight_geb;
		end;
	end;
	else if par_type="nano" then do;
		sae_Pot=(Pr_obs-Pr_obs0) / norm_sa_exposure;
		sae_weight_all = inv_v_sae / &nano_inv_var_sae_all.;
		sae_w_pot_all = sae_pot * sae_weight_all;
		sae_n_weight_all = n / &nano_total_n_all.;
		sae_n_w_pot_all = sae_pot * sae_n_weight_all;
		if i_gebel=1 then do;
			sae_weight_geb = inv_v_sae / &nano_inv_var_sae_geb.;
			sae_w_pot_geb = sae_pot * sae_weight_geb;
			sae_n_weight_geb = n / &nano_total_n_geb.;
			sae_n_w_pot_geb = sae_pot * sae_n_weight_geb;
		end;
	end;

	* volume - cumulative external exposure ;
	if par_type="micro" then do;
		ve_Pot=(Pr_obs-Pr_obs0) / norm_vol_exposure;
		ve_weight_all = inv_v_ve / &micro_inv_var_ve_all.;
		ve_w_pot_all = ve_pot * ve_weight_all;
		ve_n_weight_all = n / &micro_total_n_all.;
		ve_n_w_pot_all = ve_pot * ve_n_weight_all;
		if i_gebel=1 then do;
			ve_weight_geb = inv_v_ve / &micro_inv_var_ve_geb.;
			ve_w_pot_geb = ve_pot * ve_weight_geb;
			ve_n_weight_geb = n / &micro_total_n_geb.;
			ve_n_w_pot_geb = ve_pot * ve_n_weight_geb;
		end;
	end;
	else if par_type="nano" then do;
		ve_Pot=(Pr_obs-Pr_obs0) / norm_vol_exposure;
		ve_weight_all = inv_v_ve / &nano_inv_var_ve_all.;
		ve_w_pot_all = ve_pot * ve_weight_all;
		ve_n_weight_all = n / &nano_total_n_all.;
		ve_n_w_pot_all = ve_pot * ve_n_weight_all;
		if i_gebel=1 then do;
			ve_weight_geb = inv_v_ve / &nano_inv_var_ve_geb.;
			ve_w_pot_geb = ve_pot * ve_weight_geb;
			ve_n_weight_geb = n / &nano_total_n_geb.;
			ve_n_w_pot_geb = ve_pot * ve_n_weight_geb;
		end;
	end;

	* mass - cumulative lung burden ;
	if par_type="micro" then do;
		mb_Pot=(Pr_obs-Pr_obs0) / norm_mass_burden;
		mb_weight_all = inv_v_mb / &micro_inv_var_mb_all.;
		mb_w_pot_all = mb_pot * mb_weight_all;
		mb_n_weight_all = n / &micro_total_n_all.;
		mb_n_w_pot_all = mb_pot * mb_n_weight_all;
		if i_gebel=1 then do;
			mb_weight_geb = inv_v_mb / &micro_inv_var_mb_geb.;
			mb_w_pot_geb = mb_pot * mb_weight_geb;
			mb_n_weight_geb = n / &micro_total_n_geb.;
			mb_n_w_pot_geb = mb_pot * mb_n_weight_geb;
		end;
	end;
	else if par_type="nano" then do;
		mb_Pot=(Pr_obs-Pr_obs0) / norm_mass_burden;
		mb_weight_all = inv_v_mb / &nano_inv_var_mb_all.;
		mb_w_pot_all = mb_pot * mb_weight_all;
		mb_n_weight_all = n / &nano_total_n_all.;
		mb_n_w_pot_all = mb_pot * mb_n_weight_all;
		if i_gebel=1 then do;
			mb_weight_geb = inv_v_mb / &nano_inv_var_mb_geb.;
			mb_w_pot_geb = mb_pot * mb_weight_geb;
			mb_n_weight_geb = n / &nano_total_n_geb.;
			mb_n_w_pot_geb = mb_pot * mb_n_weight_geb;
		end;
	end;

	* surface area - cumulative lung burden ;
	if par_type="micro" then do;
		sab_Pot=(Pr_obs-Pr_obs0) / norm_sa_burden;
		sab_weight_all = inv_v_sab / &micro_inv_var_sab_all.;
		sab_w_pot_all = sab_pot * sab_weight_all;
		sab_n_weight_all = n / &micro_total_n_all.;
		sab_n_w_pot_all = sab_pot * sab_n_weight_all;
		if i_gebel=1 then do;
			sab_weight_geb = inv_v_sab / &micro_inv_var_sab_geb.;
			sab_w_pot_geb = sab_pot * sab_weight_geb;
			sab_n_weight_geb = n / &micro_total_n_geb.;
			sab_n_w_pot_geb = sab_pot * sab_n_weight_geb;
		end;
	end;
	else if par_type="nano" then do;
		sab_Pot=(Pr_obs-Pr_obs0) / norm_sa_burden;
		sab_weight_all = inv_v_sab / &nano_inv_var_sab_all.;
		sab_w_pot_all = sab_pot * sab_weight_all;
		sab_n_weight_all = n / &nano_total_n_all.;
		sab_n_w_pot_all = sab_pot * sab_n_weight_all;
		if i_gebel=1 then do;
			sab_weight_geb = inv_v_sab / &nano_inv_var_sab_geb.;
			sab_w_pot_geb = sab_pot * sab_weight_geb;
			sab_n_weight_geb = n / &nano_total_n_geb.;
			sab_n_w_pot_geb = sab_pot * sab_n_weight_geb;
		end;
	end;

	* volume - cumulative lung burden ;
	if par_type="micro" then do;
		vb_Pot=(Pr_obs-Pr_obs0) / norm_vol_burden;
		vb_weight_all = inv_v_vb / &micro_inv_var_vb_all.;
		vb_w_pot_all = vb_pot * vb_weight_all;
		vb_n_weight_all = n / &micro_total_n_all.;
		vb_n_w_pot_all = vb_pot * vb_n_weight_all;
		if i_gebel=1 then do;
			vb_weight_geb = inv_v_vb / &micro_inv_var_vb_geb.;
			vb_w_pot_geb = vb_pot * vb_weight_geb;
			vb_n_weight_geb = n / &micro_total_n_geb.;
			vb_n_w_pot_geb = vb_pot * vb_n_weight_geb;
		end;
	end;
	else if par_type="nano" then do;
		vb_Pot=(Pr_obs-Pr_obs0) / norm_vol_burden;
		vb_weight_all = inv_v_vb / &nano_inv_var_vb_all.;
		vb_w_pot_all = vb_pot * vb_weight_all;
		vb_n_weight_all = n / &nano_total_n_all.;
		vb_n_w_pot_all = vb_pot * vb_n_weight_all;
		if i_gebel=1 then do;
			vb_weight_geb = inv_v_vb / &nano_inv_var_vb_geb.;
			vb_w_pot_geb = vb_pot * vb_weight_geb;
			vb_n_weight_geb = n / &nano_total_n_geb.;
			vb_n_w_pot_geb = vb_pot * vb_n_weight_geb;
		end;
	end;
run;



/*/////////////////////////////////////////////  
/// get a relative potency for gebel's values
/// Surface Area - Cumulative External Exposure
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var sae_pot;
	where i_gebel=1;
	output out=gebel_ests_w_sae0 (drop=_type_) mean()=avg_sae_pot_geb;
run;
*
	nano			1.6857399262	n=7
	micro			4.3828677207	n=7
	ratio			0.3846203
;

/*///////////////////////////////////////////////////////////////// 
/// get a sample size weighted relative potency for gebel's values
/// Surface Area - Cumulative External Exposure
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var sae_n_w_pot_geb;
	where i_gebel=1;
	output out=gebel_ests_w_sae1 (drop=_type_) sum()=avg_sae_n_w_pot_geb;
run;
*
	nano			0.2594390696	n=7
	micro			0.6476937067	n=7
	ratio			0.4005583
;


/*/////////////////////////////////////////////////////////////   
/// get a variance-weighted relative potency for gebel's values
/// Surface Area - Cumulative External Exposure
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var sae_w_pot_geb;
	where i_gebel=1;
	output out=gebel_ests_w_sae2 (drop=_type_) sum()=avg_sae_w_pot_geb;
run;
*
	nano			0.0616606417	n=7
	micro			0.3079190072	n=7
	ratio			0.2002495
;



/*/////////////////////////////////////////////  
/// get a relative potency for all values
/// Surface Area - Cumulative External Exposure
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var sae_pot;
	output out=gebel_ests_w_sae3 (drop=_type_) mean()=avg_sae_pot_all;
run;
*
	nano			1.4776593431	n=8
	micro			2.77597187		n=12
	ratio			0.5323034
;

/*///////////////////////////////////////////////////////////////// 
/// get a sample size weighted relative potency for all values
/// Surface Area - Cumulative External Exposure
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var sae_n_w_pot_all;
	output out=gebel_ests_w_sae4 (drop=_type_) sum()=avg_sae_n_w_pot_all;
run;
*
	nano			0.1960411371	n=8
	micro			0.2347807214	n=12
	ratio			0.8349967
;


/*/////////////////////////////////////////////////////////////   
/// get a variance-weighted relative potency for all values
/// Surface Area - Cumulative External Exposure
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var sae_w_pot_all;
	output out=gebel_ests_w_sae5 (drop=_type_) sum()=avg_sae_w_pot_all;
run;
*
	nano			0.0537265683	n=8
	micro			0.1809735757	n=7
	ratio			0.2968752
;

data gebel_sae_all;
	set gebel_ests_w_sae0 (in=aa)
		gebel_ests_w_sae1 (in=bb)
		gebel_ests_w_sae2 (in=cc)
		gebel_ests_w_sae3 (in=dd)
		gebel_ests_w_sae4 (in=ee)
		gebel_ests_w_sae5 (in=ff);

	format type $50.;
	if aa then type = "Positive Rates - Gebel";
	else if bb then type = "Positive Rates - Sample Size Weight";
	else if cc then type = "Positive Rates - Inverse Variance Weight";
	else if dd then type = "All Data - Gebel";
	else if ee then type = "All Data - Sample Size Weight";
	else if ff then type = "All Data - Inverse Variance Weight";
run;






/*/////////////////////////////////////////////  
/// get a relative potency for gebel's values
/// Volume - Cumulative External Exposure
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var ve_pot;
	where i_gebel=1;
	output out=gebel_ests_w_ve0 (drop=_type_) mean()=avg_ve_pot_geb;
run;
*
	nano			1.6857399262	n=7
	micro			4.3828677207	n=7
	ratio			0.3846203
;

/*///////////////////////////////////////////////////////////////// 
/// get a sample size weighted relative potency for gebel's values
/// Volume - Cumulative External Exposure
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var ve_n_w_pot_geb;
	where i_gebel=1;
	output out=gebel_ests_w_ve1 (drop=_type_) sum()=avg_ve_n_w_pot_geb;
run;
*
	nano			0.2272376475	n=7
	micro			0.0929897294	n=7
	ratio			2.443685
;


/*/////////////////////////////////////////////////////////////   
/// get a variance-weighted relative potency for gebel's values
/// Volume - Cumulative External Exposure
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var ve_w_pot_geb;
	where i_gebel=1;
	output out=gebel_ests_w_ve2 (drop=_type_) sum()=avg_ve_w_pot_geb;
run;
*
	nano			0.1544309081	n=7
	micro			0.0381742581	n=7
	ratio			4.04542
;



/*/////////////////////////////////////////////  
/// get a relative potency for all values
/// Volume - Cumulative External Exposure
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var ve_pot;
	output out=gebel_ests_w_ve3 (drop=_type_) mean()=avg_ve_pot_all;
run;
*
	nano			1.3877217261	n=8
	micro			0.4824923991		n=12
	ratio			2.876153
;

/*///////////////////////////////////////////////////////////////// 
/// get a sample size weighted relative potency for all values
/// Volume - Cumulative External Exposure
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var ve_n_w_pot_all;
	output out=gebel_ests_w_ve4 (drop=_type_) sum()=avg_ve_n_w_pot_all;
run;
*
	nano			0.1715890682	n=8
	micro			0.0355324758	n=12
	ratio			4.829077
;


/*/////////////////////////////////////////////////////////////   
/// get a variance-weighted relative potency for all values
/// Volume - Cumulative External Exposure
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var ve_w_pot_all;
	output out=gebel_ests_w_ve5 (drop=_type_) sum()=avg_ve_w_pot_all;
run;
*
	nano			0.1265185526	n=8
	micro			0.0234376935	n=7
	ratio			5.39808
;

data gebel_ve_all;
	set gebel_ests_w_ve0 (in=aa)
		gebel_ests_w_ve1 (in=bb)
		gebel_ests_w_ve2 (in=cc)
		gebel_ests_w_ve3 (in=dd)
		gebel_ests_w_ve4 (in=ee)
		gebel_ests_w_ve5 (in=ff);

	format type $50.;
	if aa then type = "Positive Rates - Gebel";
	else if bb then type = "Positive Rates - Sample Size Weight";
	else if cc then type = "Positive Rates - Inverse Variance Weight";
	else if dd then type = "All Data - Gebel";
	else if ee then type = "All Data - Sample Size Weight";
	else if ff then type = "All Data - Inverse Variance Weight";
run;







/*/////////////////////////////////////////////  
/// get a relative potency for gebel's values
/// Mass - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var mb_pot;
	where i_gebel=1;
	output out=gebel_ests_w_mb0 (drop=_type_) mean()=avg_mb_pot_geb;
run;
*
	nano			1.6857399262	n=7
	micro			4.3828677207	n=7
	ratio			0.3846203
;

/*///////////////////////////////////////////////////////////////// 
/// get a sample size weighted relative potency for gebel's values
/// Mass - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var mb_n_w_pot_geb;
	where i_gebel=1;
	output out=gebel_ests_w_mb1 (drop=_type_) sum()=avg_mb_n_w_pot_geb;
run;
*
	nano			0.2272376475	n=7
	micro			0.0929897294	n=7
	ratio			2.443685
;


/*/////////////////////////////////////////////////////////////   
/// get a variance-weighted relative potency for gebel's values
/// Mass - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var mb_w_pot_geb;
	where i_gebel=1;
	output out=gebel_ests_w_mb2 (drop=_type_) sum()=avg_mb_w_pot_geb;
run;
*
	nano			0.1544309081	n=7
	micro			0.0381742581	n=7
	ratio			4.04542
;



/*/////////////////////////////////////////////  
/// get a relative potency for all values
/// Mass - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var mb_pot;
	output out=gebel_ests_w_mb3 (drop=_type_) mean()=avg_mb_pot_all;
run;
*
	nano			1.3877217261	n=8
	micro			0.4824923991		n=12
	ratio			2.876153
;

/*///////////////////////////////////////////////////////////////// 
/// get a sample size weighted relative potency for all values
/// Mass - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var mb_n_w_pot_all;
	output out=gebel_ests_w_mb4 (drop=_type_) sum()=avg_mb_n_w_pot_all;
run;
*
	nano			0.1715890682	n=8
	micro			0.0355324758	n=12
	ratio			4.829077
;


/*/////////////////////////////////////////////////////////////   
/// get a variance-weighted relative potency for all values
/// Mass - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var mb_w_pot_all;
	output out=gebel_ests_w_mb5 (drop=_type_) sum()=avg_mb_w_pot_all;
run;
*
	nano			0.1265185526	n=8
	micro			0.0234376935	n=7
	ratio			5.39808
;

data gebel_mb_all;
	set gebel_ests_w_mb0 (in=aa)
		gebel_ests_w_mb1 (in=bb)
		gebel_ests_w_mb2 (in=cc)
		gebel_ests_w_mb3 (in=dd)
		gebel_ests_w_mb4 (in=ee)
		gebel_ests_w_mb5 (in=ff);

	format type $50.;
	if aa then type = "Positive Rates - Gebel";
	else if bb then type = "Positive Rates - Sample Size Weight";
	else if cc then type = "Positive Rates - Inverse Variance Weight";
	else if dd then type = "All Data - Gebel";
	else if ee then type = "All Data - Sample Size Weight";
	else if ff then type = "All Data - Inverse Variance Weight";
run;







/*/////////////////////////////////////////////  
/// get a relative potency for gebel's values
/// Surface Area - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var sab_pot;
	where i_gebel=1;
	output out=gebel_ests_w_sab0 (drop=_type_) mean()=avg_sab_pot_geb;
run;
*
	nano			1.6857399262	n=7
	micro			4.3828677207	n=7
	ratio			0.3846203
;

/*///////////////////////////////////////////////////////////////// 
/// get a sample size weighted relative potency for gebel's values
/// Surface Area - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var sab_n_w_pot_geb;
	where i_gebel=1;
	output out=gebel_ests_w_sab1 (drop=_type_) sum()=avg_sab_n_w_pot_geb;
run;
*
	nano			0.2272376475	n=7
	micro			0.0929897294	n=7
	ratio			2.443685
;


/*/////////////////////////////////////////////////////////////   
/// get a variance-weighted relative potency for gebel's values
/// Surface Area - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var sab_w_pot_geb;
	where i_gebel=1;
	output out=gebel_ests_w_sab2 (drop=_type_) sum()=avg_sab_w_pot_geb;
run;
*
	nano			0.1544309081	n=7
	micro			0.0381742581	n=7
	ratio			4.04542
;



/*/////////////////////////////////////////////  
/// get a relative potency for all values
/// Surface Area - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var sab_pot;
	output out=gebel_ests_w_sab3 (drop=_type_) mean()=avg_sab_pot_all;
run;
*
	nano			1.3877217261	n=8
	micro			0.4824923991		n=12
	ratio			2.876153
;

/*///////////////////////////////////////////////////////////////// 
/// get a sample size weighted relative potency for all values
/// Surface Area - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var sab_n_w_pot_all;
	output out=gebel_ests_w_sab4 (drop=_type_) sum()=avg_sab_n_w_pot_all;
run;
*
	nano			0.1715890682	n=8
	micro			0.0355324758	n=12
	ratio			4.829077
;


/*/////////////////////////////////////////////////////////////   
/// get a variance-weighted relative potency for all values
/// Surface Area - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var sab_w_pot_all;
	output out=gebel_ests_w_sab5 (drop=_type_) sum()=avg_sab_w_pot_all;
run;
*
	nano			0.1265185526	n=8
	micro			0.0234376935	n=7
	ratio			5.39808
;

data gebel_sab_all;
	set gebel_ests_w_sab0 (in=aa)
		gebel_ests_w_sab1 (in=bb)
		gebel_ests_w_sab2 (in=cc)
		gebel_ests_w_sab3 (in=dd)
		gebel_ests_w_sab4 (in=ee)
		gebel_ests_w_sab5 (in=ff);

	format type $50.;
	if aa then type = "Positive Rates - Gebel";
	else if bb then type = "Positive Rates - Sample Size Weight";
	else if cc then type = "Positive Rates - Inverse Variance Weight";
	else if dd then type = "All Data - Gebel";
	else if ee then type = "All Data - Sample Size Weight";
	else if ff then type = "All Data - Inverse Variance Weight";
run;







/*/////////////////////////////////////////////  
/// get a relative potency for gebel's values
/// Volume - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var vb_pot;
	where i_gebel=1;
	output out=gebel_ests_w_vb0 (drop=_type_) mean()=avg_vb_pot_geb;
run;


/*///////////////////////////////////////////////////////////////// 
/// get a sample size weighted relative potency for gebel's values
/// Volume - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var vb_n_w_pot_geb;
	where i_gebel=1;
	output out=gebel_ests_w_vb1 (drop=_type_) sum()=avg_vb_n_w_pot_geb;
run;



/*/////////////////////////////////////////////////////////////   
/// get a variance-weighted relative potency for gebel's values
/// Volume - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var vb_w_pot_geb;
	where i_gebel=1;
	output out=gebel_ests_w_vb2 (drop=_type_) sum()=avg_vb_w_pot_geb;
run;




/*/////////////////////////////////////////////  
/// get a relative potency for all values
/// Volume - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var vb_pot;
	output out=gebel_ests_w_vb3 (drop=_type_) mean()=avg_vb_pot_all;
run;


/*///////////////////////////////////////////////////////////////// 
/// get a sample size weighted relative potency for all values
/// Volume - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var vb_n_w_pot_all;
	output out=gebel_ests_w_vb4 (drop=_type_) sum()=avg_vb_n_w_pot_all;
run;



/*/////////////////////////////////////////////////////////////   
/// get a variance-weighted relative potency for all values
/// Volume - Cumulative Lung Burden
/*/
proc summary data=pot7 nway missing;
	class par_type;
	var vb_w_pot_all;
	output out=gebel_ests_w_vb5 (drop=_type_) sum()=avg_vb_w_pot_all;
run;


data gebel_vb_all;
	set gebel_ests_w_vb0 (in=aa)
		gebel_ests_w_vb1 (in=bb)
		gebel_ests_w_vb2 (in=cc)
		gebel_ests_w_vb3 (in=dd)
		gebel_ests_w_vb4 (in=ee)
		gebel_ests_w_vb5 (in=ff);

	format type $50.;
	if aa then type = "Positive Rates - Gebel";
	else if bb then type = "Positive Rates - Sample Size Weight";
	else if cc then type = "Positive Rates - Inverse Variance Weight";
	else if dd then type = "All Data - Gebel";
	else if ee then type = "All Data - Sample Size Weight";
	else if ff then type = "All Data - Inverse Variance Weight";
run;

