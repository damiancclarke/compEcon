/* mapping.do                    damiancclarke             yyyy-mm-dd:2020-03-06
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file creates a map of protests from the ACLED data (from Jan 1-Jan 31 2020)
along with each country's GDP per capita from the World Bank data bank.  This
file relies on a number of user-written ados which cap be installed from the SSC
as in section 1.  

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
global DAT "/mnt/SDD-2/trabajo/Teaching/Exeter/computationalEcon/compEcon/class7"
global OUT "/mnt/SDD-2/trabajo/Teaching/Exeter/computationalEcon/compEcon/class7"
global LOG "/mnt/SDD-2/trabajo/Teaching/Exeter/computationalEcon/compEcon/class7"

log using "$LOG/mapping.txt", text replace

local protests 2020-01-01-2020-01-31.csv
local worldmap TM_WORLD_BORDERS_SIMPL-0.shp     

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
wbopendata, indicator(NY.GDP.PCAP.CD) long clear
keep if year==2018
drop if iso2code==""
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
  point(data(protests.dta) xcoord(longitude) ycoord(latitude) fcolor(red) size(*0.5))
osize(vvthin) fcolor(Pastel1) clnumber(5)
legend(title("GDP per capita", size(*1.25) bexpand justification(left)))
legend(symy(*1.25) symx(*1.25) size(*1.5)) legstyle(2)
title("GDP per Capita and Protests (Jan 2020)");
graph export "$OUT/GDPwProtestsClean.eps", replace;
#delimit cr


*-------------------------------------------------------------------------------
*-- (6) Clean up
*-------------------------------------------------------------------------------
log close


