/*//////////////////////////////////////////////////////////////////////
///		Create rodent in vivo PMN database									///
//////////////////////////////////////////////////////////////////////*/


options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*/  Set infile directory where datafiles (csv) are located /*/
%let in_dir = Y:\ENM Categories ;

* data template --- not all vars will be filled in ;
data WORK.DB01    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile "&in_dir\invivo_data_template.csv" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

	informat Chemical $20. StudyRef $20. study_type $20. Duration $20. Species $20. Strain $20. Gender $2. animal_id $20. experiment_id $20. Route $20.
				aerosol_gen_tech $20. BWstart best32. BWend best32. LWstart best32. LWend best32. avg_PPD_um best32. med_PPD_um best32. SDofPPD best32. 
				APD_um best32. SDofAPD best32. CMD_um best32. MMAD_um best32. GSD best32. SSA_gml best32. Solubility best32. pH best32. shape $20. 
				porosity best32. surface_charge best32. surface_chem best32. zeta_potential best32. generation_method $20. chemical_comp $20. Reactivity best32. 
				dose_amount best32. dose_unit $20. treatment $20. NOAEL best32. LOAEL best32. Hr_D best32. D_Wk best32. Expos_Wk best32. PE_d best32. N best32. 
				TotCell best32. PMNcount best32. PMNper best32. Fibrosis_dist_score best32. Fibrosis_severity_score best32. Fibrosis_composite_score best32. 
				collagen_amt best32. hydroxyproline_amt best32. alveolar_ct_thickness best32. LDH_uL best32. albumin_mg_mL best32. N_Tumor best32. 
				OtherResponse $20. OtherInformation $20. ;

	format 	Chemical $20. StudyRef $20. study_type $20. Duration $20. Species $20. Strain $20. Gender $2. animal_id $20. experiment_id $20. Route $20.
				aerosol_gen_tech $20. BWstart best32. BWend best32. LWstart best32. LWend best32. avg_PPD_um best32. med_PPD_um best32. SDofPPD best32. 
				APD_um best32. SDofAPD best32. CMD_um best32. MMAD_um best32. GSD best32. SSA_gml best32. Solubility best32. pH best32. shape $20. 
				porosity best32. surface_charge best32. surface_chem best32. zeta_potential best32. generation_method $20. chemical_comp $20. Reactivity best32. 
				dose_amount best32. dose_unit $20. treatment $20. NOAEL best32. LOAEL best32. Hr_D best32. D_Wk best32. Expos_Wk best32. PE_d best32. N best32. 
				TotCell best32. PMNcount best32. PMNper best32. Fibrosis_dist_score best32. Fibrosis_severity_score best32. Fibrosis_composite_score best32. 
				collagen_amt best32. hydroxyproline_amt best32. alveolar_ct_thickness best32. LDH_uL best32. albumin_mg_mL best32. N_Tumor best32. 
				OtherResponse $20. OtherInformation $20. ;

	input		Chemical $ StudyRef $ study_type $ Duration $ Species $ Strain $ Gender $ animal_id $ experiment_id $ Route $
				aerosol_gen_tech $ BWstart BWend LWstart LWend avg_PPD_um med_PPD_um SDofPPD 
				APD_um SDofAPD CMD_um MMAD_um GSD SSA_gml Solubility pH shape $ 
				porosity surface_charge surface_chem zeta_potential generation_method $ chemical_comp $ Reactivity 
				dose_amount dose_unit $ treatment $ NOAEL LOAEL Hr_D D_Wk Expos_Wk PE_d N 
				TotCell PMNcount PMNper Fibrosis_dist_score Fibrosis_severity_score Fibrosis_composite_score 
				collagen_amt hydroxyproline_amt alveolar_ct_thickness LDH_uL albumin_mg_mL N_Tumor 
				OtherResponse $ OtherInformation $;

	if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;



****** Porter et al. 2013 TiO2 BAL data *************;
data WORK.TIO2_BAL01;	
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile "&in_dir\Porter TiO2 bal data complete v2.csv" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

	informat VAR1 $4. mouse $20. days best32. ldh best32. cells_per_mouse best32. particle $20. dose best32. albumin best32. AM_count best32. 
				PMN_count best32. AM_pct best32. PMN_pct best32. PMN_per_mouse best32. exp $20. bw_g best32. ;	

	format VAR1 $4. mouse $20. days best32. ldh best32. cells_per_mouse best32. particle $20. dose best32. albumin best32. AM_count best32. 
			 PMN_count best32. AM_pct best32. PMN_pct best32. PMN_per_mouse best32. exp $20. bw_g best32. ;	

	input	VAR1 $ mouse $ days ldh cells_per_mouse particle $ dose	albumin AM_count 
			PMN_count AM_pct PMN_pct PMN_per_mouse exp $ bw_g;
	
	if _ERROR_ then call symputx('_EFIERR_',1);  
run;	

data tio2_bal02 (drop=mouse exp bw_g dose particle days cells_per_mouse pmn_per_mouse pmn_count pmn_pct am_count am_pct ldh albumin);
	set tio2_bal01 (drop=var1);

	Chemical = "TiO2";
	StudyRef = "Porter2013";
	study_type = "Sub-Chronic";
	Duration = "112 days";
	Species = "Mouse";
	Strain = "C57BL/6J";
	Gender = "M";
	animal_id = mouse;
	experiment_id = exp;
	Route = "PA";
	BWstart=bw_g;			/* !!!!!!!! NOT SURE IF BW_G IS START OR END BW  !!!!!!!!!!  */
	dose_amount = dose;
	dose_unit = "ug";
	treatment = particle;
	pe_d = days;

	TotCell = cells_per_mouse*1000;
	PMNcount = PMN_per_mouse*1000;
	PMNper = PMN_pct/100;
	AMcount = TotCell - PMNcount;
	AMper = AM_pct/100;

	SampCell = AM_count + pmn_count;
	SampPMNCount = pmn_count;
	SampPMNPer = pmn_count / (pmn_count + am_count);
	SampAMCount = AM_Count;
	SampAMPer = am_count / (pmn_count + am_count);

	LDH_uL = ldh;
	albumin_mg_mL = albumin;

	format notes $128.;
	notes="am and pmn counts only.  CHECK BODY WEIGHT - START OR END";
run;

data db02;
	set db01 tio2_bal02;
run;




data	WORK.TIO2_FIB01	;									
	%let	_EFIERR_	=	0;	/*	set	the	ERROR	detection	macro	variable	*/
	infile	'Y:\ENM Categories\Porter TiO2 fibrosis.csv'	delimiter=',' MISSOVER DSD	lrecl=32767	firstobs=2;
	
	informat	animal	$8.00 nanoparticle	$7.00 particle	$7.00 dose	best32. days	best32. fibrosis_distribution	best32. fibrosis_severity	best32. 
				fibrosis_composite	best32.	VAR9	$1.00 	;							
	
	format	animal	$8.00 nanoparticle	$7.00 particle	$7.00 dose	best12. days	best12. fibrosis_distribution	best12. fibrosis_severity	best12.
				fibrosis_composite	best12. VAR9	$1.00 	;		
	
	input		animal $	nanoparticle $	particle	$	dose	days	fibrosis_distribution fibrosis_severity fibrosis_composite VAR9 $;	
	
	if	_ERROR_	then	call	symputx('_EFIERR_',1);	/*	set	ERROR	detection macro	variable	*/									
run;	
	
data tio2_fib02 (drop=animal dose nanoparticle particle days fibrosis_distribution fibrosis_severity fibrosis_composite);
	set tio2_fib01 (drop=var9);

	Chemical = "TiO2";
	StudyRef = "Porter2013";
	study_type = "Sub-Chronic";
	Duration = "112 days";
	Species = "Mouse";
	Strain = "C57BL/6J";
	Gender = "M";
	animal_id = animal;
	Route = "PA";
	dose_amount = dose;
	dose_unit = "ug";
	treatment = particle;
	pe_d = days;
	Fibrosis_dist_score = fibrosis_distribution;
	Fibrosis_severity_score = fibrosis_severity;
	Fibrosis_composite_score = fibrosis_composite;

	format notes $128.;
	notes="animal nums seem to be different from BAL";
run;

data db03;
	set db02 tio2_fib02;
run;




data	WORK.ZNO_01	;									
	%let	_EFIERR_	=	0;	/*	set	the	ERROR	detection	macro	variable	*/
	infile	'Y:\ENM Categories\ZnO data.csv' delimiter=','	MISSOVER	DSD lrecl=32767 firstobs=2	;	
	
	informat	rat $10. particle	$10.00 dose	best32. days best32. total_phagocytes best32. AM_cells best32. AM_pct best32. PMN_cells best32. 
				PMN_pct best32. cells_counted	best32.	;
	
	format	rat $10. particle	$10.00 dose	best12. days best12. total_phagocytes best12. AM_cells best12. AM_pct best12. PMN_cells best12. 
				PMN_pct	best12.	cells_counted	best12.	;		
	
	input	rat $ particle $	dose days total_phagocytes AM_cells AM_pct PMN_cells PMN_pct cells_counted	;	
	
	if	_ERROR_ then call	symputx('_EFIERR_',1);	/*	set	ERROR	detection macro	variable	*/									
run;			

data zno_02 (drop=rat dose particle days am_cells pmn_cells am_pct pmn_pct cells_counted);
	set zno_01 (drop=total_phagocytes); /* comm. with Sager recommended using AM+PMN instead */

	if am_cells=26370 then am_cells=26.37;

	Chemical = "ZnO";
	StudyRef = "Xia2011";
	study_type = "Sub-acute";
	Duration = "30 days";
	Species = "Rat";
	Strain = "Sprague-Dawley";
	Gender = "M";
	animal_id = rat;
	Route = "IT";
	dose_amount = dose;
	dose_unit = "mg/rat";
	treatment = particle;
	pe_d = days;
	TotCell = (am_cells + pmn_cells)*1000000;
	PMNcount = pmn_cells*1000000;
	PMNper = pmncount/totcell;
	AMcount = am_cells*1000000;
	AMper = amcount/totcell;
	SampCell = cells_counted;
	SampPMNCount = pmnper*sampcell;
	SampPMNPer = .;
	SampAMCount = amper*sampcell;
	SampAMPer = .;

	format notes $128.;
	notes="dropped total_phag.  incomplete data n=4.  sampPMN estimated.  dupe rats per dose/days.";

	if animal_id=. and treatment="" then delete;
run;

data db04;
	set db03 zno_02;
run;




