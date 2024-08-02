/*libname mydata '/home/u63630988/sasuser.v94'; */
libname mydata '/home/u63610451/Mixed_models/';

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

proc sort data=mydata.bmilda out=sorted;
    by id time;
run;

data ID_once;
    set sorted;
    by id time;
    if first.ID then output;
run;


/* ******************************************** */
/* ******* Data Explorations and plots ******** */
/* ******************************************** */
/* **amount of males/fales and smokers/nonsmokers** */
proc sgplot data=ID_once;
	vbar smoking / group = sex datalabel datalabelattrs=(size=10) datalabelpos=top;; 
	title "Amount of males and females who are smokers and non-smokers";
	format smoking smokingf. sex sexf.;
run; 

proc freq data=ID_once;
   tables sex smoking smoking*sex;
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
   title "Mean BMI and Age for all observations";
run;
proc means data=ID_once;
   var bmi fage;
   title "Mean BMI and Age for all individuals at baseline";
run;

proc sgplot data=mydata.bmilda;
   histogram bmi / transparency=0.5;
   Density bmi;
   histogram fage / transparency=0.5;
   Density fage; 
   title "Distribution of BMI and Age for all observations";
run;

proc sgplot data=ID_once;
   histogram bmi / transparency=0.5;
   Density bmi;
   histogram fage / transparency=0.5;
   Density fage; 
   title "Distribution of BMI and Age at baseline";
run;

/* **mean fage and BMI for male/females smokers/non-smokers** */
proc sort data=ID_once; 
by sex smoking; 
run; 

proc means data=ID_once;
	var bmi fage;
	by sex smoking;
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

/* Loess curve of bmi over time */
ODS GRAPHICS ON / LOESSMAXOBS=15000;
PROC SGPLOT data=mydata.bmilda;
  loess x=time y=bmi / curvelabel='Loess curve' markerattrs=(size=0);
  yaxis min=0 grid;
  xaxis grid;
RUN;

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
    store out = curve1;
run;

proc PLM restore=curve1;
	effectplot fit(x=time) / predlabel= 'Fitted values for BMI' yrange=(15,35);
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

/* ******************************************** */
/* Model2 with covariates fages and sex 
/* ******************************************** */


proc mixed data=mydata.bmilda plots(maxpoints=none);
	class ID;
	model bmi=time SEX FAGE / solution;
	random intercept Time / Subject=ID TYPE=UN g gcorr v vcorr solution;
	store out = curve2;
	ods output solutionr=mydata.sol2;
run;

proc PLM restore=curve2;
	effectplot fit(x=time) / predlabel= 'Fitted values for BMI' yrange=(15,35);
run;

proc transpose data=mydata.sol2(keep= ID Effect Estimate)
	out= mydata.sol2(rename=(COL1=Intercept COL2=time) drop=_NAME_);
by ID;
run;
proc univariate data=mydata.sol2 noprint;
histogram intercept time ;
run;





/* *******************************************************/
/* Model3 with covariates fages and sex and Interactions
/* *******************************************************/

proc mixed data=mydata.bmilda plots(maxpoints=none);
	class ID;
	model bmi=time SEX FAGE SEX*FAGE SEX*TIME TIME*FAGE / solution;
	random intercept Time / Subject=ID TYPE=UN g gcorr v vcorr solution;
	store out = curve3;
	ods output solutionr=mydata.sol3;
run;

proc PLM restore=curve3;
	effectplot fit(x=time) / predlabel= 'Fitted values for BMI' yrange=(15,35);
run;

proc transpose data=mydata.sol3(keep= ID Effect Estimate)
	out= mydata.sol3(rename=(COL1=Intercept COL2=time) drop=_NAME_);
by ID;
run;
proc univariate data=mydata.sol3 noprint;
histogram intercept time ;
run;

/* *******************************************************/
/* Models with covariates fages and sex and Interactions 
/* the role of SEX Model4, model5 and model6 */
/* *******************************************************/


proc mixed data=mydata.bmilda plots(maxpoints=none);
	class ID;
	model bmi=time FAGE SEX*FAGE TIME*FAGE / solution;
	random intercept Time / Subject=ID TYPE=UN g gcorr v vcorr solution;
	store out = curve4;
	ods output solutionr=mydata.sol4;
run;

