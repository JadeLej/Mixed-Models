libname mydata '/home/u63630988/sasuser.v94';


/* ******************************************** */
/* ***** Dataset information & formatting ***** */
/* ******************************************** */
proc contents data = mydata.bmilda;
run;

PROC FORMAT;
 VALUE smokingf 1=’Smoker’
 0=’NonSmoker’;
 VALUE sexf 0=’Female’
 1=’Male’;
RUN; 

/* ******************************************** */
/* ******* Data Explorations and plots ******** */
/* ******************************************** */

/* **amount of males/fales and smokers/nonsmokers** */
proc sgplot data=mydata.bmilda;
	vbar smoking / group = sex; 
	title "Amount of males and females who are smokers and non-smokers";
	format smoking smokingf. sex sexf.;
run; 

proc freq data=mydata.bmilda;
   tables sex smoking id;
   title "Amount of males and females and smokers/nonsmokers";
   format smoking smokingf. sex sexf.;
run;

/* **amount of repeated observations in the dataset** */
proc freq data=mydata.bmilda;
   tables id / out=obs_counts(keep=id count rename=(count=num_observations));
run;

proc freq data=obs_counts;
   tables num_observations / out=obs_summary(rename=(num_observations=frequency));
run;

/* **mean fage and BMI** */
proc means data=mydata.bmilda;
   var bmi fage;
run;

proc sgplot data=mydata.bmilda;
   histogram bmi / transparency=0.5;
   Density bmi;
   histogram fage / transparency=0.5;
   Density fage; 
   title "Distribution of BMI and Age";
run;

/* **mean fage and BMI for male/females smokers/non-smokers** */
proc sort data=mydata.bmilda; 
by sex smoking; 
run; 

proc means data=mydata.bmilda;
	var bmi fage;
	by sex smoking;
	format smoking smokingf. sex sexf.;
run;

proc sgplot data=means_summary;
    vbar sex / response=Mean_BMI; 
        title 'Mean BMI by Sex';
        format smoking smokingf. sex sexf.;
run;

proc sgplot data=means_summary;
    vbar smoking / response=Mean_BMI;
    title 'Mean BMI by mean smoking habits';
    format smoking smokingf. sex sexf.;
run;

/* **mean fage and BMI for male/females (non)-smokers per repeated observation** */
proc means data=mydata.bmilda;
    class sex smoking time;
    var BMI fage;
    output out=means_summary mean=Mean_BMI std=Std_BMI;
run;

/* Creation of subsample for each level */
data subsample;
    set means_summary(where=(_type_=7));
run;

/* Subsample and plot for smoking = 0 and sex = 0 */
data subsample_smoking0_sex0;
    set subsample(where=(smoking=0 and sex=0));
run;

proc sgplot data=subsample_smoking0_sex0;
    title 'Mean BMI Over Time for Nonsmoking Females';
    series x=time y=mean_bmi / lineattrs=(thickness=2);
    xaxis label='Time' labelattrs=(size=12);
    yaxis label='Mean BMI' labelattrs=(size=12);
  	yaxis label='Mean BMI' labelattrs=(size=12) values=(20 to 30 by 5) min=20 max=30 grid;
    xaxis grid;
run;

/* Subsample for smoking = 0 and sex = 1 */
data subsample_smoking0_sex1;
    set subsample(where=(smoking=0 and sex=1));
run;

proc sgplot data=subsample_smoking0_sex1;
    title 'Mean BMI Over Time for Nonsmoking Males';
    series x=time y=mean_bmi / lineattrs=(thickness=2);
    xaxis label='Time' labelattrs=(size=12);
    yaxis label='Mean BMI' labelattrs=(size=12);
  	yaxis label='Mean BMI' labelattrs=(size=12) values=(20 to 30 by 5) min=20 max=30 grid;
    xaxis grid;
run;

/* Subsample for smoking = 1 and sex = 0 */
data subsample_smoking1_sex0;
    set subsample(where=(smoking=1 and sex=0));
run;

