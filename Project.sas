libname mydata "/home/u63613148/Mixed_Models/Project";

proc glm data=mydata.bmilda;
	run;

 /* ******************************************** */
/* Descriptive explorations */
/* ******************************************** */
proc contents data = mydata.bmilda;
run;

PROC FORMAT;
 VALUE smokingf 1=’Smoker’
 0=’NonSmoker’;
 VALUE sexf 0=’Female’
 1=’Male’;
RUN; 

proc means data=mydata.bmilda;
   var bmi fage;
run;

proc freq data=mydata.bmilda;
   tables sex smoking id;
   format smoking smokingf. sex sexf.;
run;

proc sort data=mydata.bmilda; 
by sex smoking; 

run; 

proc means data=mydata.bmilda;
	var bmi fage;
	by sex smoking;
	format smoking smokingf. sex sexf.;
run;

proc means data=mydata.bmilda;
    class sex smoking time;
    var BMI fage;
    output out=means_summary mean=Mean_BMI std=Std_BMI;
run;

/* ******************************************** */
/* Correlations */
/* ******************************************** */
proc corr data=mydata.bmilda plots=matrix(histogram) plots(maxpoints=none);
   var BMI FAGE smoking sex time;
run;

/* ******************************************** */
/* Graphical exploration */
/* ******************************************** */
/* Means and distributions */
/* lof of different options still looking at what are the best ones */
proc sgplot data=mydata.bmilda;
   histogram bmi / transparency=0.5;
   Density bmi;
   histogram fage / transparency=0.5;
   Density fage; 
   title "Distribution of BMI and Age";
run;

proc sgplot data=mydata.bmilda;
	vbar smoking / group = sex; 
	title "Amount of males and females who are smokers and non-smokers";
	format smoking smokingf. sex sexf.;
run; 

proc sgplot data=mydata.bmilda;
	vbar smoking / response=BMI; 
	title "Total BMI by smoking habits";
	format smoking smokingf. sex sexf.;
run; 

proc sgplot data=mydata.bmilda;
	vbar sex / response=BMI; 
	title "Total BMI by sex";
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

proc sgplot data=means_summary;
	series X = time Y = Mean_BMI;
	title "BMI and Age over time";
	keylegend / title = 'Legend';
run; 
/* still looking how to find legend for this plot */

/* ******************************************** */
/* Exploratory techniques */
/* ******************************************** */

proc anova data=mydata.bmilda plots(maxpoints=none);
  class time;
  model BMI = time ;
run;

/* ******************************************** */
/* First linear mixed model */
/* ******************************************** */
/* Fixed Effect = time; Random Effect = individual variability in baseline BMI levels*/

proc mixed data=mydata.bmilda plots(maxpoints=none);
	class ID;
	model bmi=time / solution;
	random intercept Time / Subject=ID TYPE=UN;
run;

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
/* Sort and format the empirical Bayes estimates 
into wide format */
/* ******************************************** */
proc sort data=mydata.eb out=ebSorted;
	by id;
run;

proc transpose data=ebSorted out=mydata.ebWide prefix=eb;
	by id;
	id Effect;
	Var Estimate;
run;

/* ******************************************** */
/* Histograms of Random Effects */
/* ******************************************** */

proc univariate data=mydata.ebWide;
	var ebintercept;
	histogram ebintercept;
run;

proc univariate data=mydata.ebWide;
	var ebtime;
	histogram ebtime;
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
	scatter x=ebintercept y=ebtime / datalabel=Label;
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
