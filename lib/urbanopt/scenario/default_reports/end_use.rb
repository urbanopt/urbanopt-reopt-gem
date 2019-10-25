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

module URBANopt
  module Scenario
    module DefaultReports
      ##
      # Enduse class all enduse energy consumption results.
      ##
      class EndUse
        attr_accessor :heating, :cooling, :interior_lighting, :exterior_lighting, :interior_equipment, :exterior_equipment,
                      :fans, :pumps, :heat_rejection, :humidification, :heat_recovery, :water_systems, :refrigeration, :generators # :nodoc:

        ##
        # EndUse class intialize all enduse atributes: +:heating+ , +:cooling+ , +:interior_lighting+ ,
        # +:exterior_lighting+ , +:interior_equipment+ , +:exterior_equipment+ ,
        # +:fans+ , +:pumps+ , +:heat_rejection+ , +:humidification+ , +:heat_recovery+ , +:water_systems+ , +:refrigeration+ , +:generators+
        ##
        # [parameters:]
        # +hash+ - _Hash_ - A hash which may contain a deserialized end_use.
        ##
        def initialize(hash = {})
          hash.delete_if { |k, v| v.nil? }
          hash = defaults.merge(hash)

          @heating = hash[:heating]
          @cooling = hash[:cooling]
          @interior_lighting = hash[:interior_lighting]
          @exterior_lighting = hash[:exterior_lighting]
          @interior_equipment = hash[:interior_equipment]
          @exterior_equipment = hash[:exterior_equipment]
          @fans = hash[:fans]
          @pumps = hash[:pumps]
          @heat_rejection = hash[:heat_rejection]
          @humidification = hash[:humidification]
          @heat_recovery = hash[:heat_recovery]
          @water_systems = hash[:water_systems]
          @refrigeration = hash[:refrigeration]
          @generators = hash[:generators]

          # initialize class variable @@extension only once
          @@extension ||= Extension.new
          @@schema ||= @@extension.schema
        end

        ##
        # Assign default values if values does not exist
        ##
        def defaults
          hash = {}

          hash[:heating] = nil
          hash[:cooling] = nil
          hash[:interior_lighting] = nil
          hash[:exterior_lighting] = nil
          hash[:interior_equipment] = nil
          hash[:exterior_equipment] = nil
          hash[:fans] = nil
          hash[:pumps] = nil
          hash[:heat_rejection] = nil
          hash[:humidification] = nil
          hash[:heat_recovery] = nil
          hash[:water_systems] = nil
          hash[:refrigeration] = nil
          hash[:generators] = nil

          return hash
        end

        ##
        # Convert to a Hash equivalent for JSON serialization.
        ##
        # - Exclude attributes with nil values.
        # - Validate end_use hash properties against schema.
        ##
        def to_hash
          result = {}

          result[:heating] = @heating
          result[:cooling] = @cooling
          result[:interior_lighting] = @interior_lighting
          result[:exterior_lighting] = @exterior_lighting
          result[:interior_equipment] = @interior_equipment
          result[:exterior_equipment] = @exterior_equipment
          result[:fans] = @fans
          result[:pumps] = @pumps
          result[:heat_rejection] = @heat_rejection
          result[:humidification] = @humidification
          result[:heat_recovery] = @heat_recovery
          result[:water_systems] = @water_systems
          result[:refrigeration] = @refrigeration
          result[:generators] = @generators

          # validate end_use properties against schema
          if @@extension.validate(@@schema[:definitions][:EndUse][:properties], result).any?
            raise "end_use properties does not match schema: #{@@extension.validate(@@schema[:definitions][:EndUse][:properties], result)}"
          end

          return result
        end

        ##
        # Aggregate values of each EndUse attribute.
        ##
        # [Parameters:]
        # +new_end_use+ - _EndUse_ - An object of EndUse class.
        ##
        def merge_end_use!(new_end_use)
          @heating += new_end_use.heating if new_end_use.heating
          @cooling += new_end_use.cooling if new_end_use.cooling
          @interior_lighting += new_end_use.interior_lighting if new_end_use.interior_lighting
          @exterior_lighting += new_end_use.exterior_lighting if new_end_use.exterior_lighting
          @interior_equipment += new_end_use.interior_equipment if new_end_use.interior_equipment
          @exterior_equipment += new_end_use.exterior_equipment if new_end_use.exterior_equipment
          @fans += new_end_use.fans if new_end_use.fans
          @pumps += new_end_use.pumps if new_end_use.pumps
          @heat_rejection += new_end_use.heat_rejection if new_end_use.heat_rejection
          @humidification += new_end_use.humidification if new_end_use.humidification
          @heat_recovery += new_end_use.heat_recovery if new_end_use.heat_recovery
          @water_systems += new_end_use.water_systems if new_end_use.water_systems
          @refrigeration += new_end_use.refrigeration if new_end_use.refrigeration
          @generators += new_end_use.generators if new_end_use.generators

          return self
        end
      end
    end
  end
end