proc sgplot data=subsample_smoking1_sex0;
    title 'Mean BMI Over Time for Smoking Females';
    series x=time y=mean_bmi / lineattrs=(thickness=2);
    xaxis label='Time' labelattrs=(size=12);
    yaxis label='Mean BMI' labelattrs=(size=12);
  	yaxis label='Mean BMI' labelattrs=(size=12) values=(20 to 30 by 5) min=20 max=30 grid;
    xaxis grid;
run;

/* Subsample for smoking = 1 and sex = 1 */
data subsample_smoking1_sex1;
    set subsample(where=(smoking=1 and sex=1));
run;

proc sgplot data=subsample_smoking1_sex1;
    title 'Mean BMI Over Time for Smoking Males';
    series x=time y=mean_bmi / lineattrs=(thickness=2);
    xaxis label='Time' labelattrs=(size=12);
    yaxis label='Mean BMI' labelattrs=(size=12) values=(20 to 30 by 5) min=20 max=30 grid;
    xaxis grid;
run;

/* **with graphical exploration of BMI over time for first 25 patients** */
proc sgplot data=mydata.bmilda;
	title 'BMI over time of 25 subjects ';
    where ID <= 25;
    series x=time y=BMI / group=ID curvelabel lineattrs=(thickness=1 pattern=dash) ;
    loess x=time y=BMI / curvelabel='Loess curve' markerattrs=(size=0) lineattrs=(thickness=3 pattern=solid) ;
    yaxis min=0 grid;
    xaxis grid;
run;

/* ******************************************** */
/* ********* Exploratory Correlations ********* */
/* ******************************************** */

/* **Correlations entire dataset** */
proc corr data=mydata.bmilda plots=matrix(histogram) plots(maxpoints=none);
   var BMI FAGE smoking sex time;
run;

/* **Correlations random sample of dataset, with n=100** */
proc surveyselect data=mydata.bmilda out=random_subset method=srs sampsize=100;
run;

proc corr data=random_subset plots=matrix(histogram) plots(maxpoints=none);
   var BMI FAGE smoking sex time;
run;

/* ******************************************** */
/* ****** Further Exploratory techniques ****** */
/* ******************************************** */

proc anova data=mydata.bmilda plots(maxpoints=none);
  class time;
  model BMI = time ;
run;

/* ******************************************** */
/* ********* First linear mixed model ********* */
/* ******************************************** */
/* Fixed Effect = time; Random Effect = individual variability in baseline BMI levels*/

ods graphics on / discretemax=4500; 
proc mixed data=mydata.bmilda plots(maxpoints=none)=all;
    class ID;
    model bmi=time / solution;
    random intercept Time / Subject=ID TYPE=UN;
run;
ods graphics off; 

/* ******************************************** */
/* Estimating the Random Effects */
/* Empirical Bayes Estimates saved in file eb */
/* ******************************************** */
ods exclude all;
proc mixed data=mydata.bmilda plots(maxpoints=none);
	class ID;
	model bmi=time / solution;
	random intercept Time / Subject=ID TYPE=UN solution;
	ods output solutionr=mydata.eb;
run;
ods exclude none;

/* ******************************************** */
/* Format Emprical Bayes' Estimates so that other
covariates are included for further analysis*/
/* ******************************************** */
proc sort data=mydata.eb out=ebSorted;
	by id;
run;

proc sort data=mydata.bmilda out = bmisorted;
	by id;
run; 

/*Create new variable if a subject every smoked. 
Equal to 1 if they smoked in half or more of 
observations */
proc sql;
create table bmisorted as
select *, round(avg(smoking)) as smoked
from bmisorted
group by id;
quit;

/*Merge the two tables */
data join;
	merge ebsorted
	bmisorted;
	by id;
run;

proc sort data=join nodupkey;
	by id estimate;
run;

proc sort data = join;
	by id sex;
run;


proc transpose data=join out=mydata.ebWide prefix=eb;
	by id sex smoked;
	id Effect;
	Var Estimate;
run;

