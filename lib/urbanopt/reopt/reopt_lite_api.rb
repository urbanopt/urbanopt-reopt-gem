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

require "net/https"
require "openssl"
require "uri"
require 'uri'
require 'json'
require 'pry'
require 'securerandom'

module URBANopt # :nodoc:
  module REopt  # :nodoc:
    class REoptLiteAPI
      ##
      # \REoptLiteAPI manages submitting optimization tasks to the \REopt Lite API  and recieving results.
      # Results can either be sourced from the production \REopt Lite API with an API key from developer.nrel.gov, or from
      # a version running at localhost.
      ##
      #
      # [*parameters:*]
      #
      # * +use_localhost+ - _Bool_ - If this is true, requests will be sent to a version of the \REopt Lite API running on localhost. Default is false, such that the production version of \REopt Lite is accessed. 
      # * +nrel_developer_key+ - _String_ - API key used to access the \REopt Lite APi. Required only if localhost is false. Obtain from https://developer.nrel.gov/signup/
      ##
      def initialize(nrel_developer_key=nil, use_localhost=false)
        @use_localhost = use_localhost
        if @use_localhost
          @uri_submit = URI.parse("http//:127.0.0.1:8000/v1/job/")
        else
          if nrel_developer_key.nil?
            raise 'A developer.nrel.gov API key is required. Please see https://developer.nrel.gov/signup/'
          end
          @nrel_developer_key =  nrel_developer_key
          @uri_submit = URI.parse("https://developer.nrel.gov/api/reopt/v1/job/?api_key=#{@nrel_developer_key}")
        end
      end

      ##
      # URL of the results end point for a specific optimization task
      ##
      #
      # [*parameters:*]
      #
      # * +run_uuid+ - _String_ - Unique run_uuid obtained from the \REopt Lite job submittal URL for a specific optimization task.
      #
      # [*return:*] _URI_ - Returns URI object for use in calling the \REopt Lite results endpoint for a specifc optimization task.
      ##
      def uri_results(run_uuid) # :nodoc:
        if @use_localhost
          return URI.parse("http://127.0.0.1:8000/v1/job/#{run_uuid}/results")
        end
        return URI.parse("https://developer.nrel.gov/api/reopt/v1/job/#{run_uuid}/results?api_key=#{@nrel_developer_key}")
      end
      
      ##
      # Checks if a optimization task can be submitted to the \REopt Lite API
      ##
      #
      # [*parameters:*]
      #
      # * +data+ - _Hash_ - Default \REopt Lite formatted post containing at least all the required parameters.
      #
      # [*return:*] _Bool_ - Returns true if the post succeeeds. Otherwise returns false.
      ##
      def check_connection(data)
        header = {'Content-Type'=> 'application/json'}
        http = Net::HTTP.new(@uri_submit.host, @uri_submit.port)
        if !@use_localhost
          http.use_ssl = true
        end
        request = Net::HTTP::Post.new(@uri_submit, header)
        request.body = data.to_json

        # Send the request
        response = http.request(request)

        if !response.is_a?(Net::HTTPSuccess)
          raise "Check_connection Failed"
        end

        return true
      end
      
      ##
      # Completes a \REopt Lite optimization. From a formatted hash, an optimization task is submitted to the API. 
      # Results are polled at 5 second interval until they are ready or an error is returned from the API. Results
      # are written to disk.
      ##
      #
      # [*parameters:*]
      #
      # * +reopt_input+ - _Hash_ - \REopt Lite formatted post containing at least required parameters.
      # * +filename+ - _String_ - Path to file that will be created containing the full \REopt Lite response.
      #
      # [*return:*] _Bool_ - Returns true if the post succeeeds. Otherwise returns false.
      ##
      def reopt_request(reopt_input, filename)

        description = reopt_input[:Scenario][:description]

        p "Submitting #{description} to REopt Lite API"

        # Format the request
        header = {'Content-Type'=> 'application/json'}
        http = Net::HTTP.new(@uri_submit.host, @uri_submit.port)
        if !@use_localhost
          http.use_ssl = true
        end
        request = Net::HTTP::Post.new(@uri_submit, header)
        request.body = reopt_input.to_json

        # Send the request
        response = http.request(request)
        
        # Get UUID
        run_uuid = JSON.parse(response.body)['run_uuid']
        
        if File.directory? filename
          if run_uuid.nil?
            run_uuid = 'error'
          end
          if run_uuid.downcase.include? 'error'
            run_uuid = "error#{SecureRandom.uuid}"
          end
          filename = File.join(filename, "#{description}_#{run_uuid}.json")
          p "REopt results saved to #{filename}"
        end

        if response.code != '201'
          File.open(filename,"w") do |f|
            f.write(response.body)
          end
          raise "Error in REopt optimization post - see #{filename}"
        end
        
        # Poll results until ready or error occurs
        status = "Optimizing..."
        uri = self.uri_results(run_uuid)
        http = Net::HTTP.new(uri.host, uri.port)
        if !@use_localhost
          http.use_ssl = true
        end

        request = Net::HTTP::Get.new(uri.request_uri)
        
        while status == "Optimizing..."
          response = http.request(request)
          data = JSON.parse(response.body)
          status = data['outputs']['Scenario']['status']
          sleep 5
        end

        File.open(filename,"w") do |f|
          f.write(data.to_json)
        end

        if status == 'optimal'   
          return data
        end

        error_message = data['messages']['error']
        raise "Error from REopt API - #{error_message}"
      end
    end
  end
end