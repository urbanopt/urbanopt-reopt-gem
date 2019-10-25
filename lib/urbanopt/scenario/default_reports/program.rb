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

require 'urbanopt/scenario/default_reports/extension'
require 'json-schema'
require 'json'

module URBANopt
  module Scenario
    module DefaultReports
      ##
      # Program includes all building program related information.
      ##
      class Program
        attr_accessor :site_area, :floor_area, :conditioned_area, :unconditioned_area, :footprint_area, :maximum_roof_height,
                      :maximum_number_of_stories, :maximum_number_of_stories_above_ground, :parking_area, :number_of_parking_spaces,
                      :number_of_parking_spaces_charging, :parking_footprint_area, :maximum_parking_height, :maximum_number_of_parking_stories,
                      :maximum_number_of_parking_stories_above_ground, :number_of_residential_units, :building_types, :building_type, :maximum_occupancy,
                      :area, :window_area, :north_window_area, :south_window_area, :east_window_area, :west_window_area, :wall_area, :roof_area, :equipment_roof_area, 
                      :photovoltaic_roof_area, :available_roof_area, :total_roof_area, :orientation, :aspect_ratio # :nodoc:
        # Program class intialize building program attributes: +:site_area+ , +:floor_area+ , +:conditioned_area+ , +:unconditioned_area+ ,
        # +:footprint_area+ , +:maximum_roof_height, +:maximum_number_of_stories+ , +:maximum_number_of_stories_above_ground+ , +:parking_area+ ,
        # +:number_of_parking_spaces+ , +:number_of_parking_spaces_charging+ , +:parking_footprint_area+ , +:maximum_parking_height+ , +:maximum_number_of_parking_stories+ ,
        # +:maximum_number_of_parking_stories_above_ground+ , +:number_of_residential_units+ , +:building_types+ , +:building_type+ , +:maximum_occupancy+ ,
        # +:area+ , +:window_area+ , +:north_window_area+ , +:south_window_area+ , +:east_window_area+ , +:west_window_area+ , +:wall_area+ , +:roof_area+ ,
        # +:equipment_roof_area+ , +:photovoltaic_roof_area+ , +:available_roof_area+ , +:total_roof_area+ , +:orientation+ , +:aspect_ratio+ 
        ##
        # [parameters:]
        # +hash+ - _Hash_ - A hash which may contain a deserialized program.
        ##
        def initialize(hash = {})
          hash.delete_if { |k, v| v.nil? }
          hash = defaults.merge(hash)

          @site_area = hash[:site_area]
          @floor_area = hash[:floor_area]
          @conditioned_area = hash[:conditioned_area]
          @unconditioned_area = hash[:unconditioned_area]
          @footprint_area = hash[:footprint_area]
          @maximum_roof_height = hash[:maximum_roof_height]
          @maximum_number_of_stories = hash[:maximum_number_of_stories]
          @maximum_number_of_stories_above_ground = hash[:maximum_number_of_stories_above_ground]
          @parking_area = hash[:parking_area]
          @number_of_parking_spaces = hash[:number_of_parking_spaces]
          @number_of_parking_spaces_charging = hash[:number_of_parking_spaces_charging]
          @parking_footprint_area = hash[:parking_footprint_area]
          @maximum_parking_height = hash[:maximum_parking_height]
          @maximum_number_of_parking_stories = hash[:maximum_number_of_parking_stories]
          @maximum_number_of_parking_stories_above_ground = hash[:maximum_number_of_parking_stories_above_ground]
          @number_of_residential_units = hash[:number_of_residential_units]
          @building_types = hash[:building_types]
          @window_area = hash[:window_area]
          @wall_area = hash[:wall_area]
          @roof_area = hash[:roof_area]
          @orientation = hash[:orientation]
          @aspect_ratio = hash[:aspect_ratio]

          # initialize class variable @@extension only once
          @@extension ||= Extension.new
          @@schema ||= @@extension.schema
        end

        ##
        # Assigns default values if values do not exist.
        ##
        def defaults
          hash = {}
          hash[:site_area] = nil
          hash[:floor_area] = nil
          hash[:conditioned_area] = nil
          hash[:unconditioned_area] = nil
          hash[:footprint_area] = nil
          hash[:maximum_roof_height] = nil
          hash[:maximum_number_of_stories] = nil
          hash[:maximum_number_of_stories_above_ground] = nil
          hash[:parking_area] = nil
          hash[:number_of_parking_spaces] = nil
          hash[:number_of_parking_spaces_charging] = nil
          hash[:parking_footprint_area] = nil
          hash[:maximum_parking_height] = nil
          hash[:maximum_number_of_parking_stories] = nil
          hash[:maximum_number_of_parking_stories_above_ground] = nil
          hash[:number_of_residential_units] = nil
          hash[:building_types] = [{ building_type: nil, maximum_occupancy: nil, floor_area: nil }]
          hash[:window_area] = { north_window_area: nil, south_window_area: nil, east_window_area: nil, west_window_area: nil, total_window_area: nil }
          hash[:wall_area] = { north_wall_area: nil, south_wall_area: nil, east_wall_area: nil, west_wall_area: nil, total_wall_area: nil }
          hash[:roof_area] = { equipment_roof_area: nil, photovoltaic_roof_area: nil, available_roof_area: nil, total_roof_area: nil }
          hash[:orientation] = nil
          hash[:aspect_ratio] = nil
          return hash
        end

        ##
        # Convert to a Hash equivalent for JSON serialization.
        ##
        # - Exclude attributes with nil values.
        # - Validate program hash properties against schema.
        ##
        def to_hash
          result = {}
          result[:site_area] = @site_area if @site_area
          result[:floor_area] = @floor_area if @floor_area
          result[:conditioned_area] = @conditioned_area if @conditioned_area
          result[:unconditioned_area] = @unconditioned_area if @unconditioned_area
          result[:footprint_area] = @footprint_area if @footprint_area
          result[:maximum_roof_height] = @maximum_roof_height if @maximum_roof_height
          result[:maximum_number_of_stories] = @maximum_number_of_stories if @maximum_number_of_stories
          result[:maximum_number_of_stories_above_ground] = @maximum_number_of_stories_above_ground if @maximum_number_of_parking_stories_above_ground
          result[:parking_area] = @parking_area if @parking_area
          result[:number_of_parking_spaces] = @number_of_parking_spaces if @number_of_parking_spaces
          result[:number_of_parking_spaces_charging] = @number_of_parking_spaces_charging if @number_of_parking_spaces_charging
          result[:parking_footprint_area] = @parking_footprint_area if @parking_footprint_area
          result[:maximum_parking_height] = @maximum_parking_height if @maximum_parking_height
          result[:maximum_number_of_parking_stories] = @maximum_number_of_parking_stories if @maximum_number_of_parking_stories
          result[:maximum_number_of_parking_stories_above_ground] = @maximum_number_of_parking_stories_above_ground if @maximum_number_of_parking_stories_above_ground
          result[:number_of_residential_units] = @number_of_residential_units if @number_of_residential_units

          if @building_types.any?
            result[:building_types] = @building_types
            @building_types.each do |bt|
              bt.delete_if { |k, v| v.nil? } if bt
            end
          end

          # result[:window_area] = @window_area if @window_area
          window_area_hash = @window_area if @window_area
          window_area_hash.delete_if { |k, v| v.nil? }
          result[:window_area] = window_area_hash if @window_area

          # result[:wall_area] = @wall_area if @wall_area
          wall_area_hash = @wall_area if @wall_area
          wall_area_hash.delete_if { |k, v| v.nil? }
          result[:wall_area] = wall_area_hash if @wall_area

          # result[:roof_area] = @roof_area if @roof_area
          roof_area_hash = @roof_area if @roof_area
          roof_area_hash.delete_if { |k, v| v.nil? }
          result[:roof_area] = roof_area_hash if @roof_area

          result[:orientation] = @orientation if @orientation
          result[:aspect_ratio] = @aspect_ratio if @aspect_ratio

          # validate program properties against schema
          if @@extension.validate(@@schema[:definitions][:Program][:properties], result).any?
            raise "program properties does not match schema: #{@@extension.validate(@@schema[:definitions][:Program][:properties], result)}"
          end

          return result
        end

        ##
        # Return the maximum value from +existing_value+ and +new_value+.
        ##
        #[parameters:]
        # +existing_value+ - _Float_ - A value corresponding to a Program attribute.
        ##
        # +new_value+ - _Float_ - A value corresponding to a Program attribute.
        ##
        def max_value(existing_value, new_value)
          if existing_value && new_value
            [existing_value, new_value].max
          elsif new_value
            existing_value = new_value
          end
          return existing_value
        end

        ##
        # Adds up +existing_value+ and +new_values+ if not nill.   
        ##
        # [parameters:]
        # +existing_value+ - _Float_ - A value corresponding to a Program attribute.
        ##
        # +new_value+ - _Float_ - A value corresponding to a Program attribute.
        ##
        def add_values(existing_value, new_value)
          if existing_value && new_value
            existing_value += new_value
          elsif new_value
            existing_value = new_value
          end
          return existing_value
        end

        ##
        # Merges program objects to each other by summing up values or taking the maximum value of the attributes.
        ##
        # [parameters:]
        # +other+ - _Program_ - An object of Program class.
        ##
        # rubocop:disable Metrics/AbcSize # :nodoc:
        def add_program(other)
          @site_area = add_values(@site_area, other.site_area)

          @floor_area = add_values(@floor_area, other.floor_area)
          @conditioned_area = add_values(@conditioned_area, other.conditioned_area)
          @unconditioned_area = add_values(@unconditioned_area, other.unconditioned_area)
          @footprint_area = add_values(@footprint_area, other.footprint_area)
          @maximum_roof_height = max_value(@maximum_roof_height, other.maximum_roof_height)
          @maximum_number_of_stories = max_value(@maximum_number_of_stories, other.maximum_number_of_stories)
          @maximum_number_of_stories_above_ground = max_value(@maximum_number_of_stories_above_ground, other.maximum_number_of_stories_above_ground)
          @parking_area = add_values(@parking_area, other.parking_area)
          @number_of_parking_spaces = add_values(@number_of_parking_spaces, other.number_of_parking_spaces)
          @number_of_parking_spaces_charging = add_values(@number_of_parking_spaces_charging, other.number_of_parking_spaces_charging)
          @parking_footprint_area = add_values(@parkig_footprint_area, other.parking_footprint_area)
          @maximum_parking_height = max_value(@maximum_parking_height, other.maximum_parking_height)
          @maximum_number_of_parking_stories = max_value(@maximum_number_of_parking_stories, other.maximum_number_of_parking_stories)
          @maximum_number_of_parking_stories_above_ground = max_value(maximum_number_of_parking_stories_above_ground, other.maximum_number_of_parking_stories_above_ground)
          @number_of_residential_units = add_values(@number_of_residential_units, other.number_of_residential_units)

          @building_types = other.building_types

          @window_area[:north_window_area] = add_values(@window_area[:north_window_area], other.window_area[:north_window_area])
          @window_area[:south_window_area] = add_values(@window_area[:south_window_area], other.window_area[:south_window_area])
          @window_area[:east_window_area] = add_values(@window_area[:east_window_area], other.window_area[:east_window_area])
          @window_area[:west_window_area] = add_values(@window_area[:west_window_area], other.window_area[:west_window_area])
          @window_area[:total_window_area] =  add_values(@window_area[:total_window_area], other.window_area[:total_window_area])

          @wall_area[:north_wall_area] = add_values(@wall_area[:north_wall_area], other.wall_area[:north_wall_area])
          @wall_area[:south_wall_area] = add_values(@wall_area[:south_wall_area], other.wall_area[:south_wall_area])
          @wall_area[:east_wall_area] = add_values(@wall_area[:east_wall_area], other.wall_area[:east_wall_area])
          @wall_area[:west_wall_area] = add_values(@wall_area[:west_wall_area], other.wall_area[:west_wall_area])
          @wall_area[:total_wall_area] = add_values(@wall_area[:total_wall_area], other.wall_area[:total_wall_area])

          @roof_area[:equipment_roof_area] = add_values(@roof_area[:equipment_roof_area], other.roof_area[:equipment_roof_area])
          @roof_area[:photovoltaic_roof_area] = add_values(@roof_area[:photovoltaic_roof_area], other.roof_area[:photovoltaic_roof_area])
          @roof_area[:available_roof_area] = add_values(@roof_area[:available_roof_area], other.roof_area[:available_roof_area])
          @roof_area[:total_roof_area] = add_values(@roof_area[:total_roof_area], other.roof_area[:total_roof_area])
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
