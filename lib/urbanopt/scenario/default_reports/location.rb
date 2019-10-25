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
      # Location include all location information.
      ##
      class Location
        attr_accessor :latitude, :longitude, :surface_elevation, :weather_filename #:nodoc:
        ##
        # Location class intialize location attributes: +:latitude+ , +:longitude+ , +:surface_elevation+ , +:weather_filename+
        ##
        # [parameters:]
        # +hash+ - _Hash_ - A hash which may contain a deserialized location.
        ##
        def initialize(hash = {})
          hash.delete_if { |k, v| v.nil? }
          hash = defaults.merge(hash)

          @latitude = hash[:latitude]
          @longitude = hash[:longitude]
          @surface_elevation = hash[:surface_elevation]
          @weather_filename = hash[:weather_filename]

          # initialize class variable @@extension only once
          @@extension ||= Extension.new
          @@schema ||= @@extension.schema
        end

        ##
        # Convert to a Hash equivalent for JSON serialization.
        ##
        # - Exclude attributes with nil values.
        # - Validate location hash properties against schema.
        ##
        def to_hash
          result = {}
          result[:latitude] = @latitude if @latitude
          result[:longitude] = @longitude if @longitude
          result[:surface_elevation] = @surface_elevation if @surface_elevation
          result[:weather_filename] = @weather_filename if @weather_filename

          # validate location properties against schema
          if @@extension.validate(@@schema[:definitions][:Location][:properties], result).any?
            raise "end_uses properties does not match schema: #{@@extension.validate(@@schema[:definitions][:Location][:properties], result)}"
          end

          return result
        end

        ##
        # Assign default values if values does not exist
        ##
        def defaults
          hash = {}
          hash[:latitude] = nil
          hash[:longitude] = nil
          hash[:surface_elevation] = nil
          hash[:weather_filename] = nil

          return hash
        end
      end
    end
  end
end
