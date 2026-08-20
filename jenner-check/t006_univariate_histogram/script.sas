/* Adapted from Project.sas (lines 280-329): histogram + grouped-density view
   of the empirical Bayes random-effect estimates by sex. Original read
   mydata.ebWide via a hardcoded libname; here a representative wide table of
   per-subject EB intercept/slope estimates (the output shape of the script's
   own PROC TRANSPOSE step) is supplied inline via DATALINES so PROC
   UNIVARIATE and PROC SGPLOT run unmodified. */

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

data ebWide;
    input id sex smoked ebintercept ebtime;
    datalines;
1 0 0 -1.35 0.21
2 0 0 2.02 -0.08
3 0 1 -2.14 0.15
4 0 1 -3.41 0.44
5 0 0 -1.02 0.36
6 0 0 -0.79 0.48
7 1 1 6.03 -0.09
8 1 1 1.11 0.60
9 0 1 1.72 -0.13
10 0 1 -4.29 0.30
11 0 0 1.44 -0.11
12 1 0 7.19 0.11
13 1 0 3.30 -0.24
14 0 0 -4.60 0.63
15 0 1 -4.35 -0.10
;
run;

/* Regular Histograms intercepts and slopes */
proc univariate data=ebWide;
format sex sexFmt.;
format smoked smokerFmt.;
	var ebintercept;
	id sex smoked;
	histogram ebintercept / odstitle = "EB Estimates for Intercepts" nohlabel vaxislabel="Proportion";
run;

/*Random effects split by gender for intercepts*/
proc sgplot data=ebWide;
format sex sexFmt.;
	histogram ebintercept / group=sex transparency=0.5;
	density ebintercept / group=sex;
	xaxis display=(nolabel);
	title "Intercept Estimates by Gender";
	refline 0 / axis = x lineattrs=(thickness=1 color=black pattern = dash);
run;
