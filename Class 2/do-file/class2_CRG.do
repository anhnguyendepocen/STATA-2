******************************************************************************
*STATA class 2: Regression and IV
*Based on "Does Compulsory School Attendance Affect Schooling and Earnings?"
*Angrist and Krueger, 1991, QJE
******************************************************************************

* We now move on from the manipulation of databases to the more exciting material
* of running regressions.

* The main/most popular commands include:
*    - anova: analysis of variance and covariance
*    - cnreg: censored-normal regression
*    - cnsreg: constrained linear regression
*    - heckman: Heckman selection model
*    - intreg: interval regression
*    - ivreg: instrumental variables (2SLS) regression
*    - newey: regression with Newey-West standard errors
*    - prais: Prais-Winsten, Cochrane-Orcutt, or Hildreth-Lu regression
*    - qreg: quantile (including median) regression
*    - reg: ordinary least squares regression
*    - reg3: three-stage least squares regression
*    - rreg: robust regression (NOT robust standard errors)
*    - sureg: seemingly unrelated regression
*    - svyheckman: Heckman selection model with survey data
*    - svyintreg: interval regression with survey data
*    - svyivreg: instrumental variables regression with survey data
*    - svyregress: linear regression with survey data
*    - tobit: tobit regression
*    - treatreg: treatment effects model
*    - truncreg: truncated regression
*    - xtabond: Arellano-Bond linear, dynamic panel-data estimator
*    - xtintreg: panel data interval regression models
*    - xtreg: fixed- and random-effects linear models
*    - xtregar: fixed- and random-effects linear models with an AR(1) disturbance
*    - xttobit: panel data tobit models

* Most have a similar syntax:
*   command varlist [weight] [if exp] [in range],[,options]

* The first variable in the varlist is the dependent variable, and the remaining
* are the independent variables.
* Stata automaticall adds the intercept (use the noconstant option if you want to
* exclude it).

* You can, at any time, review the last estimates by typing the estimation command
* without arguments.

* The level() option indicates the width of the confidence interval. The default 
* is level(95).

* Once you have run your estimation, you can carry out extra analysis, such as 
* forecasting or hypothesis testing:
*    - adjust: Tables of adjusted means and proportions
*    - estimates: Store, replay, display, ... estimation results
*    - hausman: Hausman's specification test after model fitting
*    - lincom: Obtain linear combinations of coefficients
*    - linktest: Specification link test for single-equation models
*    - lrtest: Likelihood-ratio test after model fitting
*    - mfx: Marginal effects or elasticities after estimation
*    - nlcom: Nonlinear combinations of estimators
*    - predict: Obtain predictions, residuals, etc. after estimation
*    - predictnl: Nonlinear predictions after estimation
*    - suest: Perform seemingly unrelated estimation
*    - test: Test linear hypotheses after estimation
*    - testnl: Test nonlinear hypotheses after estimation
*    - vce: Display covariance matrix of the estimators

******************
* Let's begin!!
******************
* As always...
capture log close
set more off
clear all

*******************************************
* Define directories for data and output
*******************************************
global data "C:\Users\Claudia\Dropbox\Teaching\teaching Stata\Class 2\data"
global data2 "C:\Users\roblesga\Desktop"
global output "C:\Users\Claudia\Dropbox\Teaching\teaching Stata\Class 2\output"
global output2 "C:\Users\roblesga\Desktop"

*change directory
cd "$data2"

***************
* Import data
***************
* US CENSUS 1980
use census2008.dta, clear
* See annex_class2_CRG.do for data cleaning code

*******************
* Explore dataset
*******************
* Describe content of dataset
des
* Summarize all variables
sum *

****************************************
* Look more closely at income variables
****************************************
* More precise information on variables
codebook  inctot  incwage
* Summarize income variables
sum  inctot incwage, det
* Recode as missing
replace inctot=. if inctot==9999999
replace incwage=. if incwage==999999
* Find the correlation between the two variables and report significance
pwcorr inctot incwage, sig /* Displays all pairwise correlation coefficients */
corr inctot incwage /* Displays correlation matrix or covariance matrix */
* Do log-transformation on income variables
gen log_tincome=log(inctot/wkswork1)
gen log_incwage=log(incwage/wkswork1)