proc PLM restore=curve4;
	effectplot fit(x=time) / predlabel= 'Fitted values for BMI' yrange=(15,35);
run;

proc transpose data=mydata.sol4(keep= ID Effect Estimate)
	out= mydata.sol4(rename=(COL1=Intercept COL2=time) drop=_NAME_);
by ID;
run;
proc univariate data=mydata.sol4 noprint;
histogram intercept time ;
run;

/*-----------------------------------------------------*/
proc mixed data=mydata.bmilda plots(maxpoints=none);
	class ID;
	model bmi=time FAGE SEX*TIME TIME*FAGE / solution;
	random intercept Time / Subject=ID TYPE=UN g gcorr v vcorr solution;
	store out = curve5;
	ods output solutionr=mydata.sol5;
run;

proc PLM restore=curve5;
	effectplot fit(x=time) / predlabel= 'Fitted values for BMI' yrange=(15,35);
run;

proc transpose data=mydata.sol5(keep= ID Effect Estimate)
	out= mydata.sol5(rename=(COL1=Intercept COL2=time) drop=_NAME_);
by ID;
run;
proc univariate data=mydata.sol5 noprint;
histogram intercept time ;
run;

/*-----------------------------------------------------*/
proc mixed data=mydata.bmilda plots(maxpoints=none);
	class ID;
	model bmi=time FAGE SEX TIME*FAGE / solution;
	random intercept Time / Subject=ID TYPE=UN g gcorr v vcorr solution;
	store out = curve6;
	ods output solutionr=mydata.sol6;
run;

proc PLM restore=curve6;
	effectplot fit(x=time) / predlabel= 'Fitted values for BMI' yrange=(15,35);
run;

proc transpose data=mydata.sol6(keep= ID Effect Estimate)
	out= mydata.sol6(rename=(COL1=Intercept COL2=time) drop=_NAME_);
by ID;
run;
proc univariate data=mydata.sol6 noprint;
histogram intercept time ;
run;


/* *******************************************************/
/* Models with covariates fage, sex and SMOKING 
/* the role of SMOKING Model7*/
/* *******************************************************/


proc mixed data=mydata.bmilda plots(maxpoints=none);
	class ID;
	model bmi=time FAGE SEX SMOKING / solution;
	random intercept Time / Subject=ID TYPE=UN g gcorr v vcorr solution;
	store out = curve7;
	ods output solutionr=mydata.sol7;
run;

proc PLM restore=curve7;
	effectplot fit(x=time) / predlabel= 'Fitted values for BMI' yrange=(15,35);
run;

proc transpose data=mydata.sol7(keep= ID Effect Estimate)
	out= mydata.sol7(rename=(COL1=Intercept COL2=time) drop=_NAME_);
by ID;
run;
proc univariate data=mydata.sol7 noprint;
histogram intercept time ;
run;
/* *******************************************************/
/* SMOKING and Interactions */
/* the role of SMOKING Model8, model9, model10 and model11 */
/* *******************************************************/
proc mixed data=mydata.bmilda plots(maxpoints=none);
	class ID;
	model bmi=time FAGE SEX SMOKING SMOKING*time SMOKING*FAGE SMOKING*SEX / solution;
	random intercept Time / Subject=ID TYPE=UN g gcorr v vcorr solution;
	store out = curve8;
	ods output solutionr=mydata.sol8;
run;

proc PLM restore=curve8;
	effectplot fit(x=time) / predlabel= 'Fitted values for BMI' yrange=(15,35);
run;

proc transpose data=mydata.sol8(keep= ID Effect Estimate)
	out= mydata.sol8(rename=(COL1=Intercept COL2=time) drop=_NAME_);
by ID;
run;
proc univariate data=mydata.sol8 noprint;
histogram intercept time ;
run;

/*------------------------------------------------------------*/
proc mixed data=mydata.bmilda plots(maxpoints=none);
	class ID;
	model bmi=time FAGE SEX SMOKING*time / solution;
	random intercept Time / Subject=ID TYPE=UN g gcorr v vcorr solution;
	store out = curve9;
	ods output solutionr=mydata.sol9;
run;

proc PLM restore=curve9;
	effectplot fit(x=time) / predlabel= 'Fitted values for BMI' yrange=(15,35);
run;

proc transpose data=mydata.sol9(keep= ID Effect Estimate)
	out= mydata.sol9(rename=(COL1=Intercept COL2=time) drop=_NAME_);
