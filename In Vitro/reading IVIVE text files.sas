/* ENPRA has some in vitro data in the IVIVE files
   these are tab delimited text files
   data comes from/exported to/not sure an excel file, which links to the individual data files
   could be used to QC data
*/

data test;
	infile 'Z:\MyLargeWorkspace Backup\IOM Data\EileenK-2015-02-18\WP6_Analysis\IVIVE\WP4 sheets\NM111_P9.txt' 
		dlm='09'x firstobs=5;
	input Dose $ MHS_Cytotox_LDH $ MHS_Cell_viability $ LA4_Cytotox_LDH $ LA4_Cell_viability $ time $ MHS_TNF $
		  LA4_TNF $ MHS_IL1b $ LA4_IL1b $ MHS_IL4 $ LA4_IL4 $ MHS_IL6 $ LA4_IL6 $ MHS_IL12 $ LA4_IL12 $ MHS_IL13 $ 
		  LA4_IL13 $ MHS_GCSF $ LA4_GCSF $ MHS_KC $ LA4_KC $ MHS_MCP1 $ LA4_MCP1 $ MHS_MIP1a $ LA4_MIP1a $ 
		  MHS_RANTES $ LA4_RANTES $;
run;

data test2;
	set test;
	keep Dose time MHS_IL1b LA4_IL1b;
run;