****************************
* Modify relevant variables
****************************
* Generate years of education
gen education=higrade-3
replace education=. if education<-1
replace education=0 if education<0 & education>-2
tab education

*******************
* Restrict sample
*******************
* Keep only individuals born between 1930-1939
keep if birthyr>1929 & birthyr<1940
* Tabulate gender
tab sex
* No labels
tab sex, nol
* Keep only males
drop if sex==2
* Keep only US born
keep if bpl<100
* Drop if log weekly wage is missing
drop if log_incwage==.
* Tabulate metro area
tab metro
tab metro, nol
* Drop if metro area not identified
drop if metro==0

***********************************************
* Basic OLS regression: education and earnings
***********************************************
* Simple OLS regression
reg log_incwage education
* Predicted values for dependent variable
predict log_incwage_hat
* Predicted residuals 
predict e, res
* Check residuals
sum e
* Residual plot by hand
twoway scatter e education

****************************************
* Test for significance of coefficients
****************************************
gen education2=education^2
reg log_incwage education education2
* Perform an F-test on the null hypothesis that the "true" coefficient is zero
test education
* You can perform any test on linear hypothesis about the coefficients
test education=0.5 /* test coefficient on education equals 0.5 */
test education=education2 /* test coefficients on education and education2 are the same */
test education education2 /* test coefficients on education and education2 are jointly zero */
test education+education2=0.5 /* test coefficients on education and education2 sum to 0.5 */
* If you want to test a long list of variables, you can use the testparm command
* (but remember to use the order command to bring the variables in the right order first).

***************************************************
* Test for heteroskedasticity 
***************************************************
* Install White test
capture ssc install whitetst
* Simple OLS regression
reg log_incwage education
* Breusch-Pagan test
hettest
* White test for heteroskedasticity
whitetst
estat imtest, white

***************************************************
* Manually test for heteroskedasticity (White)
***************************************************
* Generate variables
gen e2=e^2
reg e2 education education2
* See what you can take from regression
ereturn list
* White test statistic
local test=e(N)*(e(mss)/(e(mss)+e(rss)))
display "Test statistic for White test is `test'"

***************************************************
* Correcting heteroskedasticity or cluster
***************************************************
* Simple OLS regression with Huber-White sandwich estimator (to correct standard
* errors for heterokedasticity)
reg log_incwage education, robust
* Simple OLS regression with standard errors clustered at state level
* To allow for arbitrary correlation within specified groups (deviation from 
* the iid-assumption)
reg log_incwage education, cluster(statefip)

**********************
* Extracting results
**********************
regress log_incwage education, robust
gen b_cons=_b[_cons] /* beta coefficient on the constant term */
gen b_educ=_b[education] /* beta coefficient on education variable */
gen se_educ=_se[education] /*standard error of beta coefficient on education variable */
* Also, Stata stores estimation results in e()
ereturn list
* In fact, most Stata commands -not just estimation command- store results in 
* internal memory, ready for possible extraction and usually saved in r().
sum education
return list
gen mean_educ=r(mean)


*******************************************************
* Instrumental variables: solving endogeneity problem
*******************************************************
gen quarter1=(birthqtr==1)
gen quarter2=(birthqtr==2)
gen quarter3=(birthqtr==3)
gen quarter4=(birthqtr==4)

* Check if instrument valid, two-sample t-test for equal means
ttest education, by(quarter1)
* Relevance condition / First stage
reg education quarter2 quarter3 quarter4

**************************************************
* Just-Identified Case: using only one instrument
**************************************************
ivregress 2sls log_incwage (education=quarter1), robust first

* Alternative estimation methodologies
* 1. "by hand"
* First Stage
reg education quarter1, robust
* Predict education
predict edhat, xb
* xb option calculates linear prediction
* Second stage
reg log_incwage edhat, robust
* Important: You get correct coefficients, but standard errors are WRONG.