by ID;
run;
proc univariate data=mydata.sol9 noprint;
histogram intercept time ;
run;
/*------------------------------------------------------------*/
proc mixed data=mydata.bmilda plots(maxpoints=none);
	class ID;
	model bmi=time FAGE SEX SMOKING*FAGE / solution;
	random intercept Time / Subject=ID TYPE=UN g gcorr v vcorr solution;
	store out = curve10;
	ods output solutionr=mydata.sol10;
run;

proc PLM restore=curve10;
	effectplot fit(x=time) / predlabel= 'Fitted values for BMI' yrange=(15,35);
run;

proc transpose data=mydata.sol10(keep= ID Effect Estimate)
	out= mydata.sol10(rename=(COL1=Intercept COL2=time) drop=_NAME_);
by ID;
run;
proc univariate data=mydata.sol10 noprint;
histogram intercept time ;
run;

/*------------------------------------------------------------*/
proc mixed data=mydata.bmilda plots(maxpoints=none);
	class ID;
	model bmi=time FAGE SEX SMOKING*SEX / solution;
	random intercept Time / Subject=ID TYPE=UN g gcorr v vcorr solution;
	store out = curve11;
	ods output solutionr=mydata.sol11;
run;

proc PLM restore=curve11;
	effectplot fit(x=time) / predlabel= 'Fitted values for BMI' yrange=(15,35);
run;

proc transpose data=mydata.sol11(keep= ID Effect Estimate)
	out= mydata.sol11(rename=(COL1=Intercept COL2=time) drop=_NAME_);
by ID;
run;
proc univariate data=mydata.sol11 noprint;
histogram intercept time ;
run;

/**********************************************************************************************


/* ******************************************** 
Question 5: Does the evolution of BMI depend
on the gender and the age of the subject at the
start of the study??
******************************************** */

/*need a new variable = age at start of study*/

proc sort data=mydata.bmilda;
	by id time;
run;

data bmiZero;
	set mydata.bmilda;
	by id time;
	if first.id then
		ageZero = FAGE-time;
		retain ageZero;
run;



/*To analyze this we create a model with interactions.
We are looking for time by age or time by sex interaction
Store the model to use with proc plm*/

proc mixed data=mydata.bmilda plots(MAXPOINTS = 15000);
	class ID;
	model bmi=time FAGE sex smoking time*FAGE time*sex / solution;
	random intercept time / type=un subject=ID g gcorr v vcorr;
	store test;
run;

/* both interactions are significant */


/* Make plots of effects of interactions at different levels*/ 
proc plm source=test;
effectplot contour (x=time y=FAGE);
run;

proc plm source=test;
effectplot fit (x=time) / at(FAGE = 20 40 60 80);
run;

proc plm restore=test;
effectplot slicefit (x=time sliceby=FAGE plotby=sex=0 1) / clm;
run;


proc plm restore=test;
effectplot slicefit (x=time sliceby=sex=(0 1)) / clm;
run;

/**********************************************************************************************


/* ******************************************** 
Question 7. Fit a logistic mixed model for BMI over time, and interpret results, including random effect estimates.
Compare with the original outcome.
******************************************** */

/* Dichotomise BMI */
data bmi_dicho;
    set mydata.bmilda;
	if BMI > 18.5 and BMI < 24.9 then
		BMI_D = 0;
	else
		BMI_D = 1;
run;


/* logistic mixed model */
proc glimmix data=bmi_dicho;
	class id;
	model BMI_D (event='1') = time FAGE SEX SMOKING SMOKING*time sex*time FAGE*time / dist=binary solution;
	random intercept Time /Subject=ID TYPE=UN solution;
	estimate 'difference slopes sex over time' sex*time 1 -1;
	estimate 'difference slopes fage over time' fage*time 1 -1;
	estimate 'difference slopes smoking over time' smoking*time 1 -1;
	ods output solutionr=mydata.logit_eb;
	nloptions maxiter=30;
run;

/* parse random effects */

data logiteb_sorted;
    set mydata.logit_eb;
    id = input(scan(Subject, 2, ' '), 8.);
run;

proc sort data=logiteb_sorted out=logiteb_sorted;
	by id;
run;

proc sort data=mydata.bmilda out = bmisorted;
	by id;
run; 

