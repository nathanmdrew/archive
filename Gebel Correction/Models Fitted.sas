/* ...\Particles\Gebel12$Compare Nano-micro\Models Fitted.sas   26sep2014
-----------------------------------------------------------------------------------------------------
Models fitted to .\Data\Gebel_data.sas7bdat

Date	 Model_Labels
25sep14  Preliminary Gebel fit.
26sep14  Bin2Strat11 Bin3Strat11 Bin4Strat11 

   
Notes:  
1. Bin3Strat11 model seems best so far but it has evidence of overdispersion.

----------------------------------------------------------------------------------------------------- */

*Let Proj=\\cdc.gov\private\L604\rjs2\ebackup\_tasks\EDK\Particles\Gebel12$Compare Nano-micro\;
%Let Proj=C:\_tasks\EDK\Particles\Gebel12$Compare Nano-micro\;

libname c "&Proj.Data";

ods html close;
ods listing;
options nocenter LS=160;


%MACRO Gebel_Ests;

title  "Estimates of potency based on unweighted averages.";
title2 "Data used by Gebel should correspond to I_Gebel=1.";
title3 "However, the I_Gebel values are preliminary.";

data controls(rename=(Pr_obs=Pr_obs0)) exposed;
     set c.Gebel_data;
     if Conc=0 then output controls; else output exposed;
run;
data pot;
     set exposed END=EOF; by Study NOTSORTED Sex NOTSORTED ;
     if first.Study OR first.Sex then DO;
        set controls(keep=Pr_obs0);
     END;
     retain Pr_obs0;
     Pot=(Pr_obs-Pr_obs0)/NormDose;
     output;
     if EOF then STOP;
run;
data pot; set pot;
     if _n_ IN (3,6,11,13,14,15,16,19,20)   /* Need to revise list to match the records used by Gebel */
        then I_Gebel=1; else I_Gebel=0;
     label I_Gebel="I(used by Gebel [?])"
           Pot    ="Potency: (Pd-P0)/d  ";
run;
proc summary mean data=pot;
     class I_Gebel Par_type;
     var Pot;
     output out=Gebel_Ests(label="Gebel's estimates if I_Gebel matches Gebel 2012"
                            drop=_TYPE_)
            mean=AvgPot;
run;

proc sort data=Gebel_Ests
          out=c.Gebel_Ests(label="Gebel's estimates if I_Gebel matches Gebel 2012");
      by DESCENDING I_Gebel DESCENDING Par_type; 
run;

proc print data=c.Gebel_Ests label;
     id I_Gebel Par_type;
     var AvgPot _FREQ_;
     label _FREQ_="Sample size";
     format AvgPot 6.3;
run;
        
%MEND Gebel_Ests;
       


%MACRO Binomial_Fits;

title  "Fit of a 2-parameter linear dose-response model stratified by 11 study:sex combinations";
title2 "based on minimizing a criterion proportional to -2log(L|dist=binomial)";
title3 "using data on all of the normalized doses.";

title4 "The effect of dose has two potency parameters, Beta(micro) and Beta(nano) that are independent of gender";

