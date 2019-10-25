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

require 'csv'
require 'pathname'
require 'json-schema'
require 'urbanopt/scenario/default_reports/extension'
require 'urbanopt/scenario/default_reports/logger'


module URBANopt
  module Scenario
    module DefaultReports
      ##
      # TimeseriesCSV include timesries reults reported in a CSV file.
      ##
      class TimeseriesCSV
        attr_accessor :path, :first_report_datetime, :column_names #:nodoc:

        ##
        # TimeseriesCSV class initializes timeseries csv attributes: +:path+ , +:first_report_datetime+ , +:column_names+ 
        ##
        # +hash+ - _Hash_ - A hash which may contain a deserialized timeseries_csv.
        ##
        def initialize(hash = {})
          hash.delete_if { |k, v| v.nil? }
          hash = defaults.merge(hash)

          @run_dir = ''

          @path = hash[:path]
          @first_report_datetime = hash[:first_report_datetime]
          @column_names = hash[:column_names]

          # hash of column_name to array of values, does not get serialized to hash
          @mutex = Mutex.new
          @data = nil

          # initialize class variable @@extension only once
          @@extension ||= Extension.new
          @@schema ||= @@extension.schema
          
          # initialize @@logger
          @@logger ||= URBANopt::Scenario::DefaultReports.logger

        end

        ##
        # Assigns default values if values does not exist.
        ##
        def defaults
          hash = {}
          hash[:path] = nil
          hash[:column_names] = []
          return hash
        end

        ##
        # Gets run directory.
        ##
        # [parameters:]
        # +name+ - _String_ - The name of the scenario (+directory_name+).
        ##
        def run_dir_name(name)
          @run_dir = name
        end

        ##
        # Converts to a Hash equivalent for JSON serialization.
        ##
        # - Exclude attributes with nil values.
        # - Validate reporting_period hash properties against schema.
        ##
        def to_hash
          result = {}
          directory_path = Pathname.new File.expand_path(@run_dir.to_s, File.dirname(__FILE__)) if @run_dir
          csv_path = Pathname.new @path if @path

          relative_path = csv_path.to_s.sub(directory_path.to_s, '')

          result[:path] = relative_path if @path
          result[:first_report_datetime] = @first_report_datetime if @first_report_datetime
          result[:column_names] = @column_names if @column_names

          # validate timeseries_csv properties against schema
          if @@extension.validate(@@schema[:definitions][:TimeseriesCSV][:properties], result).any?
            raise "scenario_report properties does not match schema: #{@@extension.validate(@@schema[:definitions][:TimeseriesCSV][:properties], result)}"
          end

          return result
        end

        ##
        # Loads data from the CSV file.
        ##
        def load_data
          @mutex.synchronize do
            if @data.nil?
              @data = {}
              @column_names = []
              CSV.foreach(@path) do |row|
                if @column_names.empty?
                  @column_names = row
                  @column_names.each do |column_name|
                    @data[column_name] = []
                  end
                else
                  row.each_with_index do |value, i|
                    @data[@column_names[i]] << value.to_f
                  end
                end
              end
            end
          end
        end

        ##
        # Gets data for each column name in the CSV file.
        ##
        # [parameters:]
        # +column_name+ - _String_ - The header of each column in the CSV file.
        ##
        def get_data(column_name)
          load_data
          return @data[column_name]
        end

        ##
        # Saves data to the the scenario report CSV file.
        ##
        # [parameters:]
        # +path+ - _String_ - The path of the scenario report CSV (default_scenario_report.csv).
        ##
        def save_data(path)
          File.open(path, 'w') do |f|
            f.puts @column_names.join(',')
            n = @data[@column_names[0]].size

            (0..n).each do |i|
              line = []
              @column_names.each do |column_name|
                line << @data[column_name][i]
              end
              f.puts line.join(',')
            end
            begin
              f.fsync
            rescue StandardError
              f.flush
            end
          end
        end

        ##
        # Merges timeseries csv to each other.
        ##
        # - initialize first_report_datetime with the incoming first_report_datetime if its nil.
        # - checks if first_report_datetime are identical.
        # - merge the column names
        # - merge the column data
        ##
        # [parameters:]
        # +other+ - _TimeseriesCSV_ - An object of TimeseriesCSV class.
        ##
        def add_timeseries_csv(other)
          @path = other.path

          # initialize first_report_datetime with the incoming first_report_datetime if its nil.
          if @first_report_datetime.nil?
            @first_report_datetime = other.first_report_datetime
          end

          # checks if first_report_datetime are identical.
          if @first_report_datetime != other.first_report_datetime
            raise "first_report_datetime '#{@first_report_datetime}' does not match other.first_report_datetime '#{other.first_report_datetime}'"
          end

          # merge the column names
          @column_names = @column_names.concat(other.column_names).uniq

          # merge the column data
          other.column_names.each do |column_name|
            new_values = other.get_data(column_name)

            if @data.nil?
              @data = {}
            end

            current_values = @data[column_name]
            if current_values
              if current_values.size != new_values.size
                raise 'Values of different sizes in add_timeseries_csv'
              end
              new_values.each_with_index do |value, i|
                new_values[i] = value + current_values[i]
              end
              @data[column_name] = new_values
            else
              @data[column_name] = new_values
            end
          end
        end
      end
    end
  end
end
