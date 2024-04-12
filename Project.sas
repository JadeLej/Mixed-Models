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
