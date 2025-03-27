/*///////////////////////////////////////////////
///  import files
/*/


/*//////////////////////////////////////////////
///		Use this code for the FINAL reports
///      Assumes datasets already exist
/*/
/*libname f "\\cdc.gov\private\L606\vom8\Fall STA 261 H D\Final Grades";*/
/*data hw1;*/
/*	set f.mystatlab;*/
/*run;*/
/*data qq1;*/
/*	set f.qq;*/
/*run;*/
/*data quiz1;*/
/*	set f.quiz;*/
/*run;*/
/*proc import datafile="\\cdc.gov\private\L606\vom8\Fall STA 261 H D\Final Grades\exams_final.csv" out=ex1 dbms=csv;*/
/*run;*/

/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/


/* qq roster hw exam */

%let gradebookdir = "C:\Users\vom8\Desktop\Gradebook_STA261HD_Fall2015.xlsx";

/*   MyStatLab Assignments */
proc import datafile=&gradebookdir. out=hw1 dbms=excel; sheet=HW;
run;

data hw2;
	set hw1 (drop=f15 f16);
	tot_hw = 13+12+36+4+5+9+11+12+6+12+7+6+8;
	hw_sum = (hw1_13 + hw2_12 + hw3_36 + hw4_4 + hw5_5 + hw6_9 + hw8_11 + hw9_12 + hw10_6 + hw11_12 + hw12_7 + hw13_6 + hw14_8);

	/* correct HW scores for late joiners */
	if name="Chen, Yue" then do;
		tot_hw=tot_hw-13-12-26-4;
		hw_sum=hw_sum + (99*4);
	end;
	if name="Baumgartner, Joseph" then do;
		tot_hw=tot_hw-13-12-36-4-5-9;
		hw_sum=hw_sum + (99*6);
	end;
	if name="Whelpton, John" then do;
		tot_hw=tot_hw-13;
		hw_sum=hw_sum+99;
	end;

	label tot_hw   = "Total Possible HW Points"
		  hw_sum   = "Total Obtained HW Points"
          hw1_13 = "HW1 (13 Points)"
		  hw2_12 = "HW2 (12 Points)"
		  hw3_36 = "HW3 (36 Points)"
		  hw4_4  = "HW4 ( 4 Points)"
		  hw5_5  = "HW5 ( 5 Points)"
		  hw6_9  = "HW6 ( 9 Points)"
		  hw8_11 = "HW8 (11 Points)"
		  hw9_12 = "HW9 (12 Points)"
		  hw10_6 = "HW10 (6 Points)"
		  hw11_12 = "HW11 (12 Points)"
		  hw12_7 = "HW12 (7 Points)"
		  hw13_6 = "HW13 (6 Points)"
		  hw14_8 = "HW14 (8 Points)"
			;
run;

/*   QQ Assignments */
proc import datafile=&gradebookdir. out=qq1 dbms=excel; sheet=QQ;
run;

/*   Exams */
proc import datafile=&gradebookdir. out=ex1 dbms=excel; sheet=Exam;
run;
data ex2;
	set ex1 (keep=name exam1 exam1curve exam2 exam2curve);
run;

/*   Quizzes */
proc import datafile=&gradebookdir. out=quiz1 dbms=excel; sheet=Quizzes;
run;

data quiz2;
	set quiz1;

	if quiz_oct8=. then quiz_oct8=0;
	if quiz_oct22=. then quiz_oct22=0;

run;


/*   Roster */
proc import datafile=&gradebookdir. out=roster1 dbms=excel; sheet=Roster;
run;



/*/////////////////////////////////////////////////
/// combine, dedupe, change point values as needed
/*/

proc sort data=roster1;  by name;  run;
proc sort data=hw2;  by name;  run;
proc sort data=ex2;  by name;  run;

data all1 (drop=drop added participation);
	merge roster1 (in=aa) hw2 (in=bb) ex2 (in=cc);
	by name;

	if drop=1 then delete;

	*if exam1=. then exam1=0;
	*if exam1curve=. then exam1curve=0;
