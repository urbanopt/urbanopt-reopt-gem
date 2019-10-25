# URBANOpt REopt Gem

### <StaticLink href="rdoc/">Rdocs</StaticLink>

The URBANopt Scenario Gem includes functionality for defining scenarios, running simulations, and post-processing results.  An URBANopt Scenario describes a specific set of options to apply to each Feature in a FeatureFile (e.g. each GeoJSON Feature in an URBANopt GeoJSON File).  User defined SimulationMapper classes translate each Feature to a SimulationDir which is a directory containing simulation input files.  A ScenarioRunner is used to perform simulations for each SimulationDir.  Finally, a ScenarioPostProcessor can run on a Scenario to generate scenario level results.  The [URBANopt Scenario Gem Design Document](https://docs.google.com/document/d/1ExcGuHliaSvPlrYevAJTSV8XAtTQXz_KQqH3p4iQDwg/edit) describes the gem in more detail.  The [URBANopt Example Project](https://github.com/urbanopt/urbanopt-example-project) demonstrates how to use the URBANopt Scenario Gem to perform a scenario analysis.

[RDoc Documentation](https://urbanopt.github.io/urbanopt-reopt-gem/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'urbanopt-reopt'
```

And then execute:

    $ bundle install
    $ bundle update

Or install it yourself as:

    $ gem install 'urbanopt-scenario'

## Testing

Check out the repository and then execute:

    $ bundle install
    $ bundle update    
    $ bundle exec rake
    
## Releasing

* Update change log
* Update version in `/lib/urbanopt/scenario/version.rb`
* Merge down to master
* run `rake release` from master
