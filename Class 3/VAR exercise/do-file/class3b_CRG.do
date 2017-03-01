**************************************************
* Class 3, Part 2: Time Series analysis
**************************************************
* MONETARY POLICY VAR AND CHOLESKY IDENTIFICATION
**************************************************

* Stata has a very particular set of functions that control time series commands.
* In order to use these commands, you must ensure that you tell Stata.
* As with the panel data commands, we can do this using the tsset command.
* Remember that the data must be sorted by the time series. For example:
* sort datevar
* tsset datevar

* Once you have done this, you are free to use the time series commands, such as: 
*    - tsset: Declare a dataset to be time-series data
*    - tsfill: Fill in missing times with missing observations in time-series data
*    - tsappend: Add observations to a time-series dataset
*    - tsreport: Report time-series aspects of a dataset or estimation sample
*    - arima: Autoregressive integrated moving-average models
*    - arch: Autoregressive conditional heteroskedasticity (ARCH) family of estimators
*    - tssmooth_ma: Moving-average filter
*    - tssmooth_nl: Nonlinear filter
*    - corrgram: Tabulate and graph autocorrelations
*    - xcorr: Cross-correlogram for bivariate time series
*    - dfuller: Augmented Dickey-Fuller unit-root test
*    - pperron: Phillips-Perron unit-roots test
*    - archlm: Engle's LM test for the presence of autoregressive conditional heteroskedasticity
*    - var: Vector autoregression models
*    - svar: Structural vector autoregression models
*    - varbasic: Fit a simple VAR and graph impulse-response functions
*    - vec: Vector error-correction models
*    - varsoc: Obtain lag-order selection statistics for VARs and VECMs
*    - varstable: Check the stability condition of VAR or SVAR estimates
*    - vecrank: Estimate the cointegrating rank using Johansen's framework
*    - irf create: Obtain impulse-response functions and FEVDs
*    - vargranger: Perform pairwise Granger causality tests after var or svar
*    - irf graph: Graph impulse-response functions and FEVDs
*    - irf cgraph: Combine graphs of impulse-response functions and FEVDs
*    - irf ograph: Graph overlaid impulse-response functions and FEVDs
* You can type help time for more time series commands.

* Let's begin!!
* As always...
capture log close
set more off
clear all

* Path for directory
global data "C:\Users\Claudia\Dropbox\Teaching\teaching Stata\Class 3b\data"
global data2 "C:\Users\roblesga\Desktop"
global output "C:\Users\Claudia\Dropbox\Teaching\teaching Stata\Class 3b\output"
global output2 "C:\Users\roblesga\Desktop"

* Change directory
cd "$data2"

* Import data from excel file (first sheet in excel file)
import excel using data_ps3.xlsx, clear firstrow

* Labels
label var obs "time"
label var LOGGDP "Log of real GDP" 
label var LOGP "Log of price index"
label var FFR "Federal fund rate"

* Renaming
rename obs TIME
foreach var of varlist *{
local temp=lower("`var'")
rename `var' `temp'
}
*

*******************
* Data description
*******************
* Describe
des
* Summarize
sum 

**************************
* Generate quarterly data
**************************
* Year
gen year=substr(time,1,4)
* Quarter
gen quarter=substr(time,6,1)
* Get them in numeric format
destring year quarter, replace force

* Define as date as year-quarter
gen date=yq(year,quarter)
* Different date functions available:
*   - mdy(month,day,year): for daily data
*   - yw(year, week): for weekly data
*   - ym(year,month): for monthly data
*   - yq(year,quarter): for quarterly data
*   - yh(year,half-year): for half-yearly data

* Correct the time format
format date %tq
* Different formats available:
* %td daily 
* %tw weekly 
* %tm monthly 
* %tq quarterly 
* %th half-yearly 
* %ty yearly 

* Careful on how you call dates. Remember, Stata stores dates as the number 
* of elapsed periods since January 1, 1960. In our case, the number of elapsed 
* quarters since 1996 Q1. 
gen gdp_part=loggdp if date<=tq(1978q4)
* Declare time series format
sort date
tsset date

*****************
* Detrend series
*****************
* Look at the time series
twoway line loggdp date, sort
* Detrend (linear) and get rid of seasonality
foreach var of varlist loggdp logp{
reg `var' date i.quarter
predict `var'_detrended, res
}
*

*****************
* Leads and lags
*****************
* Move time series up by one quarter (or in general one unit) using forward operator
gen forward_logdp=f.loggdp
* Move time series down by one quarter (or in general one unit) using lag operator
gen lag_logdp=l.loggdp

**********************************************
* Autocorrelation and partial autocorrelation
**********************************************
* Autocorrelation function
ac loggdp
* Partial autocorrelation
pac loggdp

********************
* Stationarity test
********************
* Simple augmented Dickey-Fueller test
dfuller loggdp
* Simple augmented Dickey-Fueller test with additional lag
dfuller loggdp, lags(1)
* Simple augmented dickey-Fueller test with additional lag but including trend term in regression
dfuller loggdp, lags(1) trend

* Take first differences
gen dloggdp=loggdp-l.loggdp
* You could also use the differencing operator (d.varname) or the seasonal 
* differencing operator (s.varname)

* Check if the series is still non-stationary
dfuller dloggdp
dfuller loggdp_detrended

********************************************
* Structural Vector Autoregressions (SVAR) 
********************************************
* For monetary policy (short-run, just-identified model)
* Cholesky decomposition (easy way to orthogonalise shocks)
* Matrix constraints (we will later impose these as equality constraints)
matrix A = (1,0,0\.,1,0\.,.,1)
matrix B = (.,0,0\0,.,0\0,0,.)
* If dealing with the short-run, overidentified SVAR, then use:
* matrix A = (1,0,0\0,1,0\.,.,1)
* matrix B = (.,0,0\0,.,0\0,0,.)

* Estimate structural form var (SVAR)
svar loggdp logp ffr , aeq(A) beq(B) lags(1 2 3 4)
* The SVAR output has four parts: 
*  1. an iteration log
*  2. a display of the constraints imposed
*  3. a header with sample and SVAR log-likelihood information
*  4. a table displaying the estimates of the parameters from the A and B matrices.

*****************************
* Impulse response function
*****************************
* Create file containing impulse response function
irf create ffr, step(16) set(myirf) replace
* Generate impuse response function
irf graph oirf, impulse(ffr) response(loggdp) plot1opts(color("gs1")) ci1opts(fcolor("none")) yline(0) xlabel(0(4)16) title("Monetary Policy shock on GDP")
irf graph oirf, impulse(ffr) response(logp)
* irf can also be used for vector error-correction models (VECMS)
* See: http://www.stata.com/manuals13/tsvecintro.pdf


