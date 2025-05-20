# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************

module URBANopt # :nodoc:
    module REopt # :nodoc:
      class REoptGHPResult

        def initialize
            # initialize @@logger
            @@logger ||= URBANopt::REopt.reopt_logger
        end

        def result_calculate(reopt_ghp_dir)
            bau_output_dict = {}
            ghp_output_dict = {}
            reopt_output = File.join(reopt_ghp_dir, 'reopt_ghp_outputs')
            bau_outputs = []
            ghp_outputs = []
            Dir.glob(File.join(reopt_output, '*')) do |file|
                next unless File.file?(file)

                prefix = File.basename(file).split('_').first
                bau_outputs << file if prefix == 'BAU'
                ghp_outputs << file if prefix == 'GHP'
                ghp_outputs << file if prefix == 'GHX'
            end

            lcc_bau = 0
            lcc_ghp = 0
            lcc_net = 0
            lifecycle_capital_costs_bau = 0
            lifecycle_capital_costs_ghp = 0
            lifecycle_capital_costs_net = 0
            initial_capital_costs_bau = 0
            initial_capital_costs_ghp = 0
            initial_capital_costs_net = 0
            lifecycle_elecbill_after_tax_bau = 0
            lifecycle_elecbill_after_tax_ghp = 0
            lifecycle_elecbill_after_tax_net = 0
            npv_bau = 0
            npv_ghp = 0
            npv_net = 0
            unless bau_outputs.empty?
                bau_outputs.each do |file|
                    bau_file = JSON.parse(File.read(file), symbolize_names: true)
                    lcc = bau_file[:outputs][:Financial][:lcc]
                    lcc_bau += lcc
                    lifecycle_capital_costs = bau_file[:outputs][:Financial][:lifecycle_capital_costs]
                    lifecycle_capital_costs_bau += lifecycle_capital_costs
                    lifecycle_elecbill_after_tax = bau_file[:outputs][:Financial][:lifecycle_elecbill_after_tax_bau]
                    lifecycle_elecbill_after_tax_bau += lifecycle_elecbill_after_tax
                    npv = bau_file[:outputs][:Financial][:npv]
                    npv_bau += npv
                end
            end
            unless ghp_outputs.empty?
                ghp_outputs.each do |file|
                    ghp_file = JSON.parse(File.read(file), symbolize_names: true)
                    lcc = ghp_file[:outputs][:Financial][:lcc]
                    lcc_ghp += lcc
                    lifecycle_capital_costs = ghp_file[:outputs][:Financial][:lifecycle_capital_costs]
                    lifecycle_capital_costs_ghp += lifecycle_capital_costs
                    lifecycle_elecbill_after_tax = ghp_file[:outputs][:Financial][:lifecycle_elecbill_after_tax]
                    lifecycle_elecbill_after_tax_ghp += lifecycle_elecbill_after_tax || 0
                    npv = ghp_file[:outputs][:Financial][:npv]
                    npv_ghp += npv
                end
            end

            # Calculations for net costs
            lcc_net = lcc_ghp - lcc_bau
            initial_capital_costs_net = initial_capital_costs_ghp - initial_capital_costs_bau
            lifecycle_elecbill_after_tax_net = lifecycle_elecbill_after_tax_ghp - lifecycle_elecbill_after_tax_bau
            npv_net = npv_ghp - npv_bau
            lifecycle_capital_costs_net = lifecycle_capital_costs_ghp - lifecycle_capital_costs_bau

            result_data = {"lcc_bau": lcc_bau, "lcc_ghp": lcc_ghp, "lcc_net": lcc_net,  "lifecycle_capital_costs_bau": lifecycle_capital_costs_bau, "lifecycle_capital_costs_ghp": lifecycle_capital_costs_ghp, "lifecycle_capital_costs_net": lifecycle_capital_costs_net, "lifecycle_elecbill_after_tax_bau": lifecycle_elecbill_after_tax_bau, "lifecycle_elecbill_after_tax_ghp": lifecycle_elecbill_after_tax_ghp, "lifecycle_elecbill_after_tax_net": lifecycle_elecbill_after_tax_net, "npv_bau": npv_bau, "npv_ghp": npv_ghp, "npv_net": npv_net}
            # Write the JSON string to a file
            File.open(File.join(reopt_ghp_dir, "reopt_ghp_result_summary.json"), "w") do |file|
                file.write(JSON.pretty_generate(result_data))
            end
  
         end

      end
    end
end
