# URBANOpt REopt Gem

### <StaticLink target="\_blank" href="rdoc/">Rdocs</StaticLink>

The **URBANopt REopt Gem** extends **URBANopt::Scenario::DefaultReports::ScenarioReport** and **URBANopt::Scenario::DefaultReports::FeatureReport** with the ability to derive cost-optimal distributed energy resource (DER) technology sizes and annual dispatch strageties via the <StaticLink target="\_blank" href="https://reopt.nrel.gov/tool">REopt Lite</StaticLink> decision support platform. 
REopt Lite is a technoeconomic model which leverages mixed integer linear programming to identify the cost-optimal sizing of solar PV, Wind, Storage and/or diesel generation given an electric load profile, a utility rate tariff and other technoeconomic parameters. See <StaticLink target="\_blank" href="https://developer.nrel.gov/docs/energy-optimization/reopt-v1/">https://developer.nrel.gov/docs/energy-optimization/reopt-v1/</StaticLink> for more detailed information on input parameters and default assumptions. 

<br><b>Note:</b> this module requires an API Key from the <StaticLink target='blank' href="https://developer.nrel.gov/">NREL Developer Network</StaticLink>.


(RDoc Documentation)[https://urbanopt.github.io/urbanopt-reopt-gem/]{:target='_blank'}

## Installation

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

Check out the repository and then execute:

    $ bundle install
    $ bundle update    
    $ bundle exec rake
    
## Releasing

* Update change log
* Update version in `/lib/urbanopt/reopt/version.rb`
* Merge down to master
* run `rake release` from master
