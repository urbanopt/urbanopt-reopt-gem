# URBANopt REopt Gem

## Version 0.8.0
Date Range: 11/23/21 - 05/10/22
- Fixed [#95]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/95 ), adding additional PV fields to UO reports
- Fixed [#98]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/98 ), updates for OpenStudio 3.3
- Fixed [#99]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/99 ), fix dependencies
- Fixed [#100]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/100 ), Bump url-parse from 1.5.1 to 1.5.2 in /docs
- Fixed [#104]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/104 ), adding REopt results to URBANopt reports
- Fixed [#105]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/105 ), Bump follow-redirects from 1.13.3 to 1.14.8 in /docs
- Fixed [#106]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/106 ), Bump nanoid from 3.1.23 to 3.3.0 in /docs
- Fixed [#107]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/107 ), Bump url-parse from 1.5.1 to 1.5.6 in /docs
- Fixed [#108]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/108 ), Bump prismjs from 1.23.0 to 1.27.0 in /docs
- Fixed [#109]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/109 ), Bump url-parse from 1.5.1 to 1.5.8 in /docs
- Fixed [#110]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/110 ), Bump url-parse from 1.5.1 to 1.5.9 in /docs
- Fixed [#111]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/111 ), Renewable pct
- Fixed [#114]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/114 ), Bump nanoid from 3.1.23 to 3.3.1 in /docs
- Fixed [#115]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/115 ), Bump follow-redirects from 1.13.3 to 1.14.9 in /docs
- Fixed [#116]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/116 ), Bump minimist from 1.2.5 to 1.2.6 in /docs
- Fixed [#117]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/117 ), Update copyrights
- Fixed [#118]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/118 ), Bump async from 2.6.3 to 2.6.4 in /docs

## Version 0.7.0

Date Range: 10/16/21 - 11/22/21:

* Updated dependencies for OpenStudio 3.3

## Version 0.6.2

Date Range: 06/30/21 - 10/15/21:

* Fixed [#90]( https://github.com/urbanopt/urbanopt-reopt-gem/issues/90 ), Add location of PV to Scenario and Feature optimization reopt reports
* Fixed [#90]( https://github.com/urbanopt/urbanopt-reopt-gem/issues/91 ), Add constrain for area of ground-mount and community solar


# Version 0.6.1

Date Range: 04/30/21 - 06/30/21:
* Fixed [#83]( https://github.com/urbanopt/urbanopt-reopt-gem/issues/83 ), reopt rate-limit error is hard to decipher
* Fixed [#84]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/84 ), Api error codes
* Fixed [#86]( https://github.com/urbanopt/urbanopt-reopt-gem/pull/86 ), update rubocop configs to v4

## Version 0.6.0
Date Range: 4/16/21 - 4/29/21

* Update dependencies for OpenStudio 3.2.0 / Ruby 2.7

## Version 0.5.7

Date range: 4/7/21 - 4/15/21
* Fixes a bug that prevents **Feature Reports** from being saved


## Version 0.5.6

Date range: 3/12/21 - 4/7/21
* Fixes a bug that shifts REopt Lite timeseries data by 24 hours in **Feature Report** CSV's


## Version 0.5.5

Date range: 2/8/21 - 3/12/21
* Fixes a bug that shifts REopt Lite timeseries data by 24 hours in **Feature** and **Scenario Report** CSV's


## Version 0.5.4

Date range: 2/8/21 - 2/25/21
* Converts **Feature** and **Scenario Report** native timeseries data (i.e. load profile, optimized dispatches) to/from the specified **REopt Lite** time series resolution (defaulted to 1 timestep per hour), such that **OpenStudio** can be run at 10-minute intervals and **REopt Lite** at 1-hour or 15-minute intervals.


## Version 0.5.3

Date range: 1/21/21 - 2/8/21
* **Storage** should not be considered in total production CSV series
* **coincident_peak_load_charge_us_dollars_per_kw** should be defaulted to 0

## Version 0.5.2

Date range: 1/08/21 - 1/21/21
* Adds default coincident peak load (top 100 hours) if not specified in assumptions file to a REopt Lite post
* Specifies coincident peak price as 0 in test assumptions file to turn it off
* Allows default roof area, land area and timesteps per hour to be overwritten by assumptions file when creating a REopt Lite post


## Version 0.5.1

Date range: 12/11/20 - 1/08/21

* Extend polling time for resilience results
* Do not error out if there are no resilience results
* Handle renamed available_roof_area_sqft parameter (had been available_roof_area)


## Version 0.5.0

Date range: 11/13/20 - 12/11/20

* Updates to support OpenStudio 3.1  

 
## Version 0.4.1

Date range: 9/23/20 - 11/12/20

* PR template now automatically closes issue on merge
* Remove unnecessary require statement
* Reporting bugfix
* Working with reporting gem updates


## Version 0.4.0

Date range: 6/5/20 - 9/22/20

* Changes to support the new reporting gem
* Parsing additional results from the REopt Lite API: 
  - lcc_bau_us_dollars
  - year_one_energy_cost_bau_us_dollars
  - year_one_demand_cost_bau_us_dollars
  - year_one_bill_bau_us_dollars
  - total_energy_cost_bau_us_dollars
  - total_demand_cost_us_dollars
  - total_demand_cost_bau_us_dollars
* Makes separate calls to the REopt Lite API for new resilience statistics:
  - resilience_hours_min
  - resilience_hours_max
  - resilience_hours_avg
  - probs_of_surviving
  - probs_of_surviving_by_month
  - probs_of_surviving_by_hour_of_the_day


## Version 0.3.0

* Updating to support OpenStudio 3.0 and Ruby 2.5

## Version 0.2.1 
* Corrects code checking PV size that fails on multi PV
* Corrects parsing of site energy at timesteps other than 1 per hour


## Version 0.2.0 

* Handles multiple PV systems in the REopt Lite assumptions
* Changes REoptPostProcessor run_scenario and run_scenario_features methods to save feature and scenario reports with custom names
* Parses date from timeseries CSV when creating load profile for REopt job and when parsing optimized results
* Renames REopt timeseries CSV columns to include 'REopt' and units


## Version 0.1.0 

* Initial release of URBANopt REopt Gem. 