data	WORK.AG_01	;									
	%let	_EFIERR_	=	0;	/*	set	the	ERROR	detection	macro	variable	*/
	infile	'Y:\ENM Categories\Roberts	ag	spray	cellcount.csv'	delimiter=','	MISSOVER	DSD	lrecl=32767	firstobs=2	;	
	
	informat	EXPT	$10. rat	$10. treatment	$5.00 days	best32. Ams	best32. PMNs best32. Lymphs best32. Eosins	best32. 
			Total	best32.	Ams_pct	best32.	PMNs_pct	best32.	Lymphs_pct	best32. Eosins_pct	best32. Coulter_count	best32.	
			AM_tot	best32.	PMN_tot	best32.	Lymphs_tot	best32.	Eosins_tot	best32.	;
	
	format	EXPT	$10.	rat	$10.	treatment	$5.00 days	best12.	Ams	best12.	PMNs	best12.	Lymphs	best12.	Eosins	best12.	
				Total	best12.	Ams_pct	best12.	PMNs_pct	best12.	Lymphs_pct	best12.	Eosins_pct	best12.	Coulter_count	best12.	AM_tot	best12.	
				PMN_tot	best12. Lymphs_tot	best12.	Eosins_tot	best12.	;	
	
	input EXPT $ rat	$ treatment $	days Ams	PMNs Lymphs	Eosins 
			Total Ams_pct	PMNs_pct	Lymphs_pct Eosins_pct Coulter_count AM_tot 
			PMN_tot	Lymphs_tot Eosins_tot;		
	
	if	_ERROR_	then	call	symputx('_EFIERR_',1);	/*	set	ERROR	detection macro	variable	*/									
run;		

data ag_02 (drop=rat EXPT days coulter_count pmn_tot am_tot total pmns ams lymphs_tot eosins_tot lymphs eosins
						ams_pct pmns_pct lymphs_pct eosins_pct );
	set ag_01;

	Chemical = "Ag";
	StudyRef = "Roberts2013";
	study_type = "Sub-Acute";
	Duration = "7 days";
	Species = "Rat";
	Strain = "Sprague-Dawley";
	Gender = "M";
	animal_id = rat;
	experiment_id = EXPT;
	Route = "Inh";
	dose_amount = .;
	dose_unit = "";
	*treatment = treatment;
	pe_d = days;

	TotCell = coulter_count;
	PMNcount = pmn_tot;
	PMNper = pmn_tot/coulter_count;
	AMcount = am_tot;
	AMper = am_tot/coulter_count;
	Lymphcount = lymphs_tot;
	Eosincount = eosins_tot;

	SampCell = total;
	SampPMNCount = pmns;
	SampPMNPer = pmns/total;
	SampAMCount = ams;
	SampAMPer = ams/total;
	SampLymphCount = lymphs;
	SampEosinCount = eosins;	
run;


data WORK.AG_03    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile 'Y:\ENM Categories\Roberts ag spray LDH albumin.csv' delimiter= ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

	informat EXPT $10. rat__ $10. treatment $7. days best32. ldh best32. albumin best32. ;

	format EXPT $10. rat__ $10. treatment $7. days best12. ldh best12. albumin best12. ;

	input EXPT $ rat__ $ treatment $ days ldh albumin;

	if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

data ag_04 (drop=rat__ EXPT ldh albumin treatment days);
	set ag_03;

	StudyRef = "Roberts2013";
	animal_id = rat__;
	experiment_id = EXPT;
	LDH_uL = ldh;
	albumin_mg_mL = albumin;
	pe_d = days;
run;

proc sort data=ag_02; by experiment_id animal_id pe_d; run;
proc sort data=ag_04; by experiment_id animal_id pe_d; run;
data ag_05;
	merge ag_02 ag_04;
	by experiment_id animal_id pe_d;
run;

data db05;
	set db04 ag_05;
run;




data WORK.MWCNT_01    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile 'Y:\ENM Categories\Sager MWCNT lavage.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

	informat exp_no $10. particle $6. dose best32. mouse_no $10. post_exposure__days_ best32. LDH__U_L_ best32. albumin__mg_ml_ best32. 
				AM_per_mouse best32. AM_count best32. AM_pct best32. PMN_per_mouse best32. PMN_count best32. PMN_pct best32. ;

   format 	exp_no $10. particle $6. dose best12. mouse_no $10. post_exposure__days_ best12. LDH__U_L_ best12. albumin__mg_ml_ best12. 
				AM_per_mouse best12. AM_count best12. AM_pct best12. PMN_per_mouse best12. PMN_count best12. PMN_pct best12. ;

   input exp_no $ particle $ dose mouse_no $ post_exposure__days_ LDH__U_L_ albumin__mg_ml_ 
			AM_per_mouse AM_count AM_pct PMN_per_mouse PMN_count PMN_pct;

	if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;
data mwcnt_02 (drop=mouse_no exp_no dose particle post_exposure__days_ am_per_mouse pmn_per_mouse pmn_count am_count LDH__U_L_ albumin__mg_ml_ AM_pct PMN_pct);
	set mwcnt_01;

	Chemical = "MWCNT";
	StudyRef = "Sager2013";
	study_type = "Sub-Acute";
	Duration = "7 days";
	Species = "Mouse";
	Strain = "C57BL/6J";
	Gender = "M";
	animal_id = mouse_no;
	experiment_id = exp_no;
	Route = "PA";
	dose_amount = dose;
	dose_unit = "ug";
	treatment = particle;
	pe_d = post_exposure__days_;

	TotCell = (AM_per_mouse + PMN_per_mouse) * 1000;
	PMNcount = PMN_per_mouse * 1000;
	PMNper = PMNcount/TotCell;
	AMcount = am_per_mouse * 1000;
	AMper = AMcount/TotCell;

	SampCell = am_count + pmn_count;
	SampPMNCount = pmn_count;
	SampPMNPer = SampPMNCount/SampCell;
	SampAMCount = am_count;
	SampAMPer = SampAMCount/SampCell;

	LDH_uL = LDH__U_L_;
	albumin_mg_mL = albumin__mg_ml_;
run;


data WORK.MWCNT_03    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile 'Y:\ENM Categories\Sager MWCNT path.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

	informat path_num $8. mouse_num $10. particle $6. dose best32. days best32. distribution best32. severity best32. composite best32. ;

	format path_num $8. mouse_num $10. particle $6. dose best12. days best12. distribution best12. severity best12. composite best12. ;

	input path_num $ mouse_num $ particle $ dose days distribution severity composite;

	if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;
data mwcnt_04 (drop=mouse_num dose particle days distribution severity composite);
	set mwcnt_03 (drop=path_num);

	Chemical = "MWCNT";
	StudyRef = "Sager2013";
	study_type = "Sub-Acute";
	Duration = "7 days";
	Species = "Mouse";
	Strain = "C57BL/6J";
	Gender = "M";
	animal_id = mouse_num;
	Route = "PA";
	dose_amount = dose;
	dose_unit = "ug";
	treatment = particle;
	pe_d = days;

	Fibrosis_dist_score = distribution;
	Fibrosis_severity_score = severity;
	Fibrosis_composite_score = composite;

	format notes $128.;
	notes="no animal ids overlap with BAL";

run;


data db06;
	set db05 mwcnt_02 mwcnt_04;
run;




data WORK.SILICA_01    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile 'Y:\ENM Categories\EDA\eda macro v1.0 INPUT\silica97_cell_counts.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

	informat days best32. exposure $7. sample $3. rat__ $10. PMN best32. AM best32. total best32. __PMN best32. __AM best32. notes $100. ;

	format days best12. exposure $7. sample $3. rat__ $10. PMN best12. AM best12. total best12. __PMN best12. __AM best12. notes $100. ;

	input days exposure $ sample $ rat__ $ PMN AM total __PMN __AM notes $;

	if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;
data silica_02 (drop=days exposure sample rat__ pmn am total __PMN __AM);
	set silica_01;

	Chemical = "Silica";
	StudyRef = "Porter1997";
	study_type = "Sub-Chronic";
	Duration = "116 days";
	Species = "Rat";
	Strain = "Fischer 344";
	Gender = "M";
	animal_id = rat__;
	experiment_id = sample;
	Route = "Inh";

	if exposure="control" then dose_amount = 0;
	else if exposure="silica" then dose_amount = 15;

	dose_unit = "mg/m3";
	treatment = exposure;
	exp_d=days;
	pe_d = .;

	TotCell = total * 1000000;
	PMNcount = pmn * 1000000;
	PMNper = PMNcount/TotCell;
	AMcount = am * 1000000;
	AMper = AMcount/TotCell;

	SampCell = .;
	SampPMNCount = .;
	SampPMNPer = .;
	SampAMCount = .;
	SampAMPer = .;
run;




data WORK.SILICA_03    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile 'Y:\ENM Categories\EDA\eda macro v1.0 INPUT\silica99_cell_counts.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

	informat Exposure__days_ best32. Recovery__days_ best32. Treatment_Group $7. SiO2_Sample_code $5. AM_Yield___x106_cells_ best32. PMN___x106_cells_ best32. ;

	format Exposure__days_ best12. Recovery__days_ best12. Treatment_Group $7. SiO2_Sample_code $5. AM_Yield___x106_cells_ best12. PMN___x106_cells_ best12. ;

	input Exposure__days_ Recovery__days_ Treatment_Group $ SiO2_Sample_code $ AM_Yield___x106_cells_ PMN___x106_cells_;

	if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;
data silica_04 (drop=SiO2_Sample_code Treatment_Group Exposure__days_ Recovery__days_ AM_Yield___x106_cells_ PMN___x106_cells_);
	set silica_03;

	Chemical = "Silica";
	StudyRef = "Porter1999";
	study_type = "Sub-Chronic";
	Duration = "96 days";
	Species = "Rat";
	Strain = "Fischer 344";
	Gender = "M";
	animal_id = "";
	experiment_id = SiO2_Sample_code;
	Route = "Inh";

	if Treatment_Group="control" then dose_amount = 0;
	else if Treatment_Group="silica" then dose_amount = 15;

	treatment = Treatment_Group;
	exp_d = Exposure__days_;
	pe_d = Recovery__days_;

	TotCell = (AM_Yield___x106_cells_ +  PMN___x106_cells_)* 1000000;
	PMNcount = PMN___x106_cells_ * 1000000;
	PMNper = PMNcount/TotCell;
	AMcount = AM_Yield___x106_cells_ * 1000000;
	AMper = AMcount/TotCell;

	SampCell = .;
	SampPMNCount = .;
	SampPMNPer = .;
	SampAMCount = .;
	SampAMPer = .;
run;

data db07;
	set db06 silica_02 silica_04;
run;





