# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2019, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

require "urbanopt/scenario/default_reports"
require 'csv'
require 'pry'

module URBANopt
  module REopt
    class FeatureReportAdapter
    
      def initialize

      end
      
      def from_feature_report(feature_report)
      
        return {:Scenario => 
                  {:Site => 
                    {:latitude => 40, :longitude => -110,
                      :ElectricTariff => {:urdb_label => '594976725457a37b1175d089'}, 
                      :LoadProfile => {:doe_reference_name => 'Hospital', :annual_kwh => 1000000 }
                    }
                  }
                }

        reopt_inputs = {:Scenario => {:Site => {:ElectricTariff => {}, :LoadProfile => {}}}}
        
        requireds_names = ['latitude','longitude']
        requireds = [feature_report.location[:latitude],feature_report.location[:longitude]]

        if requireds.include? nil or requireds.include? 0
          requireds.each_with_index do |i,x|
             if [nil,0].include? x
              n = requireds_names[i]
              raise "Missing value for #{n} - this is a required input"
             end
          end
        end
        
        reopt_inputs[:Scenario][:Site][:latitude] = feature_report.location[:latitude]
        reopt_inputs[:Scenario][:Site][:longitude] = feature_report.location[:longitude]
        reopt_inputs[:Scenario][:Site][:roof_squarefeet] = feature_report.program.roof_area[:available_roof_area]
        reopt_inputs[:Scenario][:Site][:land_acres] = feature_report.program.site_area
      


        # CSV.read(scenario_report[:timeseries_csv][:path],headers: true)
        # table.by_col[0]

        # scenario_report[:timesteps_per_hour]

        

        

        # reopt_inputs[:Scenario][:Site][:LoadProfile][:loads_kw] = 



        # = scenario_report[:program][:orientation]
        # = scenario_report[:program][:aspect_ratio]
        
        # = scenario_report[:reporting_periods][:electricity]
          # return a reopt_input
        return reopt_inputs
      end
      
      def to_feature_report(reopt_output)
        featureReport = URBANopt::Scenario::DefaultReports::FeatureReport.new({})

        featureReport.location[:latitude] =   reopt_output['inputs']['Scenario']['Site']['latitude']
        featureReport.location[:longitude] =   reopt_output['inputs']['Scenario']['Site']['longitude']

        return featureReport
      end

    end
  end
end