run;


%macro qqsplit;
	/* change QQ # accordingly */
	%do ii=1 %to 16;
		data _qq&ii.;
			set qq1 (keep=qq&ii.);
			score_qq&ii. = 1;
			if qq&ii.="" then delete;
			rename qq&ii.=email;
		run;
		proc sort data=_qq&ii.; by email; run;
	%end;
%mend;
%qqsplit;
			 
data qq_all;
	merge _qq1
		  _qq2
		  _qq3
		  _qq4
		  _qq5
		  _qq6
		  _qq7
		  _qq8
		  _qq9
		  _qq10
		  _qq11
		  _qq12
		  _qq13
		  _qq14
		  _qq15
		  _qq16;
	by email;

	* everyone gets qq1 credit while working out bugs ;
	if score_qq1 ne 1 then score_qq1=1;
run;

* some duplicates;
proc summary data=qq_all nway missing;
	by email;
	var score_qq1
	    score_qq2
		score_qq3
		score_qq4
		score_qq5
		score_qq6
		score_qq7
		score_qq8
		score_qq9
		score_qq10
		score_qq11
		score_qq12
		score_qq13
		score_qq14
		score_qq15
		score_qq16;
	output out=qq_all2 (drop=_type_ _freq_) max()=;
run;

proc sort data=quiz2; by email; run; 
proc sort data=all1; by email; run; 
proc sort data=qq_all2; by email; run; 

data all2 (drop=score_qq7);
	merge all1 (in=aa) qq_all2 quiz2;
	by email;
	if aa;

	if score_qq1=. then score_qq1=0;
	if score_qq2=. then score_qq2=0;
	if score_qq3=. then score_qq3=0;
	if score_qq4=. then score_qq4=0;
	if score_qq5=. then score_qq5=0;
	if score_qq6=. then score_qq6=0;
	if score_qq7=. then score_qq7=0;
	if score_qq8=. then score_qq8=0;
	if score_qq9=. then score_qq9=0;
	if score_qq10=. then score_qq10=0;
	if score_qq11=. then score_qq11=0;
	if score_qq12=. then score_qq12=0;
	if score_qq13=. then score_qq13=0;
	if score_qq14=. then score_qq14=0;
	if score_qq15=. then score_qq15=0;
	if score_qq16=. then score_qq16=0;
	*if score_qq17=. then score_qq17=0;
	*if score_qq18=. then score_qq18=0;

	qq_total=3*15; *qq7 not counted;
	sum_qq=3*(score_qq1+score_qq2+score_qq3+score_qq4+score_qq5+score_qq6+score_qq8+score_qq9+score_qq10+score_qq11+score_qq12+
			  score_qq13+score_qq14+score_qq15+score_qq16);

	exam_total=200;
	quiz_total=6;

	total_potential = exam_total + qq_total + tot_hw + quiz_total;
	total_obtained = exam1curve + exam2curve + sum_qq + hw_sum + quiz_oct8 + quiz_oct22;

	if name="Baumgartner, Joseph" then do;
       total_obtained=total_obtained+99; *correct missing Exam1;
	   total_potential = total_potential-100;
	   qq_total=qq_total - 3*7;
	   total_potential=total_potential - 3*7;
	end;
	if name="Chen, Yue" then do;
		qq_total=qq_total - 3*4;
		total_potential = total_potential - 3*4;
	end;

		c=total_obtained/total_potential*100;
		if c >= 97 then letter="A+";
		else if c> 93 then letter="A";
		else if c>= 90 then letter="A-";
		else if c >= 87 then letter="B+";
		else if c > 83 then letter="B";
		else if c >= 80 then letter="B-";
		else if c >= 77 then letter="C+";
		else if c > 73 then letter="C";
		else if c >= 70 then letter="C-";
		else if c >= 67 then letter="D+";
		else if c > 63 then letter="D";
		else if c >= 60 then letter="D-";
		else letter="F";
run;

data qc;
	set all2;
	keep name c letter total_potential total_obtained qq_total sum_qq exam1curve tot_hw hw_sum quiz_oct8;
