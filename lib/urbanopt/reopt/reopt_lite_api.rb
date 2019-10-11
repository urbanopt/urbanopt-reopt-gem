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
require_relative '../../../developer_nrel_key'

module URBANopt
  module REopt
    class REoptLiteAPI
      def initialize(use_localhost=false)
        @use_localhost = use_localhost
        if @use_localhost
          @uri_submit = URI.parse("http//:127.0.0.1:8000/v1/job/")
        else
          if [nil,''].include? DEVELOPER_NREL_KEY
            raise 'A developer.nrel.gov API key is required. Please see https://developer.nrel.gov/signup/'
          end
          @nreldeveloperkey =  DEVELOPER_NREL_KEY
          @uri_submit = URI.parse("https://developer.nrel.gov/api/reopt/v1/job/?api_key=#{@nreldeveloperkey}")
        end
      end

      def uri_results(run_uuid)
        if @use_localhost
          return URI.parse("http://127.0.0.1:8000/v1/job/#{run_uuid}/results")
        end
        return URI.parse("https://developer.nrel.gov/api/reopt/v1/job/#{run_uuid}/results?api_key=#{@nreldeveloperkey}")
      end

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

        #puts response.body
        return true
      end

      def reopt_request(reopt_input, folder)

        description = reopt_input[:Scenario][:description]

        filename = "#{folder}/#{description}_reopt_response.json"

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

        if folder[-1] == '/'
          folder = folder.slice(0..-2)
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