data WORK.AG_06    ;	
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */	
	infile 'Y:\ENM Categories\NPRA In Vivo\enpra_ag1.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;	

	informat StudyRef $10. study_type $5. duration $5. species $5. strain $8. gender $1. route $2. chemical $2. 
				code $6. charac $2. size_nm best32. animal_nr $10. dose_ug_mouse best32. Timepoint_hrs best32. 
				prot_mg_L best32. LDH_U_L best32. totcc_E4_ml best32. macro_lung best32. neutro_lung best32. eos_lung best32. lympho_lung best32. 
				mono_lung best32. SS best32. abs_m_E4_ml best32. abs_n_E4_ml best32. abs_eos_E4_ml best32. weight_g best32. liver_g best32. 
				kidney_g best32. spleen_g best32. hart_g best32. brain_g best32. WBC_E9_L best32. RBC_E12_L best32. Hgb_nmol_L best32. 
				Hct_L_L best32. MCV_fL best32. MCH_fmol best32. MCHC_mmol_L best32. RDW best32. HDW_mmol_L best32. Plt_E9_L best32. 
				MPV_fL best32. MPC best32. neutro_b best32. lympho_b best32. mono_b best32. eos_b best32. luc_b best32. baso_b best32. abs_n_b_E9_L best32. 
				abs_l_b_E9_L best32. abs_mono_b_E9_L best32. abs_eos_b_E9_L best32. abs_luc_b_E9_L best32. abs_baso_b_E9_L best32. GSHlung_uM_mgprotein best32. 
				Com_T_lu best32. ComTL_lu best32. Com_T_li best32. ComTL_li best32. IL1b_pg_ml best32. IL4_pg_ml best32. IL6_pg_ml best32. IL12_pg_ml best32. 
				IL13_pg_ml best32. GCSF_pg_ml best32. KC_pg_ml best32. MCP1_pg_ml best32. MIP1b_pg_ml best32. RANTES_pg_ml best32. TNFa_pg_ml best32. 
				GSHli_uM_mg best32. ;	

	format 	StudyRef $10. study_type $5. duration $5. species $5. strain $8. gender $1. route $2. chemical $2. 
				code $6. charac $2. size_nm best32. animal_nr $10. dose_ug_mouse best32. Timepoint_hrs best32. 
				prot_mg_L best32. LDH_U_L best32. totcc_E4_ml best32. macro_lung best32. neutro_lung best32. eos_lung best32. lympho_lung best32. 
				mono_lung best32. SS best32. abs_m_E4_ml best32. abs_n_E4_ml best32. abs_eos_E4_ml best32. weight_g best32. liver_g best32. 
				kidney_g best32. spleen_g best32. hart_g best32. brain_g best32. WBC_E9_L best32. RBC_E12_L best32. Hgb_nmol_L best32. 
				Hct_L_L best32. MCV_fL best32. MCH_fmol best32. MCHC_mmol_L best32. RDW best32. HDW_mmol_L best32. Plt_E9_L best32. 
				MPV_fL best32. MPC best32. neutro_b best32. lympho_b best32. mono_b best32. eos_b best32. luc_b best32. baso_b best32. abs_n_b_E9_L best32. 
				abs_l_b_E9_L best32. abs_mono_b_E9_L best32. abs_eos_b_E9_L best32. abs_luc_b_E9_L best32. abs_baso_b_E9_L best32. GSHlung_uM_mgprotein best32. 
				Com_T_lu best32. ComTL_lu best32. Com_T_li best32. ComTL_li best32. IL1b_pg_ml best32. IL4_pg_ml best32. IL6_pg_ml best32. IL12_pg_ml best32. 
				IL13_pg_ml best32. GCSF_pg_ml best32. KC_pg_ml best32. MCP1_pg_ml best32. MIP1b_pg_ml best32. RANTES_pg_ml best32. TNFa_pg_ml best32. 
				GSHli_uM_mg best32. ;	

	input	StudyRef $	study_type $	duration $	species $	strain $	gender $	route $	chemical $	
			code $	charac $	size_nm	animal_nr $	dose_ug_mouse	Timepoint_hrs	
			prot_mg_L LDH_U_L totcc_E4_ml macro_lung neutro_lung eos_lung lympho_lung
			mono_lung SS abs_m_E4_ml abs_n_E4_ml abs_eos_E4_ml weight_g liver_g
			kidney_g spleen_g hart_g brain_g WBC_E9_L RBC_E12_L Hgb_nmol_L 
			Hct_L_L MCV_fL MCH_fmol MCHC_mmol_L RDW HDW_mmol_L Plt_E9_L
		   MPV_fL MPC neutro_b lympho_b mono_b eos_b luc_b baso_b abs_n_b_E9_L
			abs_l_b_E9_L abs_mono_b_E9_L abs_eos_b_E9_L abs_luc_b_E9_L abs_baso_b_E9_L GSHlung_uM_mgprotein
			Com_T_lu ComTL_lu Com_T_li ComTL_li IL1b_pg_ml IL4_pg_ml IL6_pg_ml IL12_pg_ml
			IL13_pg_ml GCSF_pg_ml KC_pg_ml MCP1_pg_ml MIP1b_pg_ml RANTES_pg_ml TNFa_pg_ml GSHli_uM_mg;
	
	if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */	
run;	

data ag_07 (drop=animal_nr dose_ug_mouse timepoint_hrs totcc_e4_ml abs_n_E4_ml abs_m_E4_ml lympho_lung SS abs_eos_E4_ml
						mono_lung neutro_lung macro_lung eos_lung ldh_u_l);
	set ag_06 (keep=studyref study_type duration species strain gender route chemical code charac size_nm animal_nr
							dose_ug_mouse	timepoint_hrs	ldh_u_l	totcc_e4_ml	macro_lung	neutro_lung	eos_lung	lympho_lung
							mono_lung	ss	abs_m_E4_ml abs_n_E4_ml abs_eos_E4_ml weight_g IL1b_pg_ml IL4_pg_ml IL6_pg_ml IL12_pg_ml
							IL13_pg_ml	TNFa_pg_ml);

	animal_id = animal_nr;
	dose_amount=dose_ug_mouse;
	dose_unit="ug/mouse";

	pe_d = 1;

	TotCell = totcc_e4_ml * 100000;	/* x 10e4 */
	PMNcount = abs_n_E4_ml * 100000;
	PMNper = PMNcount/TotCell;
	AMcount = abs_m_E4_ml * 100000;
	AMper = AMcount/TotCell;
	Lymphcount = (lympho_lung/SS)*TotCell;
	Eosincount = abs_eos_E4_ml * 100000;
	Monocount = (mono_lung/SS)*TotCell;

	SampCell = ss;
	SampPMNCount = neutro_lung;
	SampPMNPer = SampPMNCount/SampCell;
	SampAMCount = macro_lung;
	SampAMPer = SampAMCount/SampCell;
	SampLymphCount = lympho_lung;
	SampEosinCount = eos_lung;
	SampMonoCount = mono_lung;

	LDH_uL = ldh_u_l;

	format notes $128.;
	notes="weight_g = body weight after instillation/weight beforeinstillation*100%";
run;


data db08;
	set db07 ag_07;
run;





data WORK.MWCNT_05    ;	
	%let _EFIERR_ = 0; /* set the ERR	OR detection macro variable */
	infile 'Y:\ENM Categories\NPRA In Vivo\enpra_mwcnt1.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs	=2 ;

	informat StudyRef $11. study_type $8. duration $7. species $5. strain $8. gender $1. route $2. Chemical $5. code $5. 
				charac $10. size_dia_nm best32. size_length_um best32. animal_nr $5. dose_ug_mouse best32.	exp_d best32. pe_d  best32. 
				Weight_1_instil best32. Weight_2_instil best32. Weight_3_instil best32. Weight_4_instil best32. 
				Weight_5_instil best32. Weight_at_end best32. total_cells best32. macro_lung best32. neutro_lung best32. 
				eos_lung best32. lympho_lung best32. epithelial_lung best32. Scored_cells best32.	prot_mg_L best32. ;	

	format 	StudyRef $11. study_type $8. duration $7. species $5. strain $8. gender $1. route $2. Chemical $5. code $5. 
				charac $10. size_dia_nm best12. size_length_um best12. animal_nr $5. dose_ug_mouse best12. exp_d best32. pe_d  best32. 
				Weight_1_instil best12.	Weight_2_instil best12.	Weight_3_instil best12.	Weight_4_instil best12.	
				Weight_5_instil best12.	Weight_at_end best12. total_cells best12. macro_lung best12. neutro_lung best12. 
				eos_lung best12. lympho_lung best12. epithelial_lung best12. Scored_cells best12. prot_mg_L best32. ;	

	input	StudyRef $	study_type $	duration $	species $	strain $	gender $	route $	Chemical $	code $	
			charac $	size_dia_nm	size_length_um	animal_nr $	dose_ug_mouse	exp_d pe_d 
			Weight_1_instil	Weight_2_instil	Weight_3_instil	Weight_4_instil	
			Weight_5_instil	Weight_at_end	total_cells	macro_lung	neutro_lung	
			eos_lung	lympho_lung	epithelial_lung	Scored_cells	prot_mg_L 	;	

	if _ERROR_ then call symputx('_EF	IERR_',1);  /* set ERROR detection macro variable */	
run;	
data mwcnt_06 (drop=animal_nr dose_ug_mouse total_cells macro_lung neutro_lung lympho_lung eos_lung epithelial_lung scored_cells weight_1_instil weight_at_end);
	set mwcnt_05 (drop=Weight_2_instil Weight_3_instil Weight_4_instil Weight_5_instil prot_mg_L);

	animal_id = animal_nr;
	dose_amount=dose_ug_mouse;
	dose_unit="ug/mouse";

	TotCell = total_cells;	
	PMNcount = neutro_lung;
	PMNper = PMNcount/TotCell;
	AMcount = macro_lung;
	AMper = AMcount/TotCell;
	Lymphcount = lympho_lung;
	Eosincount = eos_lung;
	Epithelialcount = epithelial_lung;

	SampCell = Scored_cells;
	SampPMNCount = .;
	SampPMNPer = .;
	SampAMCount = .;
	SampAMPer = .;
	SampLymphCount = .;
	SampEosinCount = .;
	SampMonoCount = .;

	BWstart=Weight_1_instil;
	BWend = Weight_at_end;

	format notes $128.;
	notes="BWstart=Weight_1_instil which is Weight after first exposure (day 0)";
run;

data db09;
	format charac $20.;
	set db08 mwcnt_06;
run;

libname dsk "C:\Users\vom8\Desktop\invivo_db_8may2015";
data dsk.db09;
	set db09;
run;



data WORK.MWCNT_07    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile "Y:\ENM Categories\NPRA In Vivo\enpra_mwcnt2.csv" delimiter =',' MISSOVER DSD lrecl=32767 firstobs=2 ;

	informat StudyRef $11. study_type $8. duration $7. species $5. strain $15. gender $1. route $2. chemical $5. 
				code $5. charac $10. size_dia_nm best32. size_length_um best32. animal_nr $5. dose_ug_mouse best32. 
				exp_d best32. pe_d best32. Weight_1_instil best32. Weight_2_instil best32. Weight_3_instil best32. 
				Weight_4_instil best32. Weight_5_instil best32. Weight_at_end best32. Plaque_mean_area_ best32. 
				total_cells best32. macro_lung best32. neutro_lung best32. eos_lung best32. lympho_lung best32. 
				epithelial_lung best32. Scored_cells best32. prot_mg_L $1. LDH_U_L $1. VAR33 $1. ;

	format 	StudyRef $11. study_type $8. duration $7. species $5. strain $15. gender $1. route $2. chemical $5. 
				code $5. charac $10. size_dia_nm best32. size_length_um best32. animal_nr $5. dose_ug_mouse best32. 
				exp_d best32. pe_d best32. Weight_1_instil best32. Weight_2_instil best32. Weight_3_instil best32. 
				Weight_4_instil best32. Weight_5_instil best32. Weight_at_end best32. Plaque_mean_area_ best32. 
				total_cells best32. macro_lung best32. neutro_lung best32. eos_lung best32. lympho_lung best32. 
				epithelial_lung best32. Scored_cells best32. prot_mg_L $1. LDH_U_L $1. VAR33 $1. ;

	input StudyRef $ study_type $ duration $ species $ strain $ gender $ route $ chemical $ code $ charac $ size_dia_nm size_length_um animal_nr $ 
			dose_ug_mouse exp_d pe_d Weight_1_instil Weight_2_instil Weight_3_instil Weight_4_instil Weight_5_instil Weight_at_end Plaque_mean_area_ 
			total_cells macro_lung neutro_lung eos_lung lympho_lung epithelial_lung Scored_cells prot_mg_L $ LDH_U_L $ VAR33 $;

	if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;