run;

data all3 (keep = _a _b a b c letter d d2 e f g h i j k l m n o o2 o3 o4 o5 o6 o7 p q r s t u v w w2 w3 w4 w5 w6 w7 w8 x1 x2);
   set all2;

	_a=email;
	_b=name;
	a=total_potential;
	b=total_obtained;
	c=total_obtained/total_potential*100;
		if c >= 97 then letter="A+";
		else if c> 93 then letter="A";
		else if c>= 90 then letter="A-";
		else if c >= 87 then letter="B+";
		else if c > 83 then letter="B";
		else if c >= 80 then letter="B-";
		else if c >= 77 then letter="C+";
		else if c > 73 then letter="C";
		else if c >= 70 then letter="C-";
		else if c >= 67 then letter="D+";
		else if c > 63 then letter="D";
		else if c >= 60 then letter="D-";
		else letter="F";
	d=exam1curve;
	d2=exam2curve;
	e=tot_hw;
	f=hw_sum;
	g=qq_total;
	h=sum_qq;

    i=hw1_13;
	j=hw2_12;
	k=hw3_36;
	l=hw4_4;
	m=hw5_5;
	n=hw6_9;
	o=hw8_11;
	o2=hw9_12;
	o3=hw10_6;
	o4=hw11_12;
	o5=hw12_7;
	o6=hw13_6;
	o7=hw14_8;

	p=score_qq1*3;
	q=score_qq2*3;
	r=score_qq3*3;
	s=score_qq4*3;
	t=score_qq5*3;
	u=score_qq6*3;
	v=score_qq8*3;
	w=score_qq9*3;
	w2=score_qq10*3;
	w3=score_qq11*3;
	w4=score_qq12*3;
	w5=score_qq13*3;
	w6=score_qq14*3;
	w7=score_qq15*3;
	w8=score_qq16*3;

	x1=quiz_oct8;
	x2=quiz_oct22;

	label _a="Email"
	      _b="Name"
			a="Total Possible Points"
			b="Total Obtained Points"
			c="Current Percentage"
			letter="Letter Grade"
			d="Exam 1 (Curved)"
			d2="Exam 2 (Curved)"

			e="Total Possible HW Points"
			f="Total Obtained HW Points"
			g="Total Possible QQ Points"
			h="Total Obtained QQ Points"

			i = "HW1 (13 Points)"
			j = "HW2 (12 Points)"
			k = "HW3 (36 Points)"
			l  = "HW4 ( 4 Points)"
			m  = "HW5 ( 5 Points)"
			n  = "HW6 ( 9 Points)"
			o = "HW8 (11 Points)"
			o2 = "HW9 (12 Points)"
			o3 = "HW10 (6 Points)"
			o4 = "HW11 (12 Points)"
			o5 = "HW12 (7 Points)"
			o6 = "HW13 (6 Points)"
			o7 = "HW14 (8 Points)"

			p="QQ1"
			q="QQ2"
			r="QQ3"
			s="QQ4"
			t="QQ5"
			u="QQ6"
			v="QQ8"
			w="QQ9"
			w2="QQ10"
			w3="QQ11"
			w4="QQ12"
			w5="QQ13"
			w6="QQ14"
			w7="QQ15"
			w8="QQ16"

			x1="Quiz (Oct 8th)"
			x2="Quiz (Oct 22nd)"
			;
run;

* make reports ;
%let outf = Z:\MyLargeWorkspace Backup\MUH\Fall 2015 STA 261 HD\Grade Reports;

%macro report;

   %do ii=1 %to 26;
   		data report;
			set all3 (firstobs=&ii obs=&ii);
			call symput('name', compress(_b));
		run;
		proc export data=report outfile="&outf.\Grade Report 03NOV2015 &name..xlsx" dbms=excel LABEL REPLACE; 
		run;
   %end;
%mend report;

%report;

libname save "Z:\MyLargeWorkspace Backup\MUH\Fall 2015 STA 261 HD\SAS";
data save.grades_03nov2015;
	set all3;
