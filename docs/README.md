# URBANOpt REopt Gem

### <StaticLink target="\_blank" href="rdoc/">Rdocs</StaticLink>

The **URBANopt REopt Gem** extends **URBANopt::Scenario::DefaultReports::ScenarioReport** and **URBANopt::Scenario::DefaultReports::FeatureReport** with the ability to derive cost-optimal distributed energy resource (DER) technology sizes and annual dispatch strageties via the <StaticLink target="\_blank" href="https://reopt.nrel.gov/tool">REopt Lite</StaticLink> decision support platform. 
REopt Lite is a technoeconomic model which leverages mixed integer linear programming to identify the cost-optimal sizing of solar PV, Wind, Storage and/or diesel generation given an electric load profile, a utility rate tariff and other technoeconomic parameters. See <StaticLink target="\_blank" href="https://developer.nrel.gov/docs/energy-optimization/reopt-v1/">https://developer.nrel.gov/docs/energy-optimization/reopt-v1/</StaticLink> for more detailed information on input parameters and default assumptions. 

<br><b>Note:</b> this module requires an API Key from the <StaticLink target='blank' href="https://developer.nrel.gov/">NREL Developer Network</StaticLink>.


(RDoc Documentation)[https://urbanopt.github.io/urbanopt-reopt-gem/]{:target='_blank'}

## Installation

See [https://docs.urbanopt.net/installation/installation.html](https://docs.urbanopt.net/installation/installation.html) for instructions on prerequiste software, including: 
- Ruby 2.2.6
- Bundler 1.17.0
- OpenStudio 2.8.1

Add this line to your application's Gemfile:

```ruby
gem 'urbanopt-reopt'
```

And then execute:

    $ bundle install
    $ bundle update

Or install it yourself as:

    $ gem install 'urbanopt-reopt'

## Testing

First, check out the repository (i.e. git clone this repo).

Next, obtain a developer.nrel.gov API key from the [NREL Developer Network](https://developer.nrel.gov/]). Copy and paste your key in to the _developer_nrel_key_._rb_ file then save the file:

    DEVELOPER_NREL_KEY = '<insert your key here>'

Finally, execute:

    $ bundle install
    $ bundle update    
    $ bundle exec rake


## Functionality

This gem is used to call the REopt Lite API on a Scenario Report or Feature Report to update the object's Distributed Generation attributes (including system financial and sizing metrics). Moreover, the following optimal dispatch fields are added to its timeseries CSV. Where no system component is recommended the dispatch will be all zero (i.e. if no solar PV is recommended ElectricityProduced:PV:Total will be always be zero)

|            output                        |  unit   |
| -----------------------------------------| ------- |
| ElectricityProduced:Total                | kWh     |
| Electricity:Load:Total                   | kWh     |
| Electricity:Grid:ToLoad                  | kWh     |
| Electricity:Grid:ToBattery               | kWh     |
| Electricity:Storage:ToLoad               | kWh     |
| Electricity:Storage:ToGrid               | kWh     |
| Electricity:Storage:StateOfCharge        | kWh     |
| ElectricityProduced:Generator:Total      | kWh     |
| ElectricityProduced:Generator:ToBattery  | kWh     |
| ElectricityProduced:Generator:ToLoad     | kWh     |
| ElectricityProduced:Generator:ToGrid     | kWh     |
| ElectricityProduced:PV:Total             | kWh     |
| ElectricityProduced:PV:ToBattery         | kWh     |
| ElectricityProduced:PV:ToLoad            | kWh     |
| ElectricityProduced:PV:ToGrid            | kWh     |
| ElectricityProduced:Wind:Total           | kWh     |
| ElectricityProduced:Wind:ToBattery       | kWh     |
| ElectricityProduced:Wind:ToLoad          | kWh     |
| ElectricityProduced:Wind:ToGrid          | kWh     |
    
## Releasing

* Update change log
* Update version in `/lib/urbanopt/reopt/version.rb`
* Merge down to master
* run `rake release` from master