data mwcnt_08 (drop=animal_nr dose_ug_mouse total_cells macro_lung neutro_lung lympho_lung eos_lung epithelial_lung scored_cells weight_1_instil weight_at_end);
	set mwcnt_07 (drop= var33 LDH_U_L Plaque_mean_area_ Weight_2_instil Weight_3_instil Weight_4_instil Weight_5_instil prot_mg_L);

	animal_id = animal_nr;
	dose_amount=dose_ug_mouse;
	dose_unit="ug/mouse";

	TotCell = total_cells;	
	PMNcount = neutro_lung;
	PMNper = PMNcount/TotCell;
	AMcount = macro_lung;
	AMper = AMcount/TotCell;
	Lymphcount = lympho_lung;
	Eosincount = eos_lung;
	Epithelialcount = epithelial_lung;

	SampCell = Scored_cells;
	SampPMNCount = .;
	SampPMNPer = .;
	SampAMCount = .;
	SampAMPer = .;
	SampLymphCount = .;
	SampEosinCount = .;
	SampMonoCount = .;

	BWstart=Weight_1_instil;
	BWend = Weight_at_end;

	format notes $128.;
	notes="BWstart=Weight_1_instil which is Weight after first exposure (day 0)";
run;


data db10;
	set db09 mwcnt_08;
run;




data WORK.MWCNT_09    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile "Y:\ENM Categories\NPRA In Vivo\enpra_mwcnt3.csv" delimiter =',' MISSOVER DSD lrecl=32767 firstobs=2 ;

	informat StudyRef $11. study_type $8. duration $7. species $5. strain $15. gender $1. route $2. chemical $5. 
				code $5. charac $11. size_dia_nm best32. size_length_um best32. animal_nr $5. dose_ug_mouse best32. 
				exp_d best32. pe_d best32. Weight_1_instil best32. Weight_2_instil best32. Weight_3_instil best32. Weight_4_instil best32. 
				Weight_5_instil best32. Weight_at_end best32. Plaque_mean_area_ best32. total_cells best32. macro_lung best32. 
				neutro_lung best32. eos_lung best32. lympho_lung best32. epithelial_lung best32. Scored_cells best32. prot_mg_L $1. 
				LDH_U_L $1. VAR32 $1. ;

	format	StudyRef $11. study_type $8. duration $7. species $5. strain $15. gender $1. route $2. chemical $5. 
				code $5. charac $11. size_dia_nm best32. size_length_um best32. animal_nr $5. dose_ug_mouse best32. 
				exp_d best32. pe_d best32. Weight_1_instil best32. Weight_2_instil best32. Weight_3_instil best32. Weight_4_instil best32. 
				Weight_5_instil best32. Weight_at_end best32. Plaque_mean_area_ best32. total_cells best32. macro_lung best32. 
				neutro_lung best32. eos_lung best32. lympho_lung best32. epithelial_lung best32. Scored_cells best32. prot_mg_L $1. 
				LDH_U_L $1. VAR32 $1. ;

	input StudyRef $ study_type $ duration $ species $ strain $ gender $ route $ chemical $ code $ charac $ size_dia_nm size_length_um 
			animal_nr $ dose_ug_mouse exp_d pe_d $ Weight_1_instil Weight_2_instil Weight_3_instil Weight_4_instil Weight_5_instil Weight_at_end 
			Plaque_mean_area_ total_cells macro_lung neutro_lung eos_lung lympho_lung epithelial_lung Scored_cells prot_mg_L $ LDH_U_L $ VAR32 $;

	if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;
data mwcnt_10 (drop=animal_nr dose_ug_mouse total_cells macro_lung neutro_lung lympho_lung eos_lung epithelial_lung scored_cells weight_1_instil weight_at_end);
	set mwcnt_09 (drop= var32 LDH_U_L Plaque_mean_area_ Weight_2_instil Weight_3_instil Weight_4_instil Weight_5_instil prot_mg_L);

	animal_id = animal_nr;
	dose_amount=dose_ug_mouse;
	dose_unit="ug/mouse";

	TotCell = total_cells;	
	PMNcount = neutro_lung;
	PMNper = PMNcount/TotCell;
	AMcount = macro_lung;
	AMper = AMcount/TotCell;
	Lymphcount = lympho_lung;
	Eosincount = eos_lung;
	Epithelialcount = epithelial_lung;

	SampCell = Scored_cells;
	SampPMNCount = .;
	SampPMNPer = .;
	SampAMCount = .;
	SampAMPer = .;
	SampLymphCount = .;
	SampEosinCount = .;
	SampMonoCount = .;

	BWstart=Weight_1_instil;
	BWend = Weight_at_end;

	format notes $128.;
	notes="BWstart=Weight_1_instil which is Weight after first exposure (day 0)";
run;

data db11;
	set db10 mwcnt_10;
run;




data WORK.MWCNT_11    ;	
	%let _EFIERR_ = 0; /* set the ERR	OR detection macro variable */
	infile "Y:\ENM Categories\NPRA In Vivo\enpra_mwcnt4.csv" delimiter =',' MISSOVER DSD lrecl=32767 firstobs=2 ;

	informat StudyRef $11. study_type $8. duration $7. species $5. strain $8. gender $1. route $2. chemical $5. JRC_code $5. 
				characterization $11. size_dia_nm best32. size_length_um best32. animal_nr $5. dose_ug_mouse best32. exp_d best32. 
				pe_d best32. Weight_1_instil best32. Weight_2_instil best32. Weight_3_instil best32. Weight_4_instil best32. 
				Weight_5_instil best32. Weight_at_end best32. total_cells best32. macro_lung best32. neutro_lung best32. eos_lung best32. 
				lympho_lung best32. epithelial_lung best32. Scored_cells best32. prot_mg_L $1. LDH_U_L $1. ;	

	format	StudyRef $11. study_type $8. duration $7. species $5. strain $8. gender $1. route $2. chemical $5. JRC_code $5. 
				characterization $11. size_dia_nm best32. size_length_um best32. animal_nr $5. dose_ug_mouse best32. exp_d best32. 
				pe_d best32. Weight_1_instil best32. Weight_2_instil best32. Weight_3_instil best32. Weight_4_instil best32. 
				Weight_5_instil best32. Weight_at_end best32. total_cells best32. macro_lung best32. neutro_lung best32. eos_lung best32. 
				lympho_lung best32. epithelial_lung best32. Scored_cells best32. prot_mg_L $1. LDH_U_L $1. ;	

	input	StudyRef $	study_type $	duration $	species $	strain $	gender $	route $	chemical $	JRC_code $	characterization $	size_dia_nm	
			size_length_um	animal_nr $	dose_ug_mouse	exp_d	pe_d	Weight_1_instil	Weight_2_instil	Weight_3_instil	Weight_4_instil	
			Weight_5_instil	Weight_at_end	total_cells	macro_lung	neutro_lung	eos_lung	lympho_lung	epithelial_lung	Scored_cells	prot_mg_L $	LDH_U_L $;	

	if _ERROR_ then call symputx('_EF	IERR_',1);  /* set ERROR detection macro variable */	
run;	
data mwcnt_12 (drop=animal_nr dose_ug_mouse total_cells macro_lung neutro_lung lympho_lung eos_lung epithelial_lung scored_cells weight_1_instil weight_at_end);
	set mwcnt_11 (drop= JRC_code LDH_U_L Weight_2_instil Weight_3_instil Weight_4_instil Weight_5_instil prot_mg_L);

	animal_id = animal_nr;
	dose_amount=dose_ug_mouse;
	dose_unit="ug/mouse";

	TotCell = total_cells;	
	PMNcount = neutro_lung;
	PMNper = PMNcount/TotCell;
	AMcount = macro_lung;
	AMper = AMcount/TotCell;
	Lymphcount = lympho_lung;
	Eosincount = eos_lung;
	Epithelialcount = epithelial_lung;

	SampCell = Scored_cells;
	SampPMNCount = .;
	SampPMNPer = .;
	SampAMCount = .;
	SampAMPer = .;
	SampLymphCount = .;
	SampEosinCount = .;
	SampMonoCount = .;

	BWstart=Weight_1_instil;
	BWend = Weight_at_end;

	format notes $128.;
	notes="BWstart=Weight_1_instil which is Weight after first exposure (day 0)";
run;

data db12;
	set db11 mwcnt_12;
run;
	
	
	
	
	

data WORK.MWCNT_13    ;	
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */	
	infile "Y:\ENM Categories\NPRA In Vivo\enpra_mwcnt5.csv" delimiter =	',' MISSOVER DSD lrecl=32767 firstobs=2 ;	

	informat StudyRef $10. study_type $5. duration $5. species $5. strain $8. gender $1. route $2. chemical $5. code $5. 
				charac $4. size_nm best32. animal_nr $10. dose_ug_mouse best32. Timepoint_hrs best32. prot_mg_L best32. 
				LDH_U_L best32. totcc_E4_ml best32. macro_lung best32. neutro_lung best32. eos_lung best32. lympho_lung best32. 
				mono_lung best32. SS best32. abs_m_E4_ml best32. abs_n_E4_ml best32. abs_eos_E4_ml best32. weight_g best32. 
				liver_g best32. kidney_g best32. spleen_g best32. hart_g best32. brain_g best32. WBC_E9_L best32. RBC_E12_L best32. 
				Hgb_nmol_L best32. Hct_L_L best32. MCV_fL best32. MCH_fmol best32. MCHC_mmol_L $8. RDW best32. HDW_mmol_L $7. Plt_E9_L best32. 
				MPV_fL best32. MPC best32. neutro_b best32. lympho_b best32. mono_b best32. eos_b best32. luc_b best32. baso_b best32. abs_n_b_E9_L best32. 
				abs_l_b_E9_L best32. abs_mono_b_E9_L best32. abs_eos_b_E9_L best32. abs_luc_b_E9_L best32. abs_baso_b_E9_L best32. GSHlung_uM_mgprotein best32. 
				Com_T_lu best32. ComTL_lu best32. Com_T_li best32. ComTL_li best32. IL1b_pg_ml best32. IL4_pg_ml best32. IL6_pg_ml best32. IL12_pg_ml best32. 
				IL13_pg_ml best32. GCSF_pg_ml best32. KC_pg_ml best32. MCP1_pg_ml best32. MIP1b_pg_ml best32. RANTES_pg_ml best32. TNFa_pg_ml best32. 
				GSHli_uM_mg best32. ;	

	format 	StudyRef $10. study_type $5. duration $5. species $5. strain $8. gender $1. route $2. chemical $5. code $5. 
				charac $4. size_nm best32. animal_nr $10. dose_ug_mouse best32. Timepoint_hrs best32. prot_mg_L best32. 
				LDH_U_L best32. totcc_E4_ml best32. macro_lung best32. neutro_lung best32. eos_lung best32. lympho_lung best32. 
				mono_lung best32. SS best32. abs_m_E4_ml best32. abs_n_E4_ml best32. abs_eos_E4_ml best32. weight_g best32. 
				liver_g best32. kidney_g best32. spleen_g best32. hart_g best32. brain_g best32. WBC_E9_L best32. RBC_E12_L best32. 
				Hgb_nmol_L best32. Hct_L_L best32. MCV_fL best32. MCH_fmol best32. MCHC_mmol_L $8. RDW best32. HDW_mmol_L $7. Plt_E9_L best32. 
				MPV_fL best32. MPC best32. neutro_b best32. lympho_b best32. mono_b best32. eos_b best32. luc_b best32. baso_b best32. abs_n_b_E9_L best32. 
				abs_l_b_E9_L best32. abs_mono_b_E9_L best32. abs_eos_b_E9_L best32. abs_luc_b_E9_L best32. abs_baso_b_E9_L best32. GSHlung_uM_mgprotein best32. 
				Com_T_lu best32. ComTL_lu best32. Com_T_li best32. ComTL_li best32. IL1b_pg_ml best32. IL4_pg_ml best32. IL6_pg_ml best32. IL12_pg_ml best32. 
				IL13_pg_ml best32. GCSF_pg_ml best32. KC_pg_ml best32. MCP1_pg_ml best32. MIP1b_pg_ml best32. RANTES_pg_ml best32. TNFa_pg_ml best32. 
				GSHli_uM_mg best32. ;

	input	StudyRef $	study_type $	duration $	species $	strain $	gender $	route $	chemical $	code $	charac $	size_nm	animal_nr $	dose_ug_mouse	
			Timepoint_hrs	prot_mg_L	LDH_U_L	totcc_E4_ml	macro_lung	neutro_lung	eos_lung	lympho_lung	mono_lung	SS	abs_m_E4_ml	abs_n_E4_ml	abs_eos_E4_ml	
			weight_g	liver_g	kidney_g	spleen_g	hart_g	brain_g	WBC_E9_L	RBC_E12_L	Hgb_nmol_L	Hct_L_L	MCV_fL	MCH_fmol	MCHC_mmol_L $	RDW	HDW_mmol_L $	
			Plt_E9_L	MPV_fL	MPC	neutro_b	lympho_b	mono_b	eos_b	luc_b	baso_b	abs_n_b_E9_L	abs_l_b_E9_L	abs_mono_b_E9_L	abs_eos_b_E9_L	abs_luc_b_E9_L	
			abs_baso_b_E9_L	GSHlung_uM_mgprotein	Com_T_lu	ComTL_lu	Com_T_li	ComTL_li	IL1b_pg_ml	IL4_pg_ml	IL6_pg_ml	IL12_pg_ml	IL13_pg_ml	GCSF_pg_ml	
			KC_pg_ml	MCP1_pg_ml	MIP1b_pg_ml	RANTES_pg_ml	TNFa_pg_ml	GSHli_uM_mg	;	

	if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection	macro variable */	