run;


/*
proc sort data=quiz2;	by email;	run;
data all2_2;
	merge all2 quiz2;
	by email;
run;
*/

data all3 (keep=ind_Dropped last_name first_name email hw_total qq_total quiz_total exam_total);
	set all2_2;

	* ad hoc grade adjustments ;
	if last_name="Bruno" then exam2=final;
	if last_name="Cunningham" then _hw22=0;
	if last_name="Gudorf" then exam2=final;
	if last_name="Rahe" then _hw22=2;
	if last_name="Tolson" then _hw22=2;

   final2 = final*2;

	hw_total=sum(_hw1,_hw2,_hw3,_hw4,_hw5,_hw6,_hw8,_hw9,_hw11,_hw12,_hw13,_hw14,_hw15,_hw16,_hw17,_hw18,_hw19,_hw20,_hw21,_hw22);  * 22 assignments ;
	qq_total=3*sum(score_qq1,score_qq2,score_qq3,score_qq4,score_qq5,score_qq6,score_qq7,score_qq8,score_qq9,score_qq10,score_qq11,score_qq12,score_qq13,score_qq14,score_qq15,score_qq16,score_qq17,score_qq18); *18 qqs ;
	quiz_total=sum(_quiz1,_quiz2,_quiz3,_quiz4);  * 4 quizzes ;
	exam_total=sum(exam1, exam2, exam3, final2);  * 3 exams + final ;
run;

data all3_2;
	set all3;
	if last_name="Angst" then participation=30;
	if last_name="Becraft" then participation=40;
	if last_name="Bothwell" then participation=35;
	if last_name="Bruno" then participation=30;
	if last_name="Cox" then participation=40;
	if last_name="Cunningham" then participation=40;
	if last_name="Dodd" then participation=40;
	if last_name="Dunsmore" then participation=40;
	if last_name="Groene" then participation=35;
	if last_name="Gudorf" then participation=20;
	if last_name="Henry" then participation=35;
	if last_name="Huang" then participation=30;
	if last_name="Hughley" then participation=40;
	if last_name="Hunt" then participation=40;
	if last_name="Kaiser" then participation=35;
	if last_name="Leishman" then participation=40;
	if last_name="Meineke" then participation=40;
	if last_name="Meng" then participation=30;
	if last_name="Mitchell" then participation=30;
	if last_name="Ondrula" then participation=15;
	if last_name="Rahe" then participation=40;
	if last_name="Renner" then participation=40;
	if last_name="Schlake" then participation=35;
	if last_name="Smith" then participation=40;
	if last_name="North" then participation=10;
	if last_name="Tolson" then participation=35;
run;

data all4;
	set all3_2;
	if ind_dropped=0;

	*current total possible points;
	*hw:  1100%   (100% x 11) ;
	*qq:  1300%   (100% x 13) ;
	*participation: 40pts or 100% for everyone;
	*exam1:  100%;
	*max of 2600%;



/*	participation=100;*/
/*	total_percent = sum(hw_total*100, qq_total*100, exam_total, participation);*/
/*	grade=total_percent/2600*100;*/
/*	if grade >= 90 then letter="A";*/
/*	else if grade >= 80 then letter="B";*/
/*	else if grade >= 70 then letter="C";*/
/*	else if grade >= 60 then letter="D";*/
/*	else letter="F";*/

	* max HW: 212 ;
	* max QQ: 54 ;
	* max Quiz: 13 ;
	* max exams: 300 ;

	

	hw_qq_total=sum(hw_total, qq_total, quiz_total)*(160/279);   *rescale hw,qq,quiz to be out of 160;
	total_pts=sum(hw_qq_total, exam_total, participation);

	*hw_potential=212;
	*qq_potential=54;
	*exam_potential=100;
	total_potential=700;

	grade=total_pts/total_potential*100;
	if grade >= 90 then letter="A";
	else if grade >= 80 then letter="B";
	else if grade >= 70 then letter="C";
	else if grade >= 60 then letter="D";
	else letter="F";

	format letter2 $2.;
	if grade > 97 then letter2="A+";
	else if grade >= 93 and grade <= 97 then letter2="A";
	else if grade >=90 and grade < 93 then letter2="A-";

	else if grade > 87  and grade < 90 then letter2="B+";
	else if grade >= 83 and grade <= 87 then letter2="B";
	else if grade >=80 and grade < 83 then letter2="B-";

	else if grade > 77  and grade < 80 then letter2="C+";
	else if grade >= 73 and grade <= 77 then letter2="C";
	else if grade >=70 and grade < 73 then letter2="C-";

	else if grade > 67  and grade < 70 then letter2="D+";
	else if grade >= 63 and grade <= 67 then letter2="D";
	else if grade >=60 and grade < 63 then letter2="D-";

	else letter2="F";

