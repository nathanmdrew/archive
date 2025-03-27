PROC IMPORT OUT= WORK.pchem1 
            DATAFILE= "Y:\ENM Categories\DB\physiochemical list v2.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="Physiochemical$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;