run;	
data mwcnt_14 (drop=animal_nr dose_ug_mouse totcc_e4_ml abs_n_E4_ml abs_m_E4_ml lympho_lung SS abs_eos_E4_ml mono_lung neutro_lung macro_lung
							ldh_u_l eos_lung);

	set mwcnt_13 (drop = liver_g	kidney_g	spleen_g	hart_g	brain_g	WBC_E9_L	RBC_E12_L	Hgb_nmol_L	Hct_L_L	MCV_fL	MCH_fmol	MCHC_mmol_L	RDW	HDW_mmol_L	
			Plt_E9_L	MPV_fL	MPC	neutro_b	lympho_b	mono_b	eos_b	luc_b	baso_b	abs_n_b_E9_L	abs_l_b_E9_L	abs_mono_b_E9_L	abs_eos_b_E9_L	abs_luc_b_E9_L	
			abs_baso_b_E9_L	GSHlung_uM_mgprotein	Com_T_lu	ComTL_lu	Com_T_li	ComTL_li GCSF_pg_ml	
			KC_pg_ml	MCP1_pg_ml	MIP1b_pg_ml	RANTES_pg_ml GSHli_uM_mg
			Timepoint_hrs	prot_mg_L);

	animal_id = animal_nr;
	dose_amount=dose_ug_mouse;
	dose_unit="ug/mouse";

	pe_d = 1;

	TotCell = totcc_e4_ml * 100000;	/* x 10e4 */
	PMNcount = abs_n_E4_ml * 100000;
	PMNper = PMNcount/TotCell;
	AMcount = abs_m_E4_ml * 100000;
	AMper = AMcount/TotCell;
	Lymphcount = (lympho_lung/SS)*TotCell;
	Eosincount = abs_eos_E4_ml * 100000;
	Monocount = (mono_lung/SS)*TotCell;

	SampCell = ss;
	SampPMNCount = neutro_lung;
	SampPMNPer = SampPMNCount/SampCell;
	SampAMCount = macro_lung;
	SampAMPer = SampAMCount/SampCell;
	SampLymphCount = lympho_lung;
	SampEosinCount = eos_lung;
	SampMonoCount = mono_lung;

	LDH_uL = ldh_u_l;

	format notes $128.;
	notes="weight_g = body weight after instillation/weight beforeinstillation*100%";
run;

data db13;
	set db12 mwcnt_14;
run;







data WORK.MWCNT_15    ;	
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */	
	infile "Y:\ENM Categories\NPRA In Vivo\enpra_mwcnt6.csv" delimiter =	',' MISSOVER DSD lrecl=32767 firstobs=2 ;	

informat StudyRef $10. ;	
informat study_type $5. ;	
informat duration $5. ;	
informat species $5. ;	
informat strain $8. ;	
informat gender $1. ;	
informat route $2. ;	
informat chemical $5. ;	
informat code $5. ;	
informat charac $5. ;	
informat size_nm best32. ;	
informat animal_nr $10. ;	
informat dose_ug_mouse best32. ;	
informat Timepoint_hrs best32. ;	
informat prot_mg_L best32. ;	
informat LDH_U_L best32. ;	
informat totcc_E4_ml best32. ;	
informat macro_lung best32. ;	
informat neutro_lung best32. ;	
informat eos_lung best32. ;	
informat lympho_lung best32. ;	
informat mono_lung best32. ;	
informat SS best32. ;	
informat abs_m_E4_ml best32. ;	
informat abs_n_E4_ml best32. ;	
informat abs_eos_E4_ml best32. ;	
informat weight_g best32. ;	
informat liver_g best32. ;	
informat kidney_g best32. ;	
informat spleen_g best32. ;	
informat hart_g best32. ;	
informat brain_g best32. ;	
informat WBC_E9_L best32. ;	
informat RBC_E12_L best32. ;	
informat Hgb_nmol_L best32. ;	
informat Hct_L_L best32. ;	
informat MCV_fL best32. ;	
informat MCH_fmol best32. ;	
informat MCHC_mmol_L $8. ;	
informat RDW best32. ;	
informat HDW_mmol_L $7. ;	
informat Plt_E9_L best32. ;	
informat MPV_fL best32. ;	
informat MPC best32. ;	
informat neutro_b best32. ;	
informat lympho_b best32. ;	
informat mono_b best32. ;	
informat eos_b best32. ;	
informat luc_b $4. ;	
informat baso_b best32. ;	
informat abs_n_b_E9_L best32. ;	
informat abs_l_b_E9_L best32. ;	
informat abs_mono_b_E9_L best32. ;	
informat abs_eos_b_E9_L best32. ;	
informat abs_luc_b_E9_L best32. ;	
informat abs_baso_b_E9_L best32. ;	
informat GSHlung_uM_mgprotein best32. ;	
informat Com_T_lu best32. ;	
informat ComTL_lu best32. ;	
informat Com_T_li best32. ;	
informat ComTL_li best32. ;	
informat IL1b_pg_ml best32. ;	
informat IL4_pg_ml best32. ;	
informat IL6_pg_ml best32. ;	
informat IL12_pg_ml best32. ;	
informat IL13_pg_ml best32. ;	
informat GCSF_pg_ml best32. ;	
informat KC_pg_ml best32. ;	
informat MCP1_pg_ml best32. ;	
informat MIP1b_pg_ml best32. ;	
informat RANTES_pg_ml best32. ;	
informat TNFa_pg_ml best32. ;	
informat GSHli_uM_mg best32. ;	
format StudyRef $10. ;	
format study_type $5. ;	
format duration $5. ;	
format species $5. ;	
format strain $8. ;	
format gender $1. ;	
format route $2. ;	
format chemical $5. ;	
format code $5. ;	
format charac $5. ;	
format size_nm best12. ;	
format animal_nr $10. ;	
format dose_ug_mouse best12. ;	
format Timepoint_hrs best12. ;	
format prot_mg_L best12. ;	
format LDH_U_L best12. ;	
format totcc_E4_ml best12. ;	
format macro_lung best12. ;	
format neutro_lung best12. ;	
format eos_lung best12. ;	
format lympho_lung best12. ;	
format mono_lung best12. ;	
format SS best12. ;	
format abs_m_E4_ml best12. ;	
format abs_n_E4_ml best12. ;	
format abs_eos_E4_ml best12. ;	
format weight_g best12. ;	
format liver_g best12. ;	
format kidney_g best12. ;	
format spleen_g best12. ;	
format hart_g best12. ;	
format brain_g best12. ;	
format WBC_E9_L best12. ;	
format RBC_E12_L best12. ;	
format Hgb_nmol_L best12. ;	
format Hct_L_L best12. ;	
format MCV_fL best12. ;	
format MCH_fmol best12. ;	
format MCHC_mmol_L $8. ;	
format RDW best12. ;	
format HDW_mmol_L $7. ;	
format Plt_E9_L best12. ;	
format MPV_fL best12. ;	
format MPC best12. ;	
format neutro_b best12. ;	
format lympho_b best12. ;	
format mono_b best12. ;	
format eos_b best12. ;	
format luc_b $4. ;	
format baso_b best12. ;	
format abs_n_b_E9_L best12. ;	
format abs_l_b_E9_L best12. ;	
format abs_mono_b_E9_L best12. ;	
format abs_eos_b_E9_L best12. ;	
format abs_luc_b_E9_L best12. ;	
format abs_baso_b_E9_L best12. ;	
format GSHlung_uM_mgprotein best12. ;	
format Com_T_lu best12. ;	
format ComTL_lu best12. ;	
format Com_T_li best12. ;	
format ComTL_li best12. ;	
format IL1b_pg_ml best12. ;	
format IL4_pg_ml best12. ;	
format IL6_pg_ml best12. ;	
format IL12_pg_ml best12. ;	
format IL13_pg_ml best12. ;	
format GCSF_pg_ml best12. ;	
format KC_pg_ml best12. ;	
format MCP1_pg_ml best12. ;	
format MIP1b_pg_ml best12. ;	
format RANTES_pg_ml best12. ;	
format TNFa_pg_ml best12. ;	
format GSHli_uM_mg best12. ;	
input	
StudyRef $	
study_type $	
duration $	
species $	
strain $	
gender $	
route $	
chemical $	
code $	
charac $	
size_nm	
animal_nr	$
dose_ug_mouse	
Timepoint_hrs	
prot_mg_L	
LDH_U_L	
totcc_E4_ml	
macro_lung	
neutro_lung	
eos_lung	
lympho_lung	
mono_lung	
SS	
abs_m_E4_ml	
abs_n_E4_ml	
abs_eos_E4_ml	
weight_g	
liver_g	
kidney_g	
spleen_g	
hart_g	
brain_g	
WBC_E9_L	
RBC_E12_L	
Hgb_nmol_L	
Hct_L_L	
MCV_fL	
MCH_fmol	
MCHC_mmol_L $	
RDW	
HDW_mmol_L $	
Plt_E9_L	
MPV_fL	
MPC	
neutro_b	
lympho_b	
mono_b	
eos_b	
luc_b $	
baso_b	
abs_n_b_E9_L	
abs_l_b_E9_L	
abs_mono_b_E9_L	
abs_eos_b_E9_L	
abs_luc_b_E9_L	
abs_baso_b_E9_L	
GSHlung_uM_mgprotein	
Com_T_lu	
ComTL_lu	
Com_T_li	
ComTL_li	
IL1b_pg_ml	
IL4_pg_ml	
IL6_pg_ml	
IL12_pg_ml	
IL13_pg_ml	
GCSF_pg_ml	
KC_pg_ml	
MCP1_pg_ml	
MIP1b_pg_ml	
RANTES_pg_ml	
TNFa_pg_ml	
GSHli_uM_mg	
;	
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */	
run;	

