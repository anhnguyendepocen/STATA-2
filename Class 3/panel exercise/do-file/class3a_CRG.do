************************************
* Class 3, Part 1: Panel analysis
************************************

* Panel dataset: you have data on N countries/people/firms/etc, over T time periods
* giving you a total of NxT observations.
* Panel data should be kept in long format (with separate person and time variables).
* The first thing to do is to declare your data a panel using the command xtset:
* sort panelvar timevar /* Recall that the data must be sorted */
* xtset panelvar timevar
* Then you are free to use Stata's panel data commands, such as:
*    - xtdes: Describe pattern of xt data
*    - xtsum: Summarize xt data
*    - xttab: Tabulate xt data
*    - xtdata: Faster specification searches with xt data
*    - xtline: Line plots with xt data
*    - xtreg: Fixed-, between- and random-effects, and population-averaged linear models
*    - xtregar: Fixed- and random-effects linear models with an AR(1) disturbance
*    - xtgls: Panel-data models using GLS
*    - xtpcse: OLS or Prais-Winsten models with panel-corrected standard errors
*    - xtrchh: Hildreth-Houck random coefficients models
*    - xtivreg: Instrumental variables and two-stage least squares for panel-data models
*    - xtabond: Arellano-Bond linear, dynamic panel data estimator
*    - xttobit: Random-effects tobit models
*    - xtintreg: Random-effects interval data regression models
*    - xtlogit: Fixed-effects, random-effects, & population-averaged logit models
*    - xtprobit: Random-effects and population-averaged probit models
*    - xtcloglog: Random-effects and population-averaged cloglog models
*    - xtpoisson: Fixed-effects, random-effects, & population-averaged Poisson models
*    - xtnbreg: Fixed-effects, random-effects, & population-averaged negative binomial models
*    - xtgee: Population-averaged panel-data models using GEE

* Let's begin!!
* As always...
clear all
set more off
capture log close

* Path for directory
global data "C:\Users\Claudia\Dropbox\Teaching\teaching Stata\Class 3a\data"
global data2 "C:\Users\roblesga\Desktop"
global output "C:\Users\Claudia\Dropbox\Teaching\teaching Stata\Class 3a\output"
global output2 "C:\Users\roblesga\Desktop"

* Change directory
cd "$data2"

*import data
use dataset.dta, clear

****************
* Describe data
****************
* Describe dataset
des
* Summarize data
sum
* Describe dataset structure
tab year country

**********************************
* Restict analysis to Euro Area
**********************************
keep if country=="Austria" | country=="Belgium" | country=="Estonia" | country=="Finland" | country=="France" ///
| country=="Germany" | country=="Greece" | country=="Ireland" | country=="Italy" | country=="Netherlands" ///
| country=="Portugal" | country=="Slovakia" | country=="Slovenia" | country=="Spain"

***************************************
* Data description: fertility and GDP
***************************************
* Cross sectional evidence
* Generate log of GDP
gen lgdp=log(gdp_ppp)
gen lgdp2=lgdp^2
* Regression for prediction using year 1993
reg fertility lgdp if year==1993
predict fert_1993, xb
reg fertility lgdp lgdp2 if year==1993
predict fert2_1993, xb
* Graph for 1993
twoway (scatter fertility lgdp if year==1993, sort mlabel(country)) (line fert_1993 lgdp if year==1993, sort) ///
 (line fert2_1993 lgdp if year==1993, sort), graphregion(color(white)) xtitle("Log of GDP in PPP") ///
 ytitle("Fertility rate") title("Correlation in 1993") legend(off)

 * Regression for prediction using year 2001
reg fertility lgdp if year==2001
predict fert_2001, xb
reg fertility lgdp lgdp2 if year==2001
predict fert2_2001, xb
* Graph for 2001
twoway (scatter fertility lgdp if year==2001, sort mlabel(country)) (line fert_2001 lgdp if year==2001, sort) ///
(line fert2_2001 lgdp if year==2001, sort), graphregion(color(white)) xtitle("Log of GDP in PPP") ///
ytitle("Fertility rate") title("Correlation in  2001") legend(off)