run;



/* clean up */
data all5;
	set all4;

	drop hw_1 hw_2 hw3 hw_4 hw_5 hw_6 hw_8 
	     hw_9 hw_11 hw_12 hw_13 hw_14 hw_15 hw_16 
		 hw_17 hw_18 hw_19 hw_20 hw_21 hw_22
         ind_dropped 
		 score_qq1 score_qq2 score_qq3 score_qq4 score_qq5 
		 score_qq6 score_qq7 score_qq8 score_qq9 score_qq10 
		 score_qq11 score_qq12 score_qq13 score_qq14 score_qq15 
		 score_qq16 score_qq17 score_qq18 
		 quiz1 quiz2 quiz3 quiz4
		 total_potential;

   label last_name="Last Name"
   		 first_name="First Name"
		 _hw1="HW1 - 34 Points"
   		 _hw2="HW2 -  7 Points"
		 _hw3="HW3 - 30 Points"
		 _hw4="HW4 -  4 Points"
		 _hw5="HW5 -  5 Points"
		 _hw6="HW6 -  9 Points"
		 _hw8="HW8 - 12 Points"
		 _hw9="HW9 - 14 Points"

		 _hw11="HW11 -  6 Points"
		 _hw12="HW12 - 12 Points"
		 _hw13="HW13 -  7 Points"
		 _hw14="HW14 -  6 Points"
		 _hw15="HW15 -  8 Points"
		 _hw16="HW16 -  8 Points"
		 _hw17="HW17 - 10 Points"
		 _hw18="HW18 - 11 Points"
		 _hw19="HW19 -  8 Points"
		 _hw20="HW20 -  8 Points"
		 _hw21="HW21 -  7 Points"
		 _hw22="HW22 -  6 Points"

		 exam1="Exam 1 - 100 Points"
		 exam2="Exam 2 - 100 Points"
		 exam3="Exam 3 - 100 Points"

		 _quiz1="Quiz 1 - 5 Points"
		 _quiz2="Quiz 2 - 3 Points"
		 _quiz3="Quiz 3 - 3 Points"
		 _quiz4="Quiz 4 - 2 Points"

		 hw_total="HW Total - 212 Points"
		 qq_total="QQ Total -  54 Points"
		 quiz_total="Quiz Total - 13 Points"
		 exam_total="Exam Total - 300 Points"

		 hw_qq_total="Scaled HW/QQ/Quiz Total - 160 Points"
		 total_pts="Total Points - Excluding Participation and Final Exam"
		 grade="Grade (%)"
		 letter="Letter Grade (No +/-)";
run; 



/*proc summary data=all4 nway missing;*/
/*	class letter;*/
/*	var grade;*/
/*	output out=summary (Drop=_type_ _freq_) n()=;*/
/*run;*/
/**/
/*proc sort data=all4;  by letter; run;*/


libname save "C:\Users\Nathan M. Drew\Dropbox\Teaching\Fall 2014 - STA 261 Miami Hamilton\Final Grade Summary";

data save.final;
	set all4;
run;

data save.final_formatted;
	set all5;
run;

data save.mystatlab;
	set hw1;
run;

data save.qq;
	set qq1;
run;

data save.exam;
	set ex1;
run;

data save.quiz;
	set quiz1;
run;
