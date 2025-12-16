require 'json'
require 'fileutils'

module URBANopt # :nodoc:
    module REopt # :nodoc:
        class REoptGHPResult

            def initialize
                @@logger ||= URBANopt::REopt.reopt_logger
            end

            def result_calculate(reopt_ghp_dir)
                reopt_output = File.join(reopt_ghp_dir, 'reopt_ghp_outputs')
                bau_outputs = []
                ghp_outputs = []

                # Collect all valid output files with building ID
                Dir.glob(File.join(reopt_output, '*_output.json')) do |file|
                    filename = File.basename(file)
                    parts = filename.split('_') # ["BAU", "building", "1", "output.json"]
                    next unless parts.length >= 4

                    scenario = parts[0] # "BAU", "GHP", etc.
                    building_id = parts[1..2].join('_') # "building_1"

                    if scenario == 'BAU'
                        bau_outputs << [file, building_id]
                    elsif ['GHP', 'GHX'].include?(scenario)
                        ghp_outputs << [file, building_id]
                    end
                end

                # Initialize grouped results
                lcc = {}
                lifecycle_capital_costs = {}
                initial_capital_costs = {}
                initial_capital_costs_after_incentives = {}
                lifecycle_elecbill_after_tax = {}
                npv = {}

                # Totals
                lcc_total_bau = 0
                lcc_total_ghp = 0
                lifecycle_capital_costs_total_bau = 0
                lifecycle_capital_costs_total_ghp = 0
                initial_capital_costs_total_bau = 0
                initial_capital_costs_total_ghp = 0
                initial_capital_costs_after_incentives_total_bau = 0
                initial_capital_costs_after_incentives_total_ghp = 0
                lifecycle_elecbill_after_tax_total_bau = 0
                lifecycle_elecbill_after_tax_total_ghp = 0
                npv_total_bau = 0
                npv_total_ghp = 0

                # Process BAU files
                bau_outputs.each do |file, building_id|
                    data = JSON.parse(File.read(file), symbolize_names: true)
                    financial = data.dig(:outputs, :Financial) || {}

                    lcc["lcc_bau_#{building_id}"] = financial[:lcc] || 0
                    lcc_total_bau += lcc["lcc_bau_#{building_id}"]

                    lifecycle_capital_costs["bau_#{building_id}"] = financial[:lifecycle_capital_costs] || 0
                    lifecycle_capital_costs_total_bau += lifecycle_capital_costs["bau_#{building_id}"]

                    initial_capital_costs["bau_#{building_id}"] = financial[:initial_capital_costs] || 0
                    initial_capital_costs_total_bau += initial_capital_costs["bau_#{building_id}"]

                    initial_capital_costs_after_incentives["bau_#{building_id}"] = financial[:initial_capital_costs_after_incentives] || 0
                    initial_capital_costs_after_incentives_total_bau += initial_capital_costs_after_incentives["bau_#{building_id}"]

                    lifecycle_elecbill_after_tax["bau_#{building_id}"] = financial[:lifecycle_elecbill_after_tax_bau] || 0
                    lifecycle_elecbill_after_tax_total_bau += lifecycle_elecbill_after_tax["bau_#{building_id}"]

                    npv["bau_#{building_id}"] = financial[:npv] || 0
                    npv_total_bau += npv["bau_#{building_id}"]
                end

                # Process GHP files
                ghp_outputs.each do |file, building_id|
                    data = JSON.parse(File.read(file), symbolize_names: true)
                    financial = data.dig(:outputs, :Financial) || {}

                    lcc["lcc_ghp_#{building_id}"] = financial[:lcc] || 0
                    lcc_total_ghp += lcc["lcc_ghp_#{building_id}"]

                    lifecycle_capital_costs["ghp_#{building_id}"] = financial[:lifecycle_capital_costs] || 0
                    lifecycle_capital_costs_total_ghp += lifecycle_capital_costs["ghp_#{building_id}"]

                    initial_capital_costs["ghp_#{building_id}"] = financial[:initial_capital_costs] || 0
                    initial_capital_costs_total_ghp += initial_capital_costs["ghp_#{building_id}"]

                    initial_capital_costs_after_incentives["ghp_#{building_id}"] = financial[:initial_capital_costs_after_incentives] || 0
                    initial_capital_costs_after_incentives_total_ghp += initial_capital_costs_after_incentives["ghp_#{building_id}"]

                    lifecycle_elecbill_after_tax["ghp_#{building_id}"] = financial[:lifecycle_elecbill_after_tax] || 0
                    lifecycle_elecbill_after_tax_total_ghp += lifecycle_elecbill_after_tax["ghp_#{building_id}"]

                    npv["ghp_#{building_id}"] = financial[:npv] || 0
                    npv_total_ghp += npv["ghp_#{building_id}"]
                end

                # Add totals and net values
                lcc["lcc_bau_total"] = lcc_total_bau
                lcc["lcc_ghp_total"] = lcc_total_ghp
                lcc["lcc_net"] = lcc_total_ghp - lcc_total_bau

                lifecycle_capital_costs["bau_total"] = lifecycle_capital_costs_total_bau
                lifecycle_capital_costs["ghp_total"] = lifecycle_capital_costs_total_ghp
                lifecycle_capital_costs["net"] = lifecycle_capital_costs_total_ghp - lifecycle_capital_costs_total_bau

                initial_capital_costs["bau_total"] = initial_capital_costs_total_bau
                initial_capital_costs["ghp_total"] = initial_capital_costs_total_ghp
                initial_capital_costs["net"] = initial_capital_costs_total_ghp - initial_capital_costs_total_bau

                initial_capital_costs_after_incentives["bau_total"] = initial_capital_costs_after_incentives_total_bau
                initial_capital_costs_after_incentives["ghp_total"] = initial_capital_costs_after_incentives_total_ghp
                initial_capital_costs_after_incentives["net"] = initial_capital_costs_after_incentives_total_ghp - initial_capital_costs_after_incentives_total_bau

                lifecycle_elecbill_after_tax["bau_total"] = lifecycle_elecbill_after_tax_total_bau
                lifecycle_elecbill_after_tax["ghp_total"] = lifecycle_elecbill_after_tax_total_ghp
                lifecycle_elecbill_after_tax["net"] = lifecycle_elecbill_after_tax_total_ghp - lifecycle_elecbill_after_tax_total_bau

                npv["bau_total"] = npv_total_bau
                npv["ghp_total"] = npv_total_ghp
                npv["net"] = npv_total_ghp - npv_total_bau

                # Final result structure
                result_data = {
                    lcc: lcc,
                    lifecycle_capital_cost: lifecycle_capital_costs,
                    initial_capital_costs: initial_capital_costs,
                    initial_capital_costs_after_incentives: initial_capital_costs_after_incentives,
                    lifecycle_elecbill_after_tax: lifecycle_elecbill_after_tax,
                    npv: npv
                }

                output_path = File.join(reopt_ghp_dir, "reopt_ghp_result_summary.json")
                File.open(output_path, "w") { |file| file.write(JSON.pretty_generate(result_data)) }
                puts "Wrote summary to #{output_path}"
            end

        end
    end
end
