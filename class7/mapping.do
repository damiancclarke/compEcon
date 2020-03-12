/* mapping.do                    damiancclarke             yyyy-mm-dd:2020-03-06
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file creates a map of protests from the ACLED data (from Jan 1-Jan 31 2020)
along with each country's GDP per capita from the World Bank data bank.  This
file relies on a number of user-written ados which cap be installed from the SSC
as in section 1.  

Note that in certain cases, there have been issues with the data downloaded using
wbopendata.  If this is the case, line 43 which states:
 local wbflag   0
sould be changed to:
 local wbflag   1

This file also relies on data download from a number of external sources (disc-
ussed in class).  These are:

https://acleddata.com/#/dashboard

https://mapshaper.org/

http://thematicmapping.org/downloads/world_borders.php
*/

vers 12
clear all
set more off
cap log close

*-------------------------------------------------------------------------------
*-- (1) Globals, check for user-written ados and install if not available
*-------------------------------------------------------------------------------
global DAT "/mnt/SDD-2/trabajo/Teaching/Exeter/computationalEcon/compEcon/class7/test"
global OUT "/mnt/SDD-2/trabajo/Teaching/Exeter/computationalEcon/compEcon/class7/test"
global LOG "/mnt/SDD-2/trabajo/Teaching/Exeter/computationalEcon/compEcon/class7/test"

log using "$LOG/mapping.txt", text replace

**This is the start of my log file

local protests 2020-01-01-2020-01-31.csv
local worldmap TM_WORLD_BORDERS_SIMPL-0.shp
local wbflag   0


foreach ado in spmap shp2dta wbopendata {
    cap which `ado'
    if _rc!=0 ssc install `ado'
}


*-------------------------------------------------------------------------------
*-- (2) Import protest data and keep required variables
*-------------------------------------------------------------------------------
*insheet using 2020-01-01-2020-01-31.csv, comma clear names
insheet using "$DAT/`protests'", comma names
keep latitude longitude
saveold "$DAT/protests.dta", replace version(12)


*-------------------------------------------------------------------------------
*-- (3) Download and process GDP data
*-------------------------------------------------------------------------------
if `wbflag'==0 {
    wbopendata, indicator(NY.GDP.PCAP.CD) long clear
    keep if year==2018
    drop if iso2code==""
}
else use http://www.damianclarke.net/stata/wbGDPpc2018
saveold "$DAT/wbGDPpc2018", version(12) replace


*-------------------------------------------------------------------------------
*-- (4) Process shape files
*-------------------------------------------------------------------------------
shp2dta using "$DAT/`worldmap'", data("$DAT/world_data") coor("$DAT/world_coords") replace


*-------------------------------------------------------------------------------
*-- (5) Build up maps starting simply and getting complicated
*-------------------------------------------------------------------------------
use "$DAT/world_data", clear

** Map 1 is a map just checking if this works with a random variables
gen rand=rnormal()

spmap rand using "$DAT/world_coords.dta", id(_ID)
graph export "$OUT/baselineExample.eps", replace


** Map 2 is going to use GDP data to do this
use "$DAT/wbGDPpc2018", clear
rename iso2code ISO2
merge 1:1 ISO2 using world_data
drop if _merge==1

spmap ny_gdp_pcap_cd using "$DAT/world_coords.dta" if NAME!="Antartica", id(_ID)
graph export "$OUT/GDPonly.eps", replace
drop if NAME=="Antarctica"


** Map 3 is going to use real data (from protests) to superimpose on top of GDP
#delimit ;
spmap ny_gdp_pcap_cd using world_coords.dta, id(_ID)
   point(data(protests.dta) xcoord(longitude)ycoord(latitude));
graph export "$OUT/GDPwProtests.eps", replace;
#delimit cr


** Map 4 is going to make this look nice. See help file for spmap for all options
format ny_gdp_pcap_cd %5.0f
graph set eps fontface "Times New Roman"

#delimit ;
spmap ny_gdp_pcap_cd using world_coords.dta, id(_ID)
  point(data(protests.dta) xcoord(longitude) ycoord(latitude) fcolor(red) size(*0.3))
osize(vvthin) fcolor(Pastel2) clnumber(5)
legend(title("GDP per capita", size(*1.25) bexpand justification(left)))
legend(symy(*1.25) symx(*1.25) size(*1.9)) legstyle(2)
title("GDP per Capita and Protests (Jan 2020)")
note("Source: World Bank (GDP data) and The Armed Conflict Location & Event Data Project.");
graph export "$OUT/GDPwProtestsClean.eps", replace;
#delimit cr


*-------------------------------------------------------------------------------
*-- (6) Clean up
*-------------------------------------------------------------------------------
log close