data mwcnt_16 (drop=animal_nr dose_ug_mouse totcc_e4_ml abs_n_E4_ml abs_m_E4_ml lympho_lung SS abs_eos_E4_ml mono_lung neutro_lung macro_lung
							ldh_u_l eos_lung);

	set mwcnt_15 (drop = liver_g	kidney_g	spleen_g	hart_g	brain_g	WBC_E9_L	RBC_E12_L	Hgb_nmol_L	Hct_L_L	MCV_fL	MCH_fmol	MCHC_mmol_L	RDW	HDW_mmol_L	
			Plt_E9_L	MPV_fL	MPC	neutro_b	lympho_b	mono_b	eos_b	luc_b	baso_b	abs_n_b_E9_L	abs_l_b_E9_L	abs_mono_b_E9_L	abs_eos_b_E9_L	abs_luc_b_E9_L	
			abs_baso_b_E9_L	GSHlung_uM_mgprotein	Com_T_lu	ComTL_lu	Com_T_li	ComTL_li GCSF_pg_ml	
			KC_pg_ml	MCP1_pg_ml	MIP1b_pg_ml	RANTES_pg_ml GSHli_uM_mg
			Timepoint_hrs	prot_mg_L);

	animal_id = animal_nr;
	dose_amount=dose_ug_mouse;
	dose_unit="ug/mouse";

	pe_d = 1;

	TotCell = totcc_e4_ml * 100000;	/* x 10e4 */
	PMNcount = abs_n_E4_ml * 100000;
	PMNper = PMNcount/TotCell;
	AMcount = abs_m_E4_ml * 100000;
	AMper = AMcount/TotCell;
	Lymphcount = (lympho_lung/SS)*TotCell;
	Eosincount = abs_eos_E4_ml * 100000;
	Monocount = (mono_lung/SS)*TotCell;

	SampCell = ss;
	SampPMNCount = neutro_lung;
	SampPMNPer = SampPMNCount/SampCell;
	SampAMCount = macro_lung;
	SampAMPer = SampAMCount/SampCell;
	SampLymphCount = lympho_lung;
	SampEosinCount = eos_lung;
	SampMonoCount = mono_lung;

	LDH_uL = ldh_u_l;

	format notes $128.;
	notes="weight_g = body weight after instillation/weight beforeinstillation*100%";
run;

data db14;
	set db13 mwcnt_16;
run;




data WORK.MWCNT_17    ;	
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */	
	infile 'Y:\ENM Categories\NPRA In Vivo\enpra_mwcnt7.csv' delimiter =	',' MISSOVER DSD lrecl=32767 firstobs=2 ;	

informat StudyRef $8. ;	
informat study_type $11. ;	
informat duration $8. ;	
informat species $5. ;	
informat strain $8. ;	
informat gender $1. ;	
informat route $2. ;	
informat chemical $5. ;	
informat code $6. ;	
informat charac $9. ;	
informat size_nm $10. ;	
informat dose_ug_mouse best32. ;	
informat description $7. ;	
informat timepoint_m best32. ;	
informat prot_mg_L best32. ;	
informat LDH_U_L best32. ;	
informat totcc best32. ;	
informat macro__ best32. ;	
informat neutro__ best32. ;	
informat eos__ best32. ;	
informat lympho__ best32. ;	
informat SS best32. ;	
informat OH_proline best32. ;	
informat IL_1alpha best32. ;	
informat IL_1beta best32. ;	
informat IL_6 best32. ;	
informat IL_13 best32. ;	
informat OPN best32. ;	
informat TGF_beta1 best32. ;	
informat TNF_alpha best32. ;	
format StudyRef $8. ;	
format study_type $11. ;	
format duration $8. ;	
format species $5. ;	
format strain $8. ;	
format gender $1. ;	
format route $2. ;	
format chemical $5. ;	
format code $6. ;	
format charac $9. ;	
format size_nm $10. ;	
format dose_ug_mouse best12. ;	
format description $7. ;	
format timepoint_m best12. ;	
format prot_mg_L best12. ;	
format LDH_U_L best12. ;	
format totcc best12. ;	
format macro__ best12. ;	
format neutro__ best12. ;	
format eos__ best12. ;	
format lympho__ best12. ;	
format SS best12. ;	
format OH_proline best12. ;	
format IL_1alpha best12. ;	
format IL_1beta best12. ;	
format IL_6 best12. ;	
format IL_13 best12. ;	
format OPN best12. ;	
format TGF_beta1 best12. ;	
format TNF_alpha best12. ;	
input	
StudyRef $	
study_type $	
duration $	
species $	
strain $	
gender $	
route $	
chemical $	
code $	
charac $	
size_nm $	
dose_ug_mouse	
description $	
timepoint_m	
prot_mg_L	
LDH_U_L	
totcc	
macro__	
neutro__	
eos__	
lympho__	
SS	
OH_proline	
IL_1alpha	
IL_1beta	
IL_6	
IL_13	
OPN	
TGF_beta1	
TNF_alpha	
;	
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection	
macro variable */	
run;	
	
data mwcnt_18 (drop=dose_ug_mouse timepoint_m totcc neutro__ macro__ lympho__ eos__ ss ldh_u_l OH_proline);
	set mwcnt_17 (drop=TGF_beta1 OPN prot_mg_L);

	dose_amount=dose_ug_mouse;
	dose_unit="ug/mouse";

	pe_d = 60;

	TotCell = totcc ;	/* x 10e4 */
	PMNper = neutro__ / 100;
	PMNcount = PMNper*TotCell;
	AMper = macro__ / 100;
	AMcount = AMper*TotCell;
	Lymphcount = (lympho__ / 100) * TotCell;
	Eosincount = (eos__ /100) * TotCell;

	SampCell = ss;
	SampPMNCount = .;
	SampPMNPer = .;
	SampAMCount = .;
	SampAMPer = .;
	SampLymphCount = .;
	SampEosinCount = .;

	LDH_uL = ldh_u_l;

	hydroxyproline_ug_lung = OH_proline;

	format notes $128.;
	notes="pe_d = 2 months post-exposure";
run;
	
data db15;
	set db14 mwcnt_18 (rename=(size_nm=size_nm2));
run;
	





data WORK.MWCNT_19    ;	
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */	
	infile 'Y:\ENM Categories\NPRA In Vivo\enpra_mwcnt8.csv' delimiter =	',' MISSOVER DSD lrecl=32767 firstobs=2 ;	

informat StudyRef $8. ;	
informat study_type $11. ;	
informat duration $8. ;	
informat species $5. ;	
informat strain $8. ;	
informat gender $1. ;	
informat route $2. ;	
informat chemical $5. ;	
informat code $6. ;	
informat charac $9. ;	
informat size_nm $10. ;	
informat dose_ug_mouse best32. ;	
informat description $7. ;	
informat timepoint_m best32. ;	
informat prot_mg_L best32. ;	
informat LDH_U_L best32. ;	
informat totcc best32. ;	
informat macro__ best32. ;	
informat neutro__ best32. ;	
informat eos__ best32. ;	
informat lympho__ best32. ;	
informat SS best32. ;	
informat OH_proline best32. ;	
informat IL_1alpha best32. ;	
informat IL_1beta best32. ;	
informat IL_6 best32. ;	
informat IL_13 best32. ;	
informat OPN best32. ;	
informat TGF_beta1 best32. ;	
informat TNF_alpha best32. ;	
format StudyRef $8. ;	
format study_type $11. ;	
format duration $8. ;	
format species $5. ;	
format strain $8. ;	
format gender $1. ;	
format route $2. ;	
format chemical $5. ;	
format code $6. ;	
format charac $9. ;	
format size_nm $10. ;	
format dose_ug_mouse best12. ;	
format description $7. ;	
format timepoint_m best12. ;	
format prot_mg_L best12. ;	
format LDH_U_L best12. ;	
format totcc best12. ;	
format macro__ best12. ;	
format neutro__ best12. ;	
format eos__ best12. ;	
format lympho__ best12. ;	
format SS best12. ;	
format OH_proline best12. ;	
format IL_1alpha best12. ;	
format IL_1beta best12. ;	
format IL_6 best12. ;	
format IL_13 best12. ;	
format OPN best12. ;	
format TGF_beta1 best12. ;	
format TNF_alpha best12. ;	
input	
StudyRef $	
study_type $	
duration $	
species $	
strain $	
gender $	
route $	
chemical $	
code $	
charac $	
size_nm $	
dose_ug_mouse	
description $	
timepoint_m	
prot_mg_L	
LDH_U_L	
totcc	
macro__	
neutro__	
eos__	
lympho__	
SS	
OH_proline	
IL_1alpha	
IL_1beta	
IL_6	
IL_13	
OPN	
TGF_beta1	
TNF_alpha	
;	
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection	
macro variable */	
run;	
	
data mwcnt_20 (drop=dose_ug_mouse timepoint_m totcc neutro__ macro__ lympho__ eos__ ss ldh_u_l OH_proline);
	set mwcnt_19 (drop=TGF_beta1 OPN prot_mg_L);

	if dose_ug_mouse=. then delete;

	dose_amount=dose_ug_mouse;
	dose_unit="ug/mouse";

	pe_d = 60;

	TotCell = totcc ;	/* x 10e4 */
	PMNper = neutro__ / 100;
	PMNcount = PMNper*TotCell;
	AMper = macro__ / 100;
	AMcount = AMper*TotCell;
	Lymphcount = (lympho__ / 100) * TotCell;
	Eosincount = (eos__ /100) * TotCell;

	SampCell = ss;
	SampPMNCount = .;
	SampPMNPer = .;
	SampAMCount = .;
	SampAMPer = .;
	SampLymphCount = .;
	SampEosinCount = .;

	LDH_uL = ldh_u_l;

	hydroxyproline_ug_lung = OH_proline;

	format notes $128.;
	notes="pe_d = 2 months post-exposure";
run;
	
data db16;
	set db15 mwcnt_20 (rename=(size_nm=size_nm2));
run;





data WORK.ZNO_03    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile 'Y:\ENM Categories\NPRA In Vivo\enpra_zno1.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

