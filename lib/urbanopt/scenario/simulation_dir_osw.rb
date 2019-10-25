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

require 'urbanopt/scenario/simulation_dir_base'

module URBANopt
  module Scenario
    class SimulationDirOSW < SimulationDirBase
      ##
      # SimulationDirOSW creates a OSW file to simulate features, a SimulationMapperBase is invoked to translate features to OSW. 
      ##
      # [parameters:]
      # +scenario+ - _ScenarioBase_ - Scenario containing this SimulationFileBase.   
      # +features+ - _Array_ - Array of Features this SimulationFile represents.   
      # +feature_names+ - _Array_ - Array of scenario specific names for these Features.   
      # +mapper_class+ - _String_ - Name of class derived frmo SimulationMapperBase used to translate feature to simulation OSW.   
      def initialize(scenario, features, feature_names, mapper_class)
        super(scenario, features, feature_names)

        if features.size != 1
          raise 'SimulationDirOSW currently cannot simulate more than one feature'
        end

        @feature = features[0]
        @feature_id = @feature.id

        if feature_names.size == 1
          @feature_name = feature_names[0]
        else
          @feature_name = @feature.name
        end

        @mapper_class = mapper_class
      end

      attr_reader :mapper_class

      ##
      # Return the directory that this simulation will run in.
      ##
      def run_dir
        raise 'Feature ID not set' if @feature_id.nil?
        raise 'Scenario run dir not set' if scenario.run_dir.nil?
        return File.join(scenario.run_dir, @feature_id + '/')
      end

      ##
      # Return the input OSW path
      ##
      def in_osw_path
        return File.join(run_dir, 'in.osw')
      end

      ##
      # Return the input OSW
      ##
      def in_osw
        result = nil
        if File.exist?(in_osw_path)
          File.open(in_osw_path, 'r') do |f|
            result = JSON.parse(f.read, symbolize_names: true)
          end
        end
        return result
      end

      ##
      # Return the started.job path
      ##
      def started_job_path
        return File.join(run_dir, 'started.job')
      end

      ##
      # Return the failed.job path
      ##
      def failed_job_path
        return File.join(run_dir, 'failed.job')
      end

      ##
      # Return the finished.job path
      ##
      def finished_job_path
        return File.join(run_dir, 'finished.job')
      end

      ##
      # Return the output OSW path
      ##
      def out_osw_path
        return File.join(run_dir, 'out.osw')
      end

      ##
      # Return the output OSW
      ##
      def out_osw
        result = nil
        if File.exist?(out_osw_path)
          File.open(out_osw_path, 'r') do |f|
            result = JSON.parse(f.read, symbolize_names: true)
          end
        end
        return result
      end

      # rubocop: disable Metrics/AbcSize #:nodoc:
      
      ##
      # Return true if the simulation is out of date (input files newer than results), false otherwise.
      # Non-existant simulation input files are out of date.
      ##
      def out_of_date?
        if !File.exist?(run_dir)
          puts "run_dir '#{run_dir}' does not exist, simulation dir '#{run_dir}' out of date"
          return true
        end

        if !File.exist?(finished_job_path)
          puts "finished_job_path '#{finished_job_path}' does not exist, simulation dir '#{run_dir}' out of date"
          return true
        end

        if !File.exist?(out_osw_path)
          puts "out_osw_path '#{out_osw_path}' does not exist, simulation dir '#{run_dir}' out of date"
          return true
        end
        out_osw_time = File.mtime(out_osw_path)

        # array of files that this simulation dir depends on
        dependencies = []
        out_of_date_files = []

        # depends on the in.osw
        dependencies << in_osw_path

        # depends on the feature file
        dependencies << scenario.feature_file.path

        # depends on the csv file
        dependencies << scenario.csv_file

        # depends on the mapper classes
        Dir.glob(File.join(scenario.mapper_files_dir, '*')).each do |f|
          dependencies << f
        end

        # depends on the root gemfile
        dependencies << File.join(scenario.root_dir, 'Gemfile')
        dependencies << File.join(scenario.root_dir, 'Gemfile.lock')

        # todo, read in the in.osw and depend on all the measures

        # check if out of date
        dependencies.each do |f|
          if File.exist?(f)
            if File.mtime(f) > out_osw_time
              out_of_date_files << f
            end
          else
            puts "Dependency file '#{f}' does not exist"
          end
        end

        if !out_of_date_files.empty?
          puts "Files [#{out_of_date_files.join(',')}] are newer than '#{out_osw_path}', simulation dir '#{run_dir}' out of date"
          return true
        end

        return false
      end
      # rubocop: enable Metrics/AbcSize #:nodoc:

      # rubocop: disable Style/GuardClause #:nodoc:

      ##
      # Return simulation status one of {'Not Started', 'Started', 'Complete', 'Failed'}
      ##
      def simulation_status
        if File.exist?(failed_job_path)
          return 'Failed'
        elsif File.exist?(started_job_path)
          if File.exist?(finished_job_path)
            return 'Complete'
          else
            return 'Failed'
          end
        end

        return 'Not Started'
      end
      # rubocop: enable Style/GuardClause #:nodoc:

      ##
      # Clear the directory that this simulation runs in
      ##
      def clear
        dir = run_dir
        FileUtils.mkdir_p(dir) if !File.exist?(dir)
        Dir.glob(File.join(dir, '/*')).each do |f|
          FileUtils.rm_rf(f)
        end
      end

      # rubocop: disable Security/Eval #:nodoc:
      # rubocop: disable Style/EvalWithLocation #:nodoc:

      ##
      # Create run directory and generate simulation OSW, all previous contents of directory are removed
      # The simulation OSW is created by evaluating the mapper_class's create_osw method
      ##
      def create_input_files
        clear

        dir = run_dir
        osw = eval("#{@mapper_class}.new.create_osw(scenario, features, feature_names)")
        osw_path = File.join(dir, 'in.osw')
        
        File.open(osw_path, 'w') do |f|
          f << JSON.pretty_generate(osw)
          # make sure data is written to the disk one way or the other
          begin
            f.fsync
          rescue StandardError
            f.flush
          end
        end
        return osw_path
      end
      # rubocop: enable Security/Eval #:nodoc:
      # rubocop: enable Style/EvalWithLocation #:nodoc:
    end
  end
end