proc sql;
	create table bmisorted as
	select *, round(avg(smoking)) as smoked
	from bmisorted where time = 0;
	group by id;
quit;

data logiteb_joined;
	merge logiteb_sorted
	bmisorted;
	by id;
run;

proc sort data=logiteb_joined nodupkey;
	by id estimate;
run;

proc sort data = logiteb_joined;
	by id sex bmi;
run;


proc transpose data=logiteb_joined out=mydata.logiteb_parsed prefix=eb;
	by id sex smoked bmi;
	id Effect;
	Var Estimate;
run;

/* Plot random effects */

proc univariate data=mydata.logiteb_parsed;
format sex sexFmt.;
format smoked smokerFmt.;
	var ebintercept;
	id sex smoked;
	histogram ebintercept / odstitle = "logistic model - EB Estimates for Intercepts" nohlabel vaxislabel="Proportion";
run;


proc univariate data=mydata.logiteb_parsed;
format sex sexFmt.;
format smoked smokerFmt.;
	var ebtime;
	id sex smoked;
	histogram ebtime / odstitle = "logistic model - EB Estimates for Slopes" nohlabel vaxislabel="Proportion";
run;

/* plot random effects per smoking status */
proc sgplot data=mydata.logiteb_parsed;
format smoked smokerFmt.;
	where smoked is not missing;
	histogram ebintercept / group=smoked transparency=0.5;
	title "logistic model - Intercept Estimates by Smoking Status";
	refline 0 / axis = x lineattrs=(thickness=1 color=black pattern = dash);
run;


proc sgplot data=mydata.logiteb_parsed;
format smoked smokerFmt.;
	where smoked is not missing;
	histogram ebtime / group=smoked transparency=0.5;
	xaxis display=(nolabel);
	title "logistic model - Slope Estimates by Smoking Status";
	refline 0 / axis = x lineattrs=(thickness=1 color=black pattern = dash);
run;

/* plot random effects per sex */
proc sgplot data=mydata.logiteb_parsed;
format sex sexFmt.;
	histogram ebintercept / group=sex transparency=0.5;
	title "logistic model - Intercept Estimates by Sex";
	refline 0 / axis = x lineattrs=(thickness=1 color=black pattern = dash);
run;

proc sgplot data=mydata.logiteb_parsed;
format sex sexFmt.;
	histogram ebtime / group=sex transparency=0.5;
	xaxis display=(nolabel);
	title "logistic model - Slope Estimates by Sex";
	refline 0 / axis = x lineattrs=(thickness=1 color=black pattern = dash);
run;

proc sgplot data=mydata.logiteb_parsed;
	scatter x=bmi y=ebtime / datalabel=id;
run;

/* ************************************************************************************* */
/* Marginalization */
/* ************************************************************************************* */

/* Logistic mixed model with interaction */
proc glimmix data=bmi_dicho;
	class id;
	model BMI_D (event='1') = time FAGE SEX SMOKING SMOKING*time sex*time FAGE*time / dist=binary solution;
	random intercept Time /Subject=ID TYPE=UN solution;
	nloptions maxiter=30;
run;

proc iml;
d={3.0359 0.2712, 0.2712 0.0187};
call eigen(evals, evecs, D);
print "Eigenvalues", evals;
print "Eigenvectors", evecs;
/*Replace small eigenvalues with a small positive number*/
evals=choose(evals >1e-6, evals, 1e-6);
evals=diag(evals);
print "Regularized Eigenvalues", evals;
/*Reconstruct the covariance matrix using regularized eignevalues*/
D_reg = evecs*evals*t(evecs);
l=root(D_reg);
print D_reg; print l;
quit;

/* Marginalizing the logistic mixed model with interaction */
data h;
do id=1 to 1000 by 1;
	b0=rannor(-1);
	b1=rannor(-1);
	ranint=1.7424*b0;
	ranslope=0.15537*b0+0.001*b1;
	do time=0 to 9 by 1;
		do sex=0 to 1 by 1;
			do fage=14 to 69 by 1;
				do smoking=0 to 1 by 1;
					y=exp(-2.9961+ranint+(0.2075+ranslope)*time+0.07314*fage+0.5987*sex-0.3937*smoking-0.03501*time*smoking+0.07136*time*sex-0.00330*time*fage)/
					(1+exp(-2.9961+ranint+(0.2075+ranslope)*time+0.07314*fage+0.5987*sex-0.3937*smoking-0.03501*time*smoking+0.07136*time*sex-0.00330*time*fage));
				output;
				end;
			end;
		end;
	end;