/* ******************************************** */
/* Histograms of Random Effects */
/* ******************************************** */

proc format;
value sexFmt
0 = "Female"
1 = "Male"
;

proc format;
value smokerFmt
0 = "NonSmoker"
1 = "Smoker"
;


/* Regular Histograms intercepts and slopes */

proc univariate data=mydata.ebWide;
format sex sexFmt.;
format smoked smokerFmt.;
	var ebintercept;
	id sex smoked;
	histogram ebintercept / odstitle = "EB Estimates for Intercepts" nohlabel vaxislabel="Proportion";
run;


proc univariate data=mydata.ebWide;
format sex sexFmt.;
format smoked smokerFmt.;
	var ebtime;
	id sex smoked;
	histogram ebtime / odstitle = "EB Estimates for Slopes" nohlabel vaxislabel="Proportion";
run;

/*Random effects split by gender for intercepts*/
proc univariate data=mydata.ebWide;
format sex sexFmt.;
format smoked smokerFmt.;
	class sex;
	var ebintercept;
	id id;
	histogram ebintercept / odstitle = "Intercepts by Gender" nohlabel vaxislabel="Proportion";
run;

proc sgplot data=mydata.ebWide;
format sex sexFmt.;
	histogram ebintercept / group=sex transparency=0.5;
	density ebintercept / group=sex;
	xaxis display=(nolabel);
	title "Intercept Estimates by Gender";
	refline 0 / axis = x lineattrs=(thickness=1 color=black pattern = dash);
run;

/*Random effects split by gender for slopes*/
proc univariate data=mydata.ebWide;
format sex sexFmt.;
	class sex;
	var ebtime;
	id id;
	histogram ebtime / odstitle = "Slopes by Gender" nohlabel vaxislabel="Proportion";
run;

proc sgplot data=mydata.ebWide;
format sex sexFmt.;
	histogram ebtime / group=sex transparency=0.5;
	density ebtime / group=sex;
	xaxis display=(nolabel);
	title "Slope Estimates by Gender";
	refline 0 / axis = x lineattrs=(thickness=1 color=black pattern = dash);
run;


/*Random effects split by smoking status for intercepts:*/
proc univariate data=mydata.ebWide;
format smoked smokerFmt.;
	class smoked;
	var ebintercept;
	id id;
	histogram ebintercept / odstitle = "Intercepts by Smoking Status" nohlabel vaxislabel="Proportion";
run;

proc sgplot data=mydata.ebWide;
format smoked smokerFmt.;
	where smoked is not missing;
	histogram ebintercept / group=smoked transparency=0.5;
	density ebintercept / group=smoked;
	title "Intercept Estimates by Smoking Status";
	refline 0 / axis = x lineattrs=(thickness=1 color=black pattern = dash);
run;


/*Random effects split by smoking status for slopes:*/
proc univariate data=mydata.ebWide;
format smoked smokerFmt.;
	class smoked;
	var ebtime;
	id id;
	histogram ebtime / odstitle = "Slopes by Smoking Status" nohlabel vaxislabel="Proportion";
run;

proc sgplot data=mydata.ebWide;
format smoked smokerFmt.;
	where smoked is not missing;
	histogram ebtime / group=smoked transparency=0.5;
	density ebtime / group=smoked;
	title "Intercept Estimates by Smoking Status";
	refline 0 / axis = x lineattrs=(thickness=1 color=black pattern = dash);
	xaxis min = -0.5 max=0.5;
run;


/* ******************************************** */
/* Scatterplots of Random Effects */
/* ******************************************** */
proc sgplot data=mydata.ebWide;
	scatter x=ebintercept y=ebtime / datalabel=id;
run;

/*Create Label Variable to Identify Outliers */
data mydata.ebWide;
set mydata.ebwide;
Label = id;
if id not in ("4844","344","1332","4113") then
	Label = " ";
run;

proc sgplot data=mydata.ebWide;
	scatter x=ebintercept y=ebtime / 
	markerattrs=(symbol=CircleFilled size=5)
	datalabel=Label;
	xaxis label = "Intercept";
	yaxis label = "Slope";