******************************************************
* Data description: fertility and female employment
******************************************************
gen f_emp2=f_emp^2

* Regression for prediction using year 1993
reg fertility f_emp if year==1993
predict fert_1993emp, xb
reg fertility f_emp f_emp2 if year==1993
predict fert2_1993emp, xb
* Graph for 1993
twoway (scatter fertility f_emp if year==1993, sort mlabel(country)) (line fert_1993emp f_emp if year==1993, sort) ///
(line fert2_1993emp f_emp if year==1993, sort), graphregion(color(white)) xtitle("Female employment") ///
ytitle("Fertility rate") title("Correlation in 1993") legend(off)

* Regression for prediction using year 2001
reg fertility f_emp if year==2001
predict fert_2001emp, xb
reg fertility f_emp f_emp2 if year==2001
predict fert2_2001emp, xb
* Graph for 2001
twoway (scatter fertility f_emp if year==2001, sort mlabel(country)) (line fert_2001emp f_emp if year==2001, sort) ///
(line fert2_2001emp f_emp if year==2001, sort), graphregion(color(white)) ///
xtitle("Female employment") ytitle("Fertility rate") title("Correlation in  2001") legend(off)

***********************
* Regression analysis
***********************
* Cross-sectional pure models
reg fertility f_emp, robust
* Cross section: controls
xi: reg fertility f_emp lgdp exp_family epl_permanent f_part_time f_temp_emp, robust
* PROBLEM: large amount of unobsorved heterogeneity and possible correlation of
* errors within country

* Set panel (two dimensional dataset: unit of observation, time of the observation)
encode country, gen(country_code)
xtset country_code year

************************************************************************************************
* Random effects (RE) model: unobserved (time fixed) elements not relevant as omitted variables
************************************************************************************************
xi: xtreg fertility f_emp lgdp epl_permanent exp_family f_part_time f_temp_emp, re
* Save estimated results
estimates store re
* Stata's RE estimator is a weighted average of fixed and between effects (remember
* that the latter is equivalent to running a regression on the dataset of means 
* by cross-sectional identifier).

*******************************************************************************************
* Fixed effects (FE) model: unobserved (time fixed) elements relevant as omitted variables
*******************************************************************************************
* FE regression controls for unobserved, but constant, variation across the cross-section units.
xi: xtreg fertility f_emp lgdp epl_permanent exp_family f_part_time f_temp_emp i.country, fe
* Variables that are constant across time for each country are dropped, because
* they are subsumed by the country fixed-effect.
* Save estimated results
estimates store fe
* Notice that FE is equivalent to including a dummy for each country in the regression.
xi: reg fertility f_emp lgdp epl_permanent exp_family f_part_time f_temp_emp i.country

*****************************************************************
* Hausman test: check for systematic differences in two models
*****************************************************************
* The choice between models is made using a Hausman test, which compares 
* RE coefficients (efficient but not always consistent) to FE coefficients (more 
* robust in terms of consistency, but not as efficient if RE assumptions hold).
hausman fe re 
* The null hypothesis is that there is no difference in the coefficients estimated 
* by the efficient RE estimator and the consisten FE estimator.
* If there is no difference, then use the RE estimator. Otherwise, use FE or other
* solution for unobserved heterogeneity.

* PROBLEM: endogeneity due to simultaneity --> we could use lags
* Fixed effects
xi: xtreg fertility l.f_emp l.lgdp l.epl_permanent l.exp_family l.f_part_time l.f_temp_emp, fe robust

**********************************************
* Lagged dependent variable and dynamic panel
**********************************************
* Fixed effects --> estimates will be inconsistent
xi: xtreg fertility l.fertility l.f_emp l.lgdp l.epl_permanent l.exp_family l.f_part_time l.f_temp_emp, fe robust
* Arellano-Bond estimator as correction for dynamic panel inconsistency
xtabond fertility l.f_emp l.lgdp l.epl_permanent l.exp_family l.f_part_time l.f_temp_emp, vce(robust) lags(1) artests(4)
* Test for residual autocorrelation (if correlation at orders greater than one it could be a problem)
estat abond