informat StudyRef $10. ;
informat study_type $5. ;
informat duration $5. ;
informat species $5. ;
informat strain $8. ;
informat gender $1. ;
informat route $2. ;
informat chemical $3. ;
informat code $5. ;
informat charac $6. ;
informat size_nm best32. ;
informat animal_nr $10. ;
informat dose_ug_mouse best32. ;
informat Timepoint_hrs best32. ;
informat prot_mg_L best32. ;
informat LDH_U_L best32. ;
informat totcc_E4_ml best32. ;
informat macro_lung best32. ;
informat neutro_lung best32. ;
informat eos_lung best32. ;
informat lympho_lung best32. ;
informat mono_lung best32. ;
informat SS best32. ;
informat abs_m_E4_ml best32. ;
informat abs_n_E4_ml best32. ;
informat abs_eos_E4_ml best32. ;
informat weight_g best32. ;
informat liver_g best32. ;
informat kidney_g best32. ;
informat spleen_g best32. ;
informat hart_g best32. ;
informat brain_g best32. ;
informat WBC_E9_L best32. ;
informat RBC_E12_L best32. ;
informat Hgb_nmol_L best32. ;
informat Hct_L_L best32. ;
informat MCV_fL best32. ;
informat MCH_fmol best32. ;
informat MCHC_mmol_L $8. ;
informat RDW best32. ;
informat HDW_mmol_L best32. ;
informat Plt_E9_L best32. ;
informat MPV_fL best32. ;
informat MPC best32. ;
informat neutro_b best32. ;
informat lympho_b best32. ;
informat mono_b best32. ;
informat eos_b best32. ;
informat luc_b best32. ;
informat baso_b best32. ;
informat abs_n_b_E9_L best32. ;
informat abs_l_b_E9_L best32. ;
informat abs_mono_b_E9_L best32. ;
informat abs_eos_b_E9_L best32. ;
informat abs_luc_b_E9_L best32. ;
informat abs_baso_b_E9_L best32. ;
informat GSHlung_uM_mgprotein best32. ;
informat Com_T_lu best32. ;
informat ComTL_lu best32. ;
informat Com_T_li best32. ;
informat ComTL_li best32. ;
informat IL1b_pg_ml best32. ;
informat IL4_pg_ml best32. ;
informat IL6_pg_ml best32. ;
informat IL12_pg_ml best32. ;
informat IL13_pg_ml best32. ;
informat GCSF_pg_ml best32. ;
informat KC_pg_ml best32. ;
informat MCP1_pg_ml best32. ;
informat MIP1b_pg_ml best32. ;
informat RANTES_pg_ml best32. ;
informat TNFa_pg_ml best32. ;
informat GSHli_uM_mg best32. ;
format StudyRef $10. ;
format study_type $5. ;
format duration $5. ;
format species $5. ;
format strain $8. ;
format gender $1. ;
format route $2. ;
format chemical $3. ;
format code $5. ;
format charac $6. ;
format size_nm best12. ;
format animal_nr $10. ;
format dose_ug_mouse best12. ;
format Timepoint_hrs best12. ;
format prot_mg_L best12. ;
format LDH_U_L best12. ;
format totcc_E4_ml best12. ;
format macro_lung best12. ;
format neutro_lung best12. ;
format eos_lung best12. ;
format lympho_lung best12. ;
format mono_lung best12. ;
format SS best12. ;
format abs_m_E4_ml best12. ;
format abs_n_E4_ml best12. ;
format abs_eos_E4_ml best12. ;
format weight_g best12. ;
format liver_g best12. ;
format kidney_g best12. ;
format spleen_g best12. ;
format hart_g best12. ;
format brain_g best12. ;
format WBC_E9_L best12. ;
format RBC_E12_L best12. ;
format Hgb_nmol_L best12. ;
format Hct_L_L best12. ;
format MCV_fL best12. ;
format MCH_fmol best12. ;
format MCHC_mmol_L $8. ;
format RDW best12. ;
format HDW_mmol_L best12. ;
format Plt_E9_L best12. ;
format MPV_fL best12. ;
format MPC best12. ;
format neutro_b best12. ;
format lympho_b best12. ;
format mono_b best12. ;
format eos_b best12. ;
format luc_b best12. ;
format baso_b best12. ;
format abs_n_b_E9_L best12. ;
format abs_l_b_E9_L best12. ;
format abs_mono_b_E9_L best12. ;
format abs_eos_b_E9_L best12. ;
format abs_luc_b_E9_L best12. ;
format abs_baso_b_E9_L best12. ;
format GSHlung_uM_mgprotein best12. ;
format Com_T_lu best12. ;
format ComTL_lu best12. ;
format Com_T_li best12. ;
format ComTL_li best12. ;
format IL1b_pg_ml best12. ;
format IL4_pg_ml best12. ;
format IL6_pg_ml best12. ;
format IL12_pg_ml best12. ;
format IL13_pg_ml best12. ;
format GCSF_pg_ml best12. ;
format KC_pg_ml best12. ;
format MCP1_pg_ml best12. ;
format MIP1b_pg_ml best12. ;
format RANTES_pg_ml best12. ;
format TNFa_pg_ml best12. ;
format GSHli_uM_mg best12. ;
input
StudyRef $
study_type $
duration $
species $
strain $
gender $
route $
chemical $
code $
charac $
size_nm
animal_nr $
dose_ug_mouse
Timepoint_hrs
prot_mg_L
LDH_U_L
totcc_E4_ml
macro_lung
neutro_lung
eos_lung
lympho_lung
mono_lung
SS
abs_m_E4_ml
abs_n_E4_ml
abs_eos_E4_ml
weight_g
liver_g
kidney_g
spleen_g
hart_g
brain_g
WBC_E9_L
RBC_E12_L
Hgb_nmol_L
Hct_L_L
MCV_fL
MCH_fmol
MCHC_mmol_L $
RDW
HDW_mmol_L
Plt_E9_L
MPV_fL
MPC
neutro_b
lympho_b
mono_b
eos_b
luc_b
baso_b
abs_n_b_E9_L
abs_l_b_E9_L
abs_mono_b_E9_L
abs_eos_b_E9_L
abs_luc_b_E9_L
abs_baso_b_E9_L
GSHlung_uM_mgprotein
Com_T_lu
ComTL_lu
Com_T_li
ComTL_li
IL1b_pg_ml
IL4_pg_ml
IL6_pg_ml
IL12_pg_ml
IL13_pg_ml
GCSF_pg_ml
KC_pg_ml
MCP1_pg_ml
MIP1b_pg_ml
RANTES_pg_ml
TNFa_pg_ml
GSHli_uM_mg
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection
macro variable */
run;

data zno_04 (drop=animal_nr dose_ug_mouse totcc_e4_ml abs_n_E4_ml abs_m_E4_ml lympho_lung SS abs_eos_E4_ml mono_lung neutro_lung macro_lung
							ldh_u_l eos_lung);

	set zno_03 (drop=liver_g	kidney_g	spleen_g	hart_g	brain_g	WBC_E9_L	RBC_E12_L	Hgb_nmol_L	Hct_L_L	MCV_fL	MCH_fmol	MCHC_mmol_L	RDW	HDW_mmol_L	
			Plt_E9_L	MPV_fL	MPC	neutro_b	lympho_b	mono_b	eos_b	luc_b	baso_b	abs_n_b_E9_L	abs_l_b_E9_L	abs_mono_b_E9_L	abs_eos_b_E9_L	abs_luc_b_E9_L	
			abs_baso_b_E9_L	GSHlung_uM_mgprotein	Com_T_lu	ComTL_lu	Com_T_li	ComTL_li GCSF_pg_ml	
			KC_pg_ml	MCP1_pg_ml	MIP1b_pg_ml	RANTES_pg_ml GSHli_uM_mg
			Timepoint_hrs	prot_mg_L);

	animal_id = animal_nr;
	dose_amount=dose_ug_mouse;
	dose_unit="ug/mouse";

	pe_d = 1;

	TotCell = totcc_e4_ml * 100000;	/* x 10e4 */
	PMNcount = abs_n_E4_ml * 100000;
	PMNper = PMNcount/TotCell;
	AMcount = abs_m_E4_ml * 100000;
	AMper = AMcount/TotCell;
	Lymphcount = (lympho_lung/SS)*TotCell;
	Eosincount = abs_eos_E4_ml * 100000;
	Monocount = (mono_lung/SS)*TotCell;

	SampCell = ss;
	SampPMNCount = neutro_lung;
	SampPMNPer = SampPMNCount/SampCell;
	SampAMCount = macro_lung;
	SampAMPer = SampAMCount/SampCell;
	SampLymphCount = lympho_lung;
	SampEosinCount = eos_lung;
	SampMonoCount = mono_lung;

	LDH_uL = ldh_u_l;

	format notes $128.;
	notes="weight_g = body weight after instillation/weight beforeinstillation*100%";
run;

data db17;
	set db16 zno_04;
run;









data WORK.ZNO_05    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile 'Y:\ENM Categories\NPRA In Vivo\enpra_zno2.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