end;
run;

proc sort data=h;
by time;
run;

proc means data=h;
var y;
by time;
output out=out;
run;

dm "dlgprtsetup orient=L nodisplay";
filename fig 'c:/filename.eps';
goptions reset=all interpol=join ftext=swiss device=pslepsfc gsfname=fig gsfmode=replace;
proc gplot data=out;
plot y*time / vaxis=axis2 haxis=axis1;
axis1 label=(height=2 'Time');
axis2 label=(height=2 angle=90 'P(Y=1)');
where _stat_='MEAN';
run;quit;run;

/* by sex */
proc sort data=h;
by time sex;
run;

proc means data=h;
var y;
by time sex;
output out=out;
run;

dm "dlgprtsetup orient=L nodisplay";
filename fig 'c:/filename.eps';
goptions reset=all interpol=join ftext=swiss device=pslepsfc gsfname=fig gsfmode=replace;
proc gplot data=out;
plot y*time=sex;
where _stat_='MEAN';
run;quit;run;

/* by smoking */
proc sort data=h;
by time smoking;
run;

proc means data=h;
var y;
by time smoking;
output out=out;
run;

dm "dlgprtsetup orient=L nodisplay";
filename fig 'c:/filename.eps';
goptions reset=all interpol=join ftext=swiss device=pslepsfc gsfname=fig gsfmode=replace;
proc gplot data=out;
plot y*time=smoking;
where _stat_='MEAN';
run;quit;run;

/* by fage */
proc sort data=h;
by time fage;
run;

proc means data=h;
var y;
by time fage;
output out=out;
run;

dm "dlgprtsetup orient=L nodisplay";
filename fig 'c:/filename.eps';
goptions reset=all interpol=join ftext=swiss device=pslepsfc gsfname=fig gsfmode=replace;
proc gplot data=out;
plot y*time=fage;
where _stat_='MEAN';
run;quit;run;


/*Evolution of average subject*/

data w;
do id=1 to 1000 by 1;
	do time=0 to 9 by 1;
		do sex=0 to 1 by 1;
			do fage=14 to 69 by 1;
				do smoking=0 to 1 by 1;
					y=exp(-2.9961+(0.2075)*time+0.07314*fage+0.5987*sex-0.3937*smoking-0.03501*time*smoking+0.07136*time*sex-0.00330*time*fage)/
					(1+exp(-2.9961+(0.2075)*time+0.07314*fage+0.5987*sex-0.3937*smoking-0.03501*time*smoking+0.07136*time*sex-0.00330*time*fage));
				output;
				end;
			end;
		end;
	end;
end;
run;
proc sort data=w;
by time;
run;

proc means data=w;
var y;
by time;
output out=out;
run;

dm "dlgprtsetup orient=L nodisplay";
filename fig 'c:/filename2.eps';
goptions reset=all interpol=join ftext=swiss device=pslepsfc gsfname=fig gsfmode=replace;
proc gplot data=out;
plot y*time / vaxis=axis2 haxis=axis1;
axis1 label=(height=2 'Time');
axis2 label=(height=2 angle=90 'P(Y=1|b_i=0)');
where _stat_='MEAN';
run;quit;run;

/* *************************************************************************
Improvement Strategies
**************************************************************************** */

/* Suppressing outliers */

data transformed;
	set mydata.bmilda;
	if bmi <= 34;
run;

ods graphics on / discretemax=4500;
proc mixed data=transformed plots(maxpoints=none)=all;
    class id;
    model bmi = time fage sex smoking / solution;
    random intercept time / subject=id type=UN;
run;
ods graphics off;

/* Incorporating outliers with random effects */

ods graphics on / discretemax=4500;

data bmi_dicho2;
    set mydata.bmilda;
	if BMI > 30 then
		BMI_D = 1;
	else
		BMI_D = 0;
run;

proc mixed data=bmi_dicho2 plots(maxpoints=none)=all;
    class id;
    model bmi = time fage sex smoking bmi_d/ solution;
    random intercept time bmi_d/ subject=id type=UN;
run;

ods graphics off;

/* Transformations of the response variable */

ods graphics on / discretemax=4500;