* 2. Indirect least squares
* First stage
reg education quarter1, robust
local first=_b[quarter1]
* Reduced form
reg log_incwage quarter1, robust
local red=_b[quarter1]
* IV coefficient
display  `red'/`first'

********************************************************************
* Overidentified Case: more instruments than endogenous variables
********************************************************************
* Install command for nice tables for regression output. It automatically creates
* excel, word or latex tables or regressions resulys. It will save you loads of 
* time and effort.
ssc install outreg2
* If run into some error, due to for example "installations administrator-only",
* then run the ado file and the command becomes available temporarily.
*cap run http://fmwww.bc.edu/repec/bocode/o/outreg2.ado
*view http://fmwww.bc.edu/repec/bocode/o/outreg2.hlp
capture cd "$output2"
* Basic regresion
* First stage
reg education quarter2 quarter3 quarter4
* Remember not to add all quarter dummies, because since Stata includes an intercept
* by default, you would have perfect collinearity and run into a dummy trap.
local F=round(e(F)*1000)/1000
* Variable to get rid always of omitted variables (dropped variables, not omitted
* variables in sense of relevant and excluded by regression) 
gen a=1
* Using two-stage least squares estimator
xi: ivregress 2sls log_incwage (education= quarter2 quarter3 quarter4), robust
outreg2 using table1, word nocons replace addtext(Region FE, "NO", Birth Year FE, "NO", Race FE, "NO", State of birth FE, "NO", Extended instr,"NO") ctitle("IV") 
* Add controls
xi: ivregress 2sls log_incwage a i.region i.birthyr (education= quarter2 quarter3 quarter4), robust
outreg2 using table1, word nocons append addtext(Region FE, "YES", Birth Year FE, "YES", Race FE, "NO", State of birth FE, "NO", Extended instr,"NO") ctitle("IV")  drop(_I* o.*)
* Extensions
* Year in quarters
sum birthyr
return list
gen age_quarter=(birthyr-r(min))*4
gen age_quarter2=age_quarter^2
* Married
gen married=(marst==1)
* Central area
gen central=(metro==2)
* Add more controls
xi: ivregress 2sls log_incwage a central married age_quarter age_quarter2 i.region i.birthyr i.race  i.bpl (education= quarter2 quarter3 quarter4), robust
outreg2 using table1, word nocons append addtext(Region FE, "YES", Birth Year FE, "YES", Race FE, "YES", State of birth FE, "YES", Extended instr,"NO") ctitle("IV")  drop(_I* o.*)
* Add more instruments
xi: ivregress 2sls log_incwage a central married age_quarter age_quarter2 i.region i.birthyr i.race  i.bpl (education= i.birthqtr*i.bpl i.birthqtr*i.birthyr), robust
outreg2 using table1, word nocons append addtext(Region FE, "YES", Birth Year FE, "YES", Race FE, "YES", State of birth FE, "YES", Extended instr,"YES") ctitle("IV")  drop(_I* o.*)
* More instruments using limited-information maximum likelihood (LIML) estimator
xi: ivregress liml log_incwage a central married age_quarter age_quarter2 i.region i.birthyr i.race  i.bpl (education= i.birthqtr*i.bpl i.birthqtr*i.birthyr), robust
outreg2 using table1, word nocons append addtext(Region FE, "YES", Birth Year FE, "YES", Race FE, "YES", State of birth FE, "YES", Extended instr,"YES") ctitle("LIML") drop(_I* o.*)
* More instruments using generalized method of moments (GMM) estimator
xi: ivregress gmm log_incwage a central married age_quarter age_quarter2 i.region i.birthyr i.race  i.bpl (education= i.birthqtr*i.bpl i.birthqtr*i.birthyr), robust
outreg2 using table1, word nocons append addtext(Region FE, "YES", Birth Year FE, "YES", Race FE, "YES", State of birth FE, "YES", Extended instr,"YES") ctitle("GMM") drop(_I* o.*)

****************
* GMM "by hand"
*****************
xi: ivregress gmm log_incwage central (education= quarter2 quarter3 quarter4), robust i
* Manually GMM
xi: gmm (log_incwage -{xb: education central}-{b0}), instruments(central quarter2 quarter3 quarter4) nolog i 
