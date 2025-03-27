options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

libname rs "\\cdc.gov\private\L606\vom8\Gebel Correction Project 2014-09\Data\SAS Data\From Randy 26sep2014\Final Data";

data d01;
	set rs.initial_datav3;
	g_prop = g_y / g_n;
	k_prop = k_y_neo / k_n;
run;

* plot gebel's lung burden vs. gebel's non-keratin tumor counts ;
proc sgplot data=d01;
	title "Gebel Lung Burden (mg/g) vs. Gebel Tumor Incidence (%)";
	scatter x=g_lbmgg y=g_prop / group=par_type;
run;

title;

* normalize gebel's lung burden ;
proc sql;
   select max(g_lbmgg)
	into :max_glbmgg_nano
	from d01
	where par_type="nano";

	select max(g_lbmgg)
	into :max_glbmgg_micro
	from d01
	where par_type="micro";
quit;

data d02;
	set d01;
	if par_type="nano" then norm_g_lbmgg = g_lbmgg/&max_glbmgg_nano;
	else if par_type="micro" then norm_g_lbmgg = g_lbmgg/&max_glbmgg_micro;
run;

proc sgplot data=d02;
	title "Gebel Lung Burden (mg/g) vs. Gebel Tumor Incidence (%)";
	scatter x=norm_g_lbmgg y=g_prop / group=par_type;
run;




* normalize eileen's lung burden ;
proc sql;
   select max(k_lbmgg)
	into :max_klbmgg_nano
	from d02
	where par_type="nano";

	select max(k_lbmgg)
	into :max_klbmgg_micro
	from d02
	where par_type="micro";

	select max(k_lbmgg)
	into :max_klbmgg
	from d02;
quit;

data d03;
	set d02;
	if par_type="nano" then norm_k_lbmgg = k_lbmgg/&max_klbmgg;
	else if par_type="micro" then norm_k_lbmgg = k_lbmgg/&max_klbmgg;
run;

proc sgplot data=d03;
	title "Eileen Lung Burden (mg/g) vs. Eileen Tumor Incidence (%)";
	scatter x=norm_k_lbmgg y=k_prop / group=par_type;
	where i_gebel=1;
run;

proc genmod data=d03;
	where i_gebel=1;
	class par_type sex;
	model k_y_neo/k_n = norm_k_lbmgg par_type / dist=bin link=logit lrci predicted;
run;









* transform and linear regress? ;
data d04;
	set d03;
	log_k_prop = log10(k_prop);
	ln_k_prop = log(k_prop);
run;

proc univariate data=d04 normal;
	class par_type;
	var log_k_prop;
run;
* micro not normal, nano is normal ;

proc univariate data=d04 normal;
	class par_type;
	var ln_k_prop;
run;

proc univariate data=d04 normal;
	class par_type;
	var k_prop;
run;

proc sgplot data=d04;
	title "Eileen Lung Burden (mg/g) vs. Transformed Eileen Tumor Incidence (%)";
	scatter x=norm_k_lbmgg y=log_k_prop / group=par_type;
	where i_gebel=1;
run;
