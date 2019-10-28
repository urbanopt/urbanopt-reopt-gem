# Urbanopt Reopt Gem

The URBANopt REopt Gem extends URBANopt::Scenario::DefaultReports::ScenarioReport and URBANopt::Scenario::DefaultReports::FeatureReport with the ability to derive cost-optimal distributed energy resource (DER) technology sizes and annual dispatch strageties via the (REopt Lite)[https://reopt.nrel.gov/tool] decision support platform. 
REopt Lite is a technoeconomic model which leverages mixed integer linear programming to identify the cost-optimal sizing of solar PV, Wind, Storage and/or diesel generation given an electric load profile, a utility rate tariff, and other technoeconomic parameters. See https://developer.nrel.gov/docs/energy-optimization/reopt-v1/ for more detailed information on input parameters and default assumptions. 

<br><b>Note:</b> This module requires an API Key from the (NREL Developer Network)[https://developer.nrel.gov/].

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'urbanopt-reopt'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install 'urbanopt-reopt'

## Usage

To be filled out later. 

## TODO

- [ ] Remove measures from OpenStudio-Measures to standardize on this location
- [ ] Update measures to code standards
- [ ] Review and fill out the gemspec file with author and gem description

# Releasing

* Update change log
* Update version in `/lib/openstudio/urbanopt-reopt/version.rb`
* Merge down to master
* run `rake release` from master