informat StudyRef $10. ;
informat study_type $5. ;
informat duration $5. ;
informat species $5. ;
informat strain $8. ;
informat gender $1. ;
informat route $2. ;
informat chemical $3. ;
informat code $5. ;
informat charac $6. ;
informat size_nm best32. ;
informat animal_nr $10. ;
informat dose_ug_mouse best32. ;
informat Timepoint_hrs best32. ;
informat prot_mg_L best32. ;
informat LDH_U_L best32. ;
informat totcc_E4_ml best32. ;
informat macro_lung best32. ;
informat neutro_lung best32. ;
informat eos_lung best32. ;
informat lympho_lung best32. ;
informat mono_lung best32. ;
informat SS best32. ;
informat abs_m_E4_ml best32. ;
informat abs_n_E4_ml best32. ;
informat abs_eos_E4_ml best32. ;
informat weight_g best32. ;
informat liver_g best32. ;
informat kidney_g best32. ;
informat spleen_g best32. ;
informat hart_g best32. ;
informat brain_g best32. ;
informat WBC_E9_L best32. ;
informat RBC_E12_L best32. ;
informat Hgb_nmol_L best32. ;
informat Hct_L_L best32. ;
informat MCV_fL best32. ;
informat MCH_fmol best32. ;
informat MCHC_mmol_L $8. ;
informat RDW best32. ;
informat HDW_mmol_L best32. ;
informat Plt_E9_L best32. ;
informat MPV_fL best32. ;
informat MPC best32. ;
informat neutro_b best32. ;
informat lympho_b best32. ;
informat mono_b best32. ;
informat eos_b best32. ;
informat luc_b best32. ;
informat baso_b best32. ;
informat abs_n_b_E9_L best32. ;
informat abs_l_b_E9_L best32. ;
informat abs_mono_b_E9_L best32. ;
informat abs_eos_b_E9_L best32. ;
informat abs_luc_b_E9_L best32. ;
informat abs_baso_b_E9_L best32. ;
informat GSHlung_uM_mgprotein best32. ;
informat Com_T_lu best32. ;
informat ComTL_lu best32. ;
informat Com_T_li best32. ;
informat ComTL_li best32. ;
informat IL1b_pg_ml best32. ;
informat IL4_pg_ml best32. ;
informat IL6_pg_ml best32. ;
informat IL12_pg_ml best32. ;
informat IL13_pg_ml best32. ;
informat GCSF_pg_ml best32. ;
informat KC_pg_ml best32. ;
informat MCP1_pg_ml best32. ;
informat MIP1b_pg_ml best32. ;
informat RANTES_pg_ml best32. ;
informat TNFa_pg_ml best32. ;
informat GSHli_uM_mg best32. ;
format StudyRef $10. ;
format study_type $5. ;
format duration $5. ;
format species $5. ;
format strain $8. ;
format gender $1. ;
format route $2. ;
format chemical $3. ;
format code $5. ;
format charac $6. ;
format size_nm best12. ;
format animal_nr $10. ;
format dose_ug_mouse best12. ;
format Timepoint_hrs best12. ;
format prot_mg_L best12. ;
format LDH_U_L best12. ;
format totcc_E4_ml best12. ;
format macro_lung best12. ;
format neutro_lung best12. ;
format eos_lung best12. ;
format lympho_lung best12. ;
format mono_lung best12. ;
format SS best12. ;
format abs_m_E4_ml best12. ;
format abs_n_E4_ml best12. ;
format abs_eos_E4_ml best12. ;
format weight_g best12. ;
format liver_g best12. ;
format kidney_g best12. ;
format spleen_g best12. ;
format hart_g best12. ;
format brain_g best12. ;
format WBC_E9_L best12. ;
format RBC_E12_L best12. ;
format Hgb_nmol_L best12. ;
format Hct_L_L best12. ;
format MCV_fL best12. ;
format MCH_fmol best12. ;
format MCHC_mmol_L $8. ;
format RDW best12. ;
format HDW_mmol_L best12. ;
format Plt_E9_L best12. ;
format MPV_fL best12. ;
format MPC best12. ;
format neutro_b best12. ;
format lympho_b best12. ;
format mono_b best12. ;
format eos_b best12. ;
format luc_b best12. ;
format baso_b best12. ;
format abs_n_b_E9_L best12. ;
format abs_l_b_E9_L best12. ;
format abs_mono_b_E9_L best12. ;
format abs_eos_b_E9_L best12. ;
format abs_luc_b_E9_L best12. ;
format abs_baso_b_E9_L best12. ;
format GSHlung_uM_mgprotein best12. ;
format Com_T_lu best12. ;
format ComTL_lu best12. ;
format Com_T_li best12. ;
format ComTL_li best12. ;
format IL1b_pg_ml best12. ;
format IL4_pg_ml best12. ;
format IL6_pg_ml best12. ;
format IL12_pg_ml best12. ;
format IL13_pg_ml best12. ;
format GCSF_pg_ml best12. ;
format KC_pg_ml best12. ;
format MCP1_pg_ml best12. ;
format MIP1b_pg_ml best12. ;
format RANTES_pg_ml best12. ;
format TNFa_pg_ml best12. ;
format GSHli_uM_mg best12. ;
input
StudyRef $
study_type $
duration $
species $
strain $
gender $
route $
chemical $
code $
charac $
size_nm
animal_nr $
dose_ug_mouse
Timepoint_hrs
prot_mg_L
LDH_U_L
totcc_E4_ml
macro_lung
neutro_lung
eos_lung
lympho_lung
mono_lung
SS
abs_m_E4_ml
abs_n_E4_ml
abs_eos_E4_ml
weight_g
liver_g
kidney_g
spleen_g
hart_g
brain_g
WBC_E9_L
RBC_E12_L
Hgb_nmol_L
Hct_L_L
MCV_fL
MCH_fmol
MCHC_mmol_L $
RDW
HDW_mmol_L
Plt_E9_L
MPV_fL
MPC
neutro_b
lympho_b
mono_b
eos_b
luc_b
baso_b
abs_n_b_E9_L
abs_l_b_E9_L
abs_mono_b_E9_L
abs_eos_b_E9_L
abs_luc_b_E9_L
abs_baso_b_E9_L
GSHlung_uM_mgprotein
Com_T_lu
ComTL_lu
Com_T_li
ComTL_li
IL1b_pg_ml
IL4_pg_ml
IL6_pg_ml
IL12_pg_ml
IL13_pg_ml
GCSF_pg_ml
KC_pg_ml
MCP1_pg_ml
MIP1b_pg_ml
RANTES_pg_ml
TNFa_pg_ml
GSHli_uM_mg
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection
macro variable */
run;

data zno_06 (drop=animal_nr dose_ug_mouse totcc_e4_ml abs_n_E4_ml abs_m_E4_ml lympho_lung SS abs_eos_E4_ml mono_lung neutro_lung macro_lung
							ldh_u_l eos_lung);

	set zno_05 (drop=liver_g	kidney_g	spleen_g	hart_g	brain_g	WBC_E9_L	RBC_E12_L	Hgb_nmol_L	Hct_L_L	MCV_fL	MCH_fmol	MCHC_mmol_L	RDW	HDW_mmol_L	
			Plt_E9_L	MPV_fL	MPC	neutro_b	lympho_b	mono_b	eos_b	luc_b	baso_b	abs_n_b_E9_L	abs_l_b_E9_L	abs_mono_b_E9_L	abs_eos_b_E9_L	abs_luc_b_E9_L	
			abs_baso_b_E9_L	GSHlung_uM_mgprotein	Com_T_lu	ComTL_lu	Com_T_li	ComTL_li GCSF_pg_ml	
			KC_pg_ml	MCP1_pg_ml	MIP1b_pg_ml	RANTES_pg_ml GSHli_uM_mg
			Timepoint_hrs	prot_mg_L);

	animal_id = animal_nr;
	dose_amount=dose_ug_mouse;
	dose_unit="ug/mouse";

	pe_d = 1;

	TotCell = totcc_e4_ml * 100000;	/* x 10e4 */
	PMNcount = abs_n_E4_ml * 100000;
	PMNper = PMNcount/TotCell;
	AMcount = abs_m_E4_ml * 100000;
	AMper = AMcount/TotCell;
	Lymphcount = (lympho_lung/SS)*TotCell;
	Eosincount = abs_eos_E4_ml * 100000;
	Monocount = (mono_lung/SS)*TotCell;

	SampCell = ss;
	SampPMNCount = neutro_lung;
	SampPMNPer = SampPMNCount/SampCell;
	SampAMCount = macro_lung;
	SampAMPer = SampAMCount/SampCell;
	SampLymphCount = lympho_lung;
	SampEosinCount = eos_lung;
	SampMonoCount = mono_lung;

	LDH_uL = ldh_u_l;

	format notes $128.;
	notes="weight_g = body weight after instillation/weight beforeinstillation*100%";
run;

data db18;
	set db17 zno_06;
run;





	


data WORK.zno_07    ;	
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */	
	infile 'Y:\ENM Categories\NPRA In Vivo\enpra_zno3.csv' delimiter =	',' MISSOVER DSD lrecl=32767 firstobs=2 ;	

informat StudyRef $8. ;	
informat study_type $11. ;	
informat duration $8. ;	
informat species $5. ;	
informat strain $8. ;	
informat gender $1. ;	
informat route $2. ;	
informat chemical $5. ;	
informat code $6. ;	
informat charac $9. ;	
informat size_nm $10. ;	
informat dose_ug_mouse best32. ;	
informat description $7. ;	
informat timepoint_m best32. ;	
informat prot_mg_L best32. ;	
informat LDH_U_L best32. ;	
informat totcc best32. ;	
informat macro__ best32. ;	
informat neutro__ best32. ;	
informat eos__ best32. ;	
informat lympho__ best32. ;	
informat SS best32. ;	
informat OH_proline best32. ;	
informat IL_1alpha best32. ;	
informat IL_1beta best32. ;	
informat IL_6 best32. ;	
informat IL_13 best32. ;	
informat OPN best32. ;	
informat TGF_beta1 best32. ;	
informat TNF_alpha best32. ;	
format StudyRef $8. ;	
format study_type $11. ;	
format duration $8. ;	
format species $5. ;	
format strain $8. ;	
format gender $1. ;	
format route $2. ;	
format chemical $5. ;	
format code $6. ;	
format charac $9. ;	
format size_nm $10. ;	
format dose_ug_mouse best12. ;	
format description $7. ;	
format timepoint_m best12. ;	
format prot_mg_L best12. ;	
format LDH_U_L best12. ;	
format totcc best12. ;	
format macro__ best12. ;	
format neutro__ best12. ;	
format eos__ best12. ;	
format lympho__ best12. ;	
format SS best12. ;	
format OH_proline best12. ;	
format IL_1alpha best12. ;	
format IL_1beta best12. ;	
format IL_6 best12. ;	
format IL_13 best12. ;	
format OPN best12. ;	
format TGF_beta1 best12. ;	
format TNF_alpha best12. ;	
input	
StudyRef $	
study_type $	
duration $	
species $	
strain $	
gender $	
route $	
chemical $	
code $	
charac $	
size_nm $	
dose_ug_mouse	
description $	
timepoint_m	
prot_mg_L	
LDH_U_L	
totcc	
macro__	
neutro__	
eos__	
lympho__	
SS	
OH_proline	
IL_1alpha	
IL_1beta	
IL_6	
IL_13	
OPN	
TGF_beta1	
TNF_alpha	
;	
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection	
macro variable */	
run;	
	
data zno_08 (drop=dose_ug_mouse timepoint_m totcc neutro__ macro__ lympho__ eos__ ss ldh_u_l OH_proline);
	set zno_07 (drop=TGF_beta1 OPN prot_mg_L);

	if dose_ug_mouse=. then delete;

	dose_amount=dose_ug_mouse;
	dose_unit="ug/mouse";

	pe_d = 60;

	TotCell = totcc ;	/* x 10e4 */
	PMNper = neutro__ / 100;
	PMNcount = PMNper*TotCell;
	AMper = macro__ / 100;
	AMcount = AMper*TotCell;
	Lymphcount = (lympho__ / 100) * TotCell;
	Eosincount = (eos__ /100) * TotCell;

	SampCell = ss;
	SampPMNCount = .;
	SampPMNPer = .;
	SampAMCount = .;
	SampAMPer = .;
	SampLymphCount = .;
	SampEosinCount = .;

	LDH_uL = ldh_u_l;

	hydroxyproline_ug_lung = OH_proline;

	format notes $128.;
	notes="pe_d = 2 months post-exposure";
run;
	
data db19;
	set db18 zno_08 (rename=(size_nm=size_nm2));
run;


libname dsk "C:\Users\vom8\Desktop\invivo_db_8may2015";
data dsk.db19;
	set db19;
run;


/*
files <- c("Y:/ENM Categories/EDA/eda macro v1.0 INPUT/bermudez_combined.csv",
           "Y:/ENM Categories/EDA/eda macro v1.0 INPUT/gernand_Carbon_Nanotube_Pulmonary_Toxicity_Data_Set_20120313.csv",
					all 17 NPRA
				Y:\ENM Categories\NPRA In Vivo\enpra_tio21.csv
				Y:\ENM Categories\NPRA In Vivo\enpra_tio22.csv
				Y:\ENM Categories\NPRA In Vivo\enpra_tio23.csv
				Y:\ENM Categories\NPRA In Vivo\enpra_tio24.csv
				Y:\ENM Categories\NPRA In Vivo\enpra_tio25.csv
*/
proc import datafile="" dbms=csv out=;
run;