run;


/*Add in color coding for gender */
proc sgplot data=mydata.ebWide;
format sex sexFmt.;
	scatter x=ebintercept y=ebtime / 
	markerattrs=(symbol=CircleFilled size=5)
	group=sex
	datalabel=Label;
	xaxis label = "Intercept";
	yaxis label = "Slope";
run;


/* Add in color coding for smoking status */
proc sgplot data=mydata.ebWide;
format smoked smokerFmt.;
	where smoked is not missing;
	scatter x=ebintercept y=ebtime / 
	markerattrs=(symbol=CircleFilled size=5)
	group=smoked
	datalabel=Label;
	xaxis label = "Intercept";
	yaxis label = "Slope";
run;



/* Curve of BMI over time per patient */
OPTIONS NONOTES NOSTIMER NOSOURCE NOSYNTAXCHECK;

PROC SGPLOT data=mydata.bmilda;
  where ID <= 50;

  series x=time y=bmi / group=ID curvelabel;
  loess x=time y=bmi / curvelabel='Loess curve' markerattrs=(size=0);
  yaxis min=0 grid;
  xaxis grid;
RUN;

/* Loess curve of bmi over time */
OPTIONS NONOTES NOSTIMER NOSOURCE NOSYNTAXCHECK;

PROC SGPLOT data=mydata.bmilda;
  loess x=time y=bmi / curvelabel='Loess curve' markerattrs=(size=0);
  yaxis min=0 grid;
  xaxis grid;
RUN;

/*                           Basic model                                     */
/*---------------------------------------------------------------------------*/
/*Test1*/
proc mixed data=mydata.bmilda plots(MAXPOINTS=15000);
	class ID;
	model bmi=time / solution;
	random intercept / type=un subject=ID g gcorr v vcorr;
run;
/* time^2 and time^3 are not significant. This is coherent with the loess curve */


/*                           Model with covariates fages and sex             */
/*---------------------------------------------------------------------------*/

/*Test 2*/
proc mixed data=mydata.bmilda plots(MAXPOINTS=15000);
	class ID;
	model bmi=time sex fage fage*sex/ solution;
	random intercept / type=un subject=ID g gcorr v vcorr;
run;
/* fage*sex is not significant and sex is at the threshold */

/*Test 3*/
/*interaction fage and sex*/
proc mixed data=mydata.bmilda plots(MAXPOINTS=15000);
	class ID;
	model bmi=time FAGE*SEX/ solution;
	random intercept / type=un subject=ID g gcorr v vcorr;
run;
/* time and fage*sex are significant */

/*Test 4 */

proc mixed data=mydata.bmilda plots(MAXPOINTS=15000);
	class SEX;
	model BMI=TIME fage FAGE*SEX / solution;
	random intercept / type=un subject=ID g gcorr v vcorr;
run;	
/* all covariates are significant */

/* Test 5 */
proc mixed data=mydata.bmilda plots(MAXPOINTS=15000);
	class SEX;
	model BMI=TIME sex FAGE*SEX / solution;
	random intercept / type=un subject=ID g gcorr v vcorr;
run;
/* sex is not significant */
/* Test 6 */
proc mixed data=mydata.bmilda plots(MAXPOINTS=15000);
	class SEX;
	model BMI=TIME sex FAGE / solution;
	random intercept / type=un subject=ID g gcorr v vcorr;
run;

/* All covariates are significant */


/* ******************************************** 
Question 5: Does the evolution of BMI depend
on the gender and the age of the subject at the
start of the study??
******************************************** */

/*To analyze this we create a model with interactions.
We are looking for time by age or time by sex interaction*/

proc mixed data=mydata.bmilda plots(MAXPOINTS = 15000);
	class ID;
	model bmi=time fage time*fage sex time*sex smoking/ solution;
	random intercept / type=un subject=ID g gcorr v vcorr;
run;

/* both interactions are significant */


