/* sampling distributions */

data one;
   do ii=1 to 25;
      x = rand("Normal", 25, 3);
	  output;
   end;
run;

proc means data=one;
   var x;
run;
/* x-bar = 25.2086390
   se = ?
   normal theory says it will be 3/sqrt(25)= 0.6
*/

data temp;
   file print;
   x=3/sqrt(25);
   put x;
run;

proc surveyselect data=one noprint
   out=boot (rename=(replicate=sampleID))
   method=urs
   sampsize=25
   reps=10000
   outhits;
run;

proc summary data=boot nway;
   class sampleid;
   var x;
   output out=summ (drop=_TYPE_ _FREQ_) mean=xbar;
run;

proc univariate data=summ;
   histogram xbar;
run;
/* se=0.5 - just a sanity check, mwcnt corr should be good */
