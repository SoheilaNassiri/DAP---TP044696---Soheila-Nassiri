/*************** Initial Data Entry ***************/
Proc import out= WORK
datafile= '/home/nassirisoheila0/Initial_Data_DAP.xls'
dbms= xls replace;
getnames= yes;
namerow=5;
datarow=6;
endrow=525;
endcol=O;
run;

/****************** Renaming Columns ****************/
data work1;
set work;
Rename C=YEAR
VAR4= POPULATION
VAR5= VIOLENT_CRIME
VAR7= Rape_revised
VAR8= Rape_legacy
VAR10=Agg_Assault
VAR11= Prop_crime
VAR13= Larceny
VAR14=Mveh_theft
VAR15=Arson;
run;

proc print data=work1;
run;

/***************** missing values checking ****************/
proc means data=work1 nmiss;
run;
/***************** frequency check to identify areas of missing values **********/
proc freq data=work1;
tables _CHAR_ / missing missprint nocum nopercent;
tables _numeric_ / missing missprint nocum nopercent;
run;

/*********************** Replacing missing values ***********************/
proc stdize data=work1 out=work2
            missing=mean reponly;
            var VIOLENT_CRIME
                Murder
                Rape_revised
                Robbery
                Agg_Assault
                Prop_crime
                Burglary
                Larceny
                Mveh_theft
                Arson;
                run;
                
proc print data=work2;
run;


/***********checking for missing values after first impute***********/
proc means data=work2 nmiss;
run;
/************************ Replacing population by using 2017 percentage increase ********************/
data work3;
set work2;
retain 
	s_population
 	s_state
 	s_city;
If not missing (population) 
then s_population=round(population+(Population*0.080));
else population=s_population;

If not missing (state) 
then s_state=state;
else state=s_state;

If not missing (city) 
then s_city=city;
else city=s_city;
drop
s_population
s_state
s_city;
run;
/******************** checking missing values after population replacement *********************/
proc means data=work3 nmiss;
run;
/******************** rounding values *************************/
data rounded_work;
set work3;
violent_crime=round(violent_crime,1);
Murder=round(murder,1);
Rape_revised=round(rape_revised,1);
Robbery=round(robbery,1);
Agg_Assault=round(agg_assault,1);
Prop_crime=round(prop_crime,1);
Burglary=round(burglary,1);
Larceny=round(larceny,1);
Mveh_theft=round(Mveh_theft,1);
Arson=round(arson,1);
/********************** finalized pre-processing **************************/
data final_preprocessed;
set rounded_work;
drop 
rape_legacy;
run;
/*********************************** Objective processing and visualization**************************************/
data summed_data;
set final_preprocessed;
total_theft=sum( Robbery, Agg_Assault, Prop_crime, Burglary, Larceny, Mveh_theft, Arson);
drop murder rape_revised Robbery Agg_Assault Prop_crime Burglary Larceny Mveh_theft Arson;
run;
/******************** sorting data based on total_theft and Violent_crime**************************/
proc sort data=summed_data out=sorted_data;
by descending violent_crime descending total_theft;
run;
proc print data=sorted_data;
var state city year violent_crime total_theft;
run;
/***********************************Visualization 1*****************************************/
ods graphics / reset imagemap;
proc sgplot data=WORK.SORTED_DATA;
title "Total theft and violent crime grouped by state";
scatter x=State y=VIOLENT_CRIME / group=total_theft 
markerattrs=(symbol=Circle) transparency=0.0 name='Scatter';
xaxis grid;
yaxis grid;
run;

ods graphics / reset;
title;

/************************************Visualization 2****************************************/
ods graphics / reset width=10in height=4.8in imagemap;
proc sgplot data=SORTED_DATA;
title H=15pt "Total theft and violent crimes grouped by year";
vbox total_theft / category=VIOLENT_CRIME group=YEAR grouporder=descending 
name='Box';
xaxis fitpolicy=splitrotate label="Violent crime" discreteorder=data;
yaxis label="Total theft" grid;
run;
ods graphics / reset;
title;

/***********************************Visualization 3*****************************************/
ods graphics / reset width=10in height=10in imagemap;
proc sgplot data=SORTED_DATA;
title H=15pt "Cities and violent crimes grouped by total theft";
hbar City / response=VIOLENT_CRIME group=total_theft groupdisplay=Cluster 
datalabel stat=Mean dataskin=Gloss;
xaxis grid label="Violent Crime";
run;
ods graphics / reset;
title;