proc nlmixed data=c.Gebel_data  DF=18 Tech=TruReg;
     PARMS    Alpha1_M Alpha1_F 
              Alpha2_F  
              Alpha3_M Alpha3_F 
              Alpha4_FM
              Alpha5_F Alpha6_F Alpha7_F  
              Alpha8_M Alpha8_F
            = 0.0934438583270535                 /* sum(y)/sum(n) = 248/2654                 */
              Beta_Nano  = 0
              Beta_Micro = 0
             ;
     BOUNDS   Beta_Nano    <= 3.856              /* From max(NormDose|Nano) in CB_P90_Hein95 */
            , Beta_Nano    >= 0
            , Beta_Micro   <= 0.972477064220     /* From CB_Elft12_Nik95 male controls       */
            , Beta_Micro   >= 0
            , Alpha1_M Alpha1_F 
              Alpha2_F  
              Alpha3_M Alpha3_F 
              Alpha4_FM
              Alpha5_F Alpha6_F Alpha7_F  
              Alpha8_M Alpha8_F < 1
            , Alpha1_M Alpha1_F 
              Alpha2_F  
              Alpha3_M Alpha3_F 
              Alpha4_FM
              Alpha5_F Alpha6_F Alpha7_F  
              Alpha8_M Alpha8_F > 0;
     
     if Study = "TiO2_Lee85"      then if Sex="m" then Alpha=Alpha1_M; else Alpha=Alpha1_F;
     if Study = "Coal_Mart77"     then Alpha=Alpha2_F;      
     if Study = "Talc_NTP93"      then if Sex="m" then Alpha=Alpha3_M; else Alpha=Alpha3_F; 
     if Study = "Ton_Muhle91"     then Alpha=Alpha4_FM;      
     if Study = "TiO2_P25_Hein95" then Alpha=Alpha5_F;  
     if Study = "CB_P90_Hein94"   then Alpha=Alpha6_F;    
     if Study = "CB_P90_Hein95"   then Alpha=Alpha7_F;    
     if Study = "CB_Elft12_Nik95" then if Sex="m" then Alpha=Alpha8_M; else Alpha=Alpha8_F; 

     if Par_type = "micro" then Beta = Beta_Micro; else Beta = Beta_Nano;

     LP = Alpha + Beta * NormDose;
     Phat  = LP;
     Muhat = N * Phat;

     MODEL   Y ~ binomial(N,Phat);

     Estimate "log(Beta_Nano)"        log(Beta_Nano);
     Estimate "log(Beta_Micro)"       log(Beta_Micro);
     Estimate "log(Relative_Potency)" log(Beta_Nano)-log(Beta_Micro);
     Estimate "Relative_Potency"      Beta_Nano/Beta_Micro ;

     r_P   = (Y-Muhat)/sqrt(Muhat*(1-Phat));              /* Binomial Pearson  residual */
   
     id Phat r_P;
     Predict log(Phat) out=Bin2Strat11_Pred_lnPhat(label="Fit of 2 parameter stratified binomial regression model");

     ods output Parameters=Bin2Strat11_Initvals(label="Fit of 2 parameter stratified binomial regression model");
     ods output IterHistory=Bin2Strat11_IterHist(label="Fit of 2 parameter stratified binomial regression model");
     ods output ParameterEstimates=Bin2Strat11_ParmEsts(label="Fit of 2 parameter stratified binomial regression model");
     ods output AdditionalEstimates=Bin2Strat11_AddlEsts(label="Fit of 2 parameter stratified binomial regression model");
     ods output FitStatistics=Bin2Strat11_FitStats(label="Fit of 2 parameter stratified binomial regression model");
run;



title4 "The model has two slope parameters, Beta(micro,male) and Beta(micro,female) and one relative potency parameter";

Data Parmsdata(label="Based on the 2 parameter stratified binomial regression model");
     length Parameter $12;
     set Bin2Strat11_ParmEsts(keep=Parameter Estimate);
     if Parameter="Beta_Nano"  then DO; Parameter="Theta"; Estimate=5.3175; END;
     if Parameter="Beta_Micro" then DO; Parameter="Beta_Micro_M";  output; Parameter="Beta_Micro_F" ;END;
     output;
run;

