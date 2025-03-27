PROC IMPORT OUT= WORK.D01 
            DATAFILE= "C:\Users\vom8\Documents\Gebel Correction Project 
2014-09\Data\Data Reformatted.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="Database$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;
