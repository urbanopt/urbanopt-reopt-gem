# URBANopt REopt Gem

## Version 0.5.1

Date range: 12/11/20 - 1/08/20

* Extend polling time for resilience results
* Do not error out if there are no resilience results


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