proc nlmixed data=c.Gebel_data  DF=17 Tech=TruReg;
     PARMS  /pdata=Parmsdata  ;
     BOUNDS   Beta_Micro_M <= 0.972477064220     /* From CB_Elft12_Nik95 male    controls       */
            , Beta_Micro_F <= 0.9921             /* From TiO2_Lee85      females            */
            , Theta        <  10
            , Alpha1_M Alpha1_F 
              Alpha2_F  
              Alpha3_M Alpha3_F 
              Alpha4_FM
              Alpha5_F Alpha6_F Alpha7_F  
              Alpha8_M Alpha8_F < 1
            , Alpha1_M Alpha1_F 
              Alpha2_F  
              Alpha3_M Alpha3_F 
              Alpha4_FM
              Alpha5_F Alpha6_F Alpha7_F  
              Alpha8_M Alpha8_F > 0;
     
     if Study = "TiO2_Lee85"      then if Sex="m" then Alpha=Alpha1_M; else Alpha=Alpha1_F;
     if Study = "Coal_Mart77"     then Alpha=Alpha2_F;      
     if Study = "Talc_NTP93"      then if Sex="m" then Alpha=Alpha3_M; else Alpha=Alpha3_F; 
     if Study = "Ton_Muhle91"     then Alpha=Alpha4_FM;      
     if Study = "TiO2_P25_Hein95" then Alpha=Alpha5_F;  
     if Study = "CB_P90_Hein94"   then Alpha=Alpha6_F;    
     if Study = "CB_P90_Hein95"   then Alpha=Alpha7_F;    
     if Study = "CB_Elft12_Nik95" then if Sex="m" then Alpha=Alpha8_M; else Alpha=Alpha8_F; 

     if Sex="m"   then Beta_Micro=Beta_Micro_M;
     if Sex="f"   then Beta_Micro=Beta_Micro_F;
     if Sex="f/m" then Beta_Micro=(Beta_Micro_M+Beta_Micro_F)/2;
  
     if Par_type="micro" then LP = Alpha + Beta_Micro * NormDose;
     if Par_type="nano"  then LP = Alpha + Theta * Beta_Micro * NormDose;
     
     Phat  = LP;
     Muhat = N * Phat;

     MODEL   Y ~ binomial(N,Phat);

     Estimate "log(Beta_Micro_M)"     log(Beta_Micro_M);
     Estimate "log(Beta_Micro_F)"     log(Beta_Micro_F);
     Estimate "log(Beta_MF_ratio)"    log(Beta_Micro_M)-log(Beta_Micro_F);
     Estimate "log(Relative_Potency)" log(Theta);
     Estimate "Relative_Potency"      Theta ;

     r_P   = (Y-Muhat)/sqrt(Muhat*(1-Phat));              /* Binomial Pearson  residual */
   
     id Phat r_P;
     Predict log(Phat) out=Bin3Strat11_Pred_lnPhat(label="Fit of 3 parameter stratified binomial regression model");

     ods output Parameters=Bin3Strat11_Initvals(label="Fit of 3 parameter stratified binomial regression model");
     ods output IterHistory=Bin3Strat11_IterHist(label="Fit of 3 parameter stratified binomial regression model");
     ods output ParameterEstimates=Bin3Strat11_ParmEsts(label="Fit of 3 parameter stratified binomial regression model");
     ods output AdditionalEstimates=Bin3Strat11_AddlEsts(label="Fit of 3 parameter stratified binomial regression model");
     ods output FitStatistics=Bin3Strat11_FitStats(label="Fit of 3 parameter stratified binomial regression model");
run;



title4 "The model has two slope parameters, Beta(micro,male) and Beta(micro,female) and two relative potency parameters";

Data Parmsdata(label="Based on the 3 parameter stratified binomial regression model");
     length Parameter $12;
     set Bin3Strat11_ParmEsts(keep=Parameter Estimate);
     if Parameter="Theta"  then DO; Parameter="Theta_M"; output; Parameter="Theta_F"; END;
     output;
run;