data transformed2;
    set mydata.bmilda;
    log_bmi = log(bmi);
run;

data transformed3;
	set mydata.bmilda;
	sqrt_bmi=sqrt(bmi);
run;
data transformed4;
	set mydata.bmilda;
	square_bmi=bmi**2;
run;
data transformed5;
	set mydata.bmilda;
	sqrt3_bmi=bmi**(1/3);
run;
proc anova data=transformed2 plots(maxpoints=none)=all;
    class time;
    model log_bmi = time;
run;

proc univariate data=mydata.bmilda;
	var bmi;
run;
proc univariate data=transformed2;
	var log_bmi;
run;
proc univariate data=transformed3;
	var sqrt_bmi;
run;
proc univariate data=transformed4;
	var square_bmi;
run;
proc univariate data=transformed5;
	var sqrt3_bmi;
run;
proc mixed data=transformed2 plots(maxpoints=none)=all;
    class id;
    model log_bmi = time fage sex smoking / solution;
    random intercept time / subject=id type=UN;
run;

proc mixed data=transformed3 plots(maxpoints=none)=all;
    class id;
    model sqrt_bmi = time fage sex smoking / solution;
    random intercept time / subject=id type=UN;
run;

proc mixed data=transformed4 plots(maxpoints=none)=all;
    class id;
    model square_bmi = time fage sex smoking / solution;
    random intercept time / subject=id type=UN;
run;
proc mixed data=transformed5 plots(maxpoints=none)=all;
    class id;
    model sqrt3_bmi = time fage sex smoking / solution;
    random intercept time / subject=id type=UN;
run;

ods graphics off;
/* Transformations of the covariates */

ods graphics on / discretemax=4500;

data transfo1;
    set mydata.bmilda;
    log_fage = log(fage);
run;

data transfo2;
	set mydata.bmilda;
	sqrt_fage = sqrt(fage);
run;

data transfo3;
	set mydata.bmilda;
	square_fage = fage**2;
run;

data transfo4;
	set mydata.bmilda;
	log_time = log(time);
run;

data transfo5;
	set mydata.bmilda;
	sqrt_time = sqrt(time);
run;

data transfo6;
	set mydata.bmilda;
	square_time = time**2;
run;

data transfo7;
	set mydata.bmilda;
	sqrt3_time = time**(1/3);
run;

proc mixed data=transfo1 plots(maxpoints=none)=all;
    class id;
    model bmi = time log_fage sex smoking / solution;
    random intercept time / subject=id type=UN;
run;

proc mixed data=transfo2 plots(maxpoints=none)=all;
    class id;
    model bmi = time sqrt_fage sex smoking / solution;
    random intercept time / subject=id type=UN;
run;

proc mixed data=transfo3 plots(maxpoints=none)=all;
    class id;
    model bmi = time square_fage sex smoking / solution;
    random intercept time / subject=id type=UN;
run;

proc mixed data=transfo4 plots(maxpoints=none)=all;
    class id;
    model bmi = log_time fage sex smoking / solution;
    random intercept time / subject=id type=UN;
run;

proc mixed data=transfo5 plots(maxpoints=none)=all;
    class id;
    model bmi = sqrt_time fage sex smoking / solution;
    random intercept time / subject=id type=UN;
run;

proc mixed data=transfo6 plots(maxpoints=none)=all;
    class id;
    model bmi = square_time fage sex smoking / solution;
    random intercept time / subject=id type=UN;
run;

proc mixed data=transfo7 plots(maxpoints=none)=all;
    class id;
    model bmi = sqrt3_time fage sex smoking / solution;
    random intercept time / subject=id type=UN;
run;

ods graphics off;

/* Adding random effects */

ods graphics on / discretemax=4500;

proc mixed data=mydata.bmilda plots(maxpoints=none)=all;
    class id;
    model bmi = time fage sex smoking / solution;
    random intercept sex / subject=id type=UN;
run;

proc mixed data=mydata.bmilda plots(maxpoints=none)=all;
    class id;
    model bmi = time fage sex smoking / solution;
    random intercept fage / subject=id type=UN;
run;

proc mixed data=mydata.bmilda plots(maxpoints=none)=all;
    class id;
    model bmi = time fage sex smoking / solution;
    random intercept smoking / subject=id type=UN;
run;

ods graphics off;
