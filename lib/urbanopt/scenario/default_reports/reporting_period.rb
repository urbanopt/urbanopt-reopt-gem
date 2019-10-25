# *********************************************************************************
# URBANopt, Copyright (c) 2019, Alliance for Sustainable Energy, LLC, and other
# contributors. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or other
# materials provided with the distribution.
#
# Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
# *********************************************************************************

require 'json'
require 'urbanopt/scenario/default_reports/end_uses'
require 'urbanopt/scenario/default_reports/end_use'
require 'urbanopt/scenario/default_reports/date'
require 'urbanopt/scenario/default_reports/extension'
require 'json-schema'

module URBANopt
  module Scenario
    module DefaultReports
      ##
      # ReportingPeriod includes all the results of a specific reporting period.
      ##
      class ReportingPeriod
        attr_accessor :id, :name, :multiplier, :start_date, :end_date, :month, :day_of_month, :year, :total_site_energy, :total_source_energy,
                      :net_site_energy, :net_source_energy, :net_utility_cost, :electricity, :natural_gas, :additional_fuel, :district_cooling,
                      :district_heating, :water, :electricity_produced, :end_uses, :energy_production, :photovoltaic, :utility_costs,
                      :fuel_type, :total_cost, :usage_cost, :demand_cost, :comfort_result, :time_setpoint_not_met_during_occupied_cooling,
                      :time_setpoint_not_met_during_occupied_heating, :time_setpoint_not_met_during_occupied_hours #:nodoc:
        # ReportingPeriod class intializes the reporting period attributes: 
        # +:id+ , +:name+ , +:multiplier+ , +:start_date+ , +:end_date+ , +:month+ , +:day_of_month+ , +:year+ , +:total_site_energy+ , +:total_source_energy+ ,
        # +:net_site_energy+ , +:net_source_energy+ , +:net_utility_cost+ , +:electricity+ , +:natural_gas+ , +:additional_fuel+ , +:district_cooling+ ,
        # +:district_heating+ , +:water+ , +:electricity_produced+ , +:end_uses+ , +:energy_production+ , +:photovoltaic+ , +:utility_costs+ ,
        # +:fuel_type+ , +:total_cost+ , +:usage_cost+ , +:demand_cost+ , +:comfort_result+ , +:time_setpoint_not_met_during_occupied_cooling+ ,
        # +:time_setpoint_not_met_during_occupied_heating+ , +:time_setpoint_not_met_during_occupied_hours+
        ##
        # [parameters:]
        # +hash+ - _Hash_ - A hash which may contain a deserialized reporting_period.
        ##
        def initialize(hash = {})
          hash.delete_if { |k, v| v.nil? }
          hash = defaults.merge(hash)

          @id = hash[:id]
          @name = hash[:name]
          @multiplier = hash[:multiplier]
          @start_date = Date.new(hash[:start_date])
          @end_date = Date.new(hash[:end_date])

          @total_site_energy = hash[:total_site_energy]
          @total_source_energy = hash[:total_source_energy]
          @net_site_energy = hash [:net_site_energy]
          @net_source_energy = hash [:net_source_energy]
          @net_utility_cost = hash [:net_utility_cost]
          @electricity = hash [:electricity]
          @natural_gas = hash [:natural_gas]
          @additional_fuel = hash [:additional_fuel]
          @district_cooling = hash [:district_cooling]
          @district_heating = hash[:district_heating]
          @water = hash[:water]
          @electricity_produced = hash[:electricity_produced]
          @end_uses = EndUses.new(hash[:end_uses])

          @energy_production = hash[:energy_production]

          @utility_costs = hash[:utility_costs]

          @comfort_result = hash[:comfort_result]

          # initialize class variable @@extension only once
          @@extension ||= Extension.new
          @@schema ||= @@extension.schema
        end

        ##
        # Assigns default values if values do not exist.
        ##
        def defaults
          hash = {}

          hash[:id] = nil
          hash[:name] = nil
          hash[:multiplier] = nil
          hash[:start_date] = Date.new.to_hash
          hash[:end_date] = Date.new.to_hash

          hash[:total_site_energy] = nil
          hash[:total_source_energy] = nil
          hash [:net_site_energy] = nil
          hash [:net_source_energy] = nil
          hash [:net_utility_cost] = nil
          hash [:electricity] = nil
          hash [:natural_gas] = nil
          hash [:additional_fuel] = nil
          hash [:district_cooling] = nil
          hash[:district_heating] = nil

          hash[:electricity_produced] = nil
          hash[:end_uses] = EndUses.new.to_hash
          hash[:energy_production] = { electricity_produced: { photovoltaic: nil } }
          hash[:utility_costs] = [{ fuel_type: nil, total_cost: nil, usage_cost: nil, demand_cost: nil }]
          hash[:comfort_result] = { time_setpoint_not_met_during_occupied_cooling: nil, time_setpoint_not_met_during_occupied_heating: nil, time_setpoint_not_met_during_occupied_hours: nil }

          return hash
        end

        ##
        # Converts to a Hash equivalent for JSON serialization.
        ##
        # - Exclude attributes with nil values.
        # - Validate reporting_period hash properties against schema.
        #
        def to_hash
          result = {}

          result[:id] = @id if @id
          result[:name] = @name if @name
          result[:multiplier] = @multiplier if @multiplier
          result[:start_date] = @start_date.to_hash if @start_date
          result[:end_date] = @end_date.to_hash if @end_date
          result[:total_site_energy] = @total_site_energy if @total_site_energy
          result[:total_source_energy] = @total_source_energy if @total_source_energy
          result[:net_site_energy] = @net_site_energy if @net_site_energy
          result[:net_source_energy] = @net_source_energy if @net_source_energy
          result[:net_utility_cost] = @net_utility_cost if @net_utility_cost
          result[:electricity] = @electricity if @electricity
          result[:natural_gas] = @natural_gas if @natural_gas
          result[:additional_fuel] = @additional_fuel if @additional_fuel
          result[:district_cooling] = @district_cooling if @district_cooling
          result[:district_heating] = @district_heating if @district_heating
          result[:water] = @water if @water
          result[:electricity_produced] = @electricity_produced if @electricity_produced
          result[:end_uses] = @end_uses.to_hash if @end_uses

          energy_production_hash = @energy_production if @energy_production
          energy_production_hash.delete_if { |k, v| v.nil? }
          energy_production_hash.each do |eph|
            eph.delete_if { |k, v| v.nil? }
          end

          result[:energy_production] = energy_production_hash if @energy_production

          if @utility_costs.any?
            result[:utility_costs] = @utility_costs
            @utility_costs.each do |uc|
              uc.delete_if { |k, v| v.nil? } if uc
            end
          end

          comfort_result_hash = @comfort_result if @comfort_result
          comfort_result_hash.delete_if { |k, v| v.nil? }
          result[:comfort_result] = comfort_result_hash if @comfort_result

          # validates +reporting_period+ properties against schema for reporting period.
          if @@extension.validate(@@schema[:definitions][:ReportingPeriod][:properties], result).any?
            raise "feature_report properties does not match schema: #{@@extension.validate(@@schema[:definitions][:ReportingPeriod][:properties], result)}"
          end

          return result
        end

        ##
        # Adds up +existing_value+ and +new_values+ if not nill.   
        ##
        # [parameter:]
        # +existing_value+ - _Float_ - A value corresponding to a ReportingPeriod attribute.
        ##
        # +new_value+ - _Float_ - A value corresponding to a ReportingPeriod attribute.
        ##
        def self.add_values(existing_value, new_value)
          if existing_value && new_value
            existing_value += new_value
          elsif new_value
            existing_value = new_value
          end
          return existing_value
        end

        ##
        # Merges an +existing_period+ with a +new_period+ if not nil.
        ##
        # [Parameters:]
        # +existing_period+ - _ReportingPeriod_ - An object of ReportingPeriod class.
        ##
        # +new_period+ - _ReportingPeriod_ - An object of ReportingPeriod class.
        ##
        # rubocop: disable Metrics/AbcSize
        def self.merge_reporting_period(existing_period, new_period)
          # modify the existing_period by summing up the results
          existing_period.total_site_energy = add_values(existing_period.total_site_energy, new_period.total_site_energy)
          existing_period.total_source_energy = add_values(existing_period.total_source_energy, new_period.total_source_energy)
          existing_period.net_source_energy = add_values(existing_period.net_source_energy, new_period.net_source_energy)
          existing_period.net_utility_cost = add_values(existing_period.net_utility_cost, new_period.net_utility_cost)
          existing_period.electricity = add_values(existing_period.electricity, new_period.electricity)
          existing_period.natural_gas = add_values(existing_period.natural_gas, new_period.natural_gas)
          existing_period.additional_fuel = add_values(existing_period.additional_fuel, new_period.additional_fuel)
          existing_period.district_cooling = add_values(existing_period.district_cooling, new_period.district_cooling)
          existing_period.district_heating = add_values(existing_period.district_heating, new_period.district_heating)
          existing_period.water = add_values(existing_period.water, new_period.water)
          existing_period.electricity_produced = add_values(existing_period.electricity_produced, new_period.electricity_produced)

          # merge end uses
          new_end_uses = new_period.end_uses
          existing_period.end_uses.merge_end_uses!(new_end_uses) if existing_period.end_uses

          if existing_period.energy_production
            if existing_period.energy_production[:electricity_produced]
              existing_period.energy_production[:electricity_produced][:photovoltaic] = add_values(existing_period.energy_production[:electricity_produced][:photovoltaic], new_period.energy_production[:electricity_produced][:photovoltaic])
            end
          end

          if existing_period.utility_costs

            existing_period.utility_costs.each_with_index do |item, i|
              existing_period.utility_costs[i][:fuel_type] = add_values(existing_period.utility_costs[i][:fuel_type], new_period.utility_costs[i][:fuel_type])
              existing_period.utility_costs[i][:total_cost] = add_values(existing_period.utility_costs[i][:total_cost], new_period.utility_costs[i][:total_cost])
              existing_period.utility_costs[i][:usage_cost] = add_values(existing_period.utility_costs[i][:usage_cost], new_period.utility_costs[i][:usage_cost])
              existing_period.utility_costs[i][:demand_cost] = add_values(existing_period.utility_costs[i][:demand_cost], new_period.utility_costs[i][:demand_cost])
            end

          end

          if existing_period.comfort_result
            existing_period.comfort_result[:time_setpoint_not_met_during_occupied_cooling] = add_values(existing_period.comfort_result[:time_setpoint_not_met_during_occupied_cooling], new_period.comfort_result[:time_setpoint_not_met_during_occupied_cooling])
            existing_period.comfort_result[:time_setpoint_not_met_during_occupied_heating] = add_values(existing_period.comfort_result[:time_setpoint_not_met_during_occupied_heating], new_period.comfort_result[:time_setpoint_not_met_during_occupied_heating])
            existing_period.comfort_result[:time_setpoint_not_met_during_occupied_hours] = add_values(existing_period.comfort_result[:time_setpoint_not_met_during_occupied_hours], new_period.comfort_result[:time_setpoint_not_met_during_occupied_hours])
          end

          return existing_period
        end
        # rubocop: enable Metrics/AbcSize # :nodoc:

        ##
        # Merges multiple reporting periods together.
        # - If +existing_periods+ and +new_periods+ ids are equal,  
        # modify the existing_periods by merging the new periods results
        # - If existing periods are empty, initialize with new_periods.
        # - Raise an error if the existing periods are not identical with new periods (cannot have different reporting period ids).
        ##
        # [parameters:]
        ##
        # +existing_periods+ - _Array_ - An array of ReportingPeriod objects. 
        ##
        # +new_periods+ - _Array_ - An array of ReportingPeriod objects.
        ##
        def self.merge_reporting_periods(existing_periods, new_periods)
          id_list_existing = []
          id_list_new = []
          id_list_existing = existing_periods.collect(&:id)
          id_list_new = new_periods.collect(&:id)

          if id_list_existing == id_list_new

            existing_periods.each_index do |index|
              # if +existing_periods+ and +new_periods+ ids are equal,  
              # modify the existing_periods by merging the new periods results
              existing_periods[index] = merge_reporting_period(existing_periods[index], new_periods[index])

            end

          elsif existing_periods.empty?

            # if existing periods are empty, initialize with new_periods
            # the = operator would link existing_periods and new_periods to the same object in memory
            # we want to initialize with a deep clone of new_periods
            existing_periods = Marshal.load(Marshal.dump(new_periods))

          else
            # raise an error if the existing periods are not identical with new periods (cannot have different reporting period ids)
            raise 'cannot merge different reporting periods'

          end

          return existing_periods
        end
      end
    end
  end
end