proc nlmixed data=c.Gebel_data  DF=16 Tech=TruReg;
     PARMS  /pdata=Parmsdata  ;
     BOUNDS   Beta_Micro_M <= 0.972477064220     /* From CB_Elft12_Nik95 male    controls       */
            , Beta_Micro_F <= 0.9921             /* From TiO2_Lee85      females            */
            , Theta_M Theta_F    <  10
            , Alpha1_M Alpha1_F 
              Alpha2_F  
              Alpha3_M Alpha3_F 
              Alpha4_FM
              Alpha5_F Alpha6_F Alpha7_F  
              Alpha8_M Alpha8_F < 1
            , Alpha1_M Alpha1_F 
              Alpha2_F  
              Alpha3_M Alpha3_F 
              Alpha4_FM
              Alpha5_F Alpha6_F Alpha7_F  
              Alpha8_M Alpha8_F > 0;
     
     if Study = "TiO2_Lee85"      then if Sex="m" then Alpha=Alpha1_M; else Alpha=Alpha1_F;
     if Study = "Coal_Mart77"     then Alpha=Alpha2_F;      
     if Study = "Talc_NTP93"      then if Sex="m" then Alpha=Alpha3_M; else Alpha=Alpha3_F; 
     if Study = "Ton_Muhle91"     then Alpha=Alpha4_FM;      
     if Study = "TiO2_P25_Hein95" then Alpha=Alpha5_F;  
     if Study = "CB_P90_Hein94"   then Alpha=Alpha6_F;    
     if Study = "CB_P90_Hein95"   then Alpha=Alpha7_F;    
     if Study = "CB_Elft12_Nik95" then if Sex="m" then Alpha=Alpha8_M; else Alpha=Alpha8_F; 

     if Sex="m"   then DO; Beta_Micro=Beta_Micro_M;                  Theta=Theta_M;             END;
     if Sex="f"   then DO; Beta_Micro=Beta_Micro_F;                  Theta=Theta_F;             END;
     if Sex="f/m" then DO; Beta_Micro=(Beta_Micro_M+Beta_Micro_F)/2; Theta=(Theta_M+Theta_F)/2; END;
  
     if Par_type="micro" then LP = Alpha + Beta_Micro * NormDose;
     if Par_type="nano"  then LP = Alpha + Theta * Beta_Micro * NormDose;
     
     Phat  = LP;
     Muhat = N * Phat;

     MODEL   Y ~ binomial(N,Phat);

     Estimate "log(Beta_Micro_M)"     log(Beta_Micro_M);
     Estimate "log(Beta_Micro_F)"     log(Beta_Micro_F);
     Estimate "log(Beta_MF_ratio)"    log(Beta_Micro_M)-log(Beta_Micro_F);
     Estimate "log(Rel_Potency_M)"    log(Theta_M);
     Estimate "log(Rel_Potency_F)"    log(Theta_F);
     Estimate "log(Rel_PotRatio_MF)"  log(Theta_M)-log(Theta_F);
     Estimate "Rel_Potency_M"         Theta_M ;
     Estimate "Rel_Potency_F"         Theta_F ;

     r_P   = (Y-Muhat)/sqrt(Muhat*(1-Phat));              /* Binomial Pearson  residual */
   
     id Phat r_P;
     Predict log(Phat) out=Bin4Strat11_Pred_lnPhat(label="Fit of 3 parameter stratified binomial regression model");

     ods output Parameters=Bin4Strat11_Initvals(label="Fit of 3 parameter stratified binomial regression model");
     ods output IterHistory=Bin4Strat11_IterHist(label="Fit of 3 parameter stratified binomial regression model");
     ods output ParameterEstimates=Bin4Strat11_ParmEsts(label="Fit of 3 parameter stratified binomial regression model");
     ods output AdditionalEstimates=Bin4Strat11_AddlEsts(label="Fit of 3 parameter stratified binomial regression model");
     ods output FitStatistics=Bin4Strat11_FitStats(label="Fit of 3 parameter stratified binomial regression model");
run;







/*-------------------------------------------------------------------+
 |  -2logL(data|binomial model[i])                                   |
 +-------------------------------------------------------------------*/



title4 "Pearson residuals of Model_Label=Bin2Strat11";
proc univariate plot data=Bin2Strat11_Pred_lnPhat;
     var r_P;
run; /* O.D. parameter Phi = 93.5300655/18 = 5.196115    USS of Pearson residuals is the numerator */


title4 "Pearson residuals of Model_Label=Bin3Strat11";
proc univariate plot data=Bin3Strat11_Pred_lnPhat;
     var r_P;
run; /* O.D. parameter Phi = 74.7582956/17 = 4.397547 */


title4 "Pearson residuals of Model_Label=Bin4Strat11";
proc univariate plot data=Bin4Strat11_Pred_lnPhat;
     var r_P;
run; /* O.D. parameter Phi = 70.4751064/16 = 4.404694 */


Data Binomial_2logL(Label="-2logL values of binomial models fitted to Gebel data on all doses"
                    rename=(Value=Neg2logL));
     Length Descr $24 Model_Label $16;
     One=1;
     Model_Label="Bin2Strat11"; set Bin2Strat11_FitStats POINT=One; Sc_Neg2logL = Value/4.397547; Phi=5.196115;  output;
     Model_Label="Bin3Strat11"; set Bin3Strat11_FitStats POINT=One; Sc_Neg2logL = Value/4.397547; Phi=4.397547;  output; 
     Model_Label="Bin4Strat11"; set Bin4Strat11_FitStats POINT=One; Sc_Neg2logL = Value/4.397547; Phi=4.404694;  output;
     
     format Value  Sc_Neg2logL 9.4;
      
     label Value            = "Binomial model -2logL"
           Phi              = "Overdispersion parameter=USS(r_Pearson)"
           Sc_Neg2logL      = "-2logL/4.397547";
STOP;
run;

proc copy out=c in=work;
     select Bin:;
run;


%MEND Binomial_Fits;


