# URBANopt REopt Gem
 
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
