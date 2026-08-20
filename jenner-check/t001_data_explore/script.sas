/* Adapted from Project.sas (lines 1-77): data formatting, baseline extraction,
   and the amount-of-smokers/sex exploration. Original read mydata.bmilda via a
   hardcoded libname to an external SAS session folder; here the same shape of
   data is supplied inline via DATALINES so the PROCs run unmodified. */

PROC FORMAT;
 VALUE smokingf 1='Smoker'
 0='NonSmoker';
 VALUE sexf 0='Female'
 1='Male';
RUN;

data bmilda;
    input id time bmi fage sex smoking;
    datalines;
1 0 22.08 46.0 0 0
1 1 21.99 46.0 0 0
1 2 21.59 46.0 0 0
2 0 26.5 37.7 0 0
2 1 26.32 37.7 0 0
2 2 26.57 37.7 0 0
3 0 21.4 31.9 0 1
3 1 21.7 31.9 0 1
3 2 21.58 31.9 0 1
4 0 20.15 38.8 0 1
4 1 20.38 38.8 0 1
4 2 19.34 38.8 0 1
4 3 21.18 38.8 0 1
5 0 22.48 50.3 0 0
5 1 22.36 50.3 0 0
5 2 22.93 50.3 0 0
5 3 23.57 50.3 0 0
6 0 22.7 25.7 0 0
6 1 22.23 25.7 0 0
6 2 22.85 25.7 0 0
6 3 24.13 25.7 0 0
7 0 30.55 22.3 1 1
7 1 30.86 22.3 1 1
7 2 30.38 22.3 1 1
7 3 30.22 22.3 1 1
7 4 30.22 22.3 1 1
8 0 25.17 27.7 1 1
8 1 25.55 27.7 1 1
8 2 26.37 27.7 1 1
9 0 26.24 33.4 0 1
9 1 25.81 33.4 0 1
9 2 26.54 33.4 0 1
9 3 25.84 33.4 0 1
10 0 19.26 35.2 0 1
10 1 19.88 35.2 0 1
10 2 18.96 35.2 0 1
10 3 20.17 35.2 0 1
11 0 26.04 33.1 0 0
11 1 25.54 33.1 0 0
11 2 25.88 33.1 0 0
12 0 31.3 22.0 1 0
12 1 31.33 22.0 1 0
12 2 31.72 22.0 1 0
12 3 31.74 22.0 1 0
12 4 31.44 22.0 1 0
13 0 27.87 52.5 1 0
13 1 28.15 52.5 1 0
13 2 28.94 52.5 1 0
13 3 27.3 52.5 1 0
13 4 26.9 52.5 1 0
14 0 19.3 22.5 0 0
14 1 19.78 22.5 0 0
14 2 19.65 22.5 0 0
14 3 20.54 22.5 0 0
14 4 21.82 22.5 0 0
15 0 20.08 48.3 0 1
15 1 20.66 48.3 0 1
15 2 19.88 48.3 0 1
;
run;

proc sort data=bmilda out=sorted;
    by id time;
run;

data ID_once;
    set sorted;
    by id time;
    if first.ID then output;
run;

/* **amount of males/females and smokers/nonsmokers** */
proc freq data=ID_once;
   tables sex smoking smoking*sex;
   title "Amount of males and females and smokers/nonsmokers";
   format smoking smokingf. sex sexf.;
run;

/* **amount of repeated observations in the dataset** */
proc freq data=bmilda;
   tables id / out=obs_counts(keep=id count rename=(count=num_observations));
run;

proc freq data=obs_counts;
   tables num_observations / out=obs_summary(rename=(num_observations=frequency));
run;

/* **mean fage and BMI** */
proc means data=bmilda;
   var bmi fage;
   title "Mean BMI and Age for all observations";
run;
proc means data=ID_once;
   var bmi fage;
   title "Mean BMI and Age for all individuals at baseline";
run;
