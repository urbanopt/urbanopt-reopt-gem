# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Energy Innovation, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************

require_relative 'spec_helper'

RSpec.describe 'URLConfig' do
  describe 'with default configuration' do
    let(:config) { URBANopt::REopt::URLConfig.new }
    
    it 'uses the new default URL' do
      expect(config.base_url).to eq('https://developer.nlr.gov/api/reopt/v3')
    end
    
    it 'generates correct submit URL' do
      config = URBANopt::REopt::URLConfig.new(api_key: 'test_key')
      uri = config.submit_uri
      expect(uri.to_s).to eq('https://developer.nlr.gov/api/reopt/v3/job?api_key=test_key')
    end
    
    it 'generates correct results URL' do
      config = URBANopt::REopt::URLConfig.new(api_key: 'test_key')
      uri = config.results_uri('test-uuid')
      expect(uri.to_s).to eq('https://developer.nlr.gov/api/reopt/v3/job/test-uuid/results?api_key=test_key')
    end
  end
  
  describe 'with environment variable override' do
    before { ENV['REOPT_BASE_URL'] = 'https://test.example.com/api/reopt/v3' }
    after { ENV.delete('REOPT_BASE_URL') }
    
    let(:config) { URBANopt::REopt::URLConfig.new }
    
    it 'uses environment variable URL' do
      expect(config.base_url).to eq('https://test.example.com/api/reopt/v3')
    end
    
    it 'generates correct URLs with env override (no API key needed)' do
      config = URBANopt::REopt::URLConfig.new(api_key: 'test_key')
      uri = config.submit_uri
      expect(uri.to_s).to eq('https://test.example.com/api/reopt/v3/job/')
    end
    
    it 'does not require API key for custom URLs' do
      config = URBANopt::REopt::URLConfig.new
      expect(config.requires_api_key?).to be false
      uri = config.submit_uri
      expect(uri.to_s).to eq('https://test.example.com/api/reopt/v3/job/')
    end
  end
  
  describe 'SSL configuration' do
    it 'enables SSL for HTTPS URLs' do
      config = URBANopt::REopt::URLConfig.new
      http = double('Net::HTTP')
      expect(http).to receive(:use_ssl=).with(true)
      config.configure_ssl(http)
    end
    
    it 'does not enable SSL for HTTP URLs' do
      ENV['REOPT_BASE_URL'] = 'http://localhost:8000/v3'
      config = URBANopt::REopt::URLConfig.new
      http = double('Net::HTTP')
      expect(http).not_to receive(:use_ssl=)
      config.configure_ssl(http)
      ENV.delete('REOPT_BASE_URL')
    end
  end
  
  describe 'API key requirements' do
    it 'requires API key for developer.nlr.gov' do
      config = URBANopt::REopt::URLConfig.new
      expect(config.requires_api_key?).to be true
    end
    
    it 'requires API key for developer.nlr.gov' do
      ENV['REOPT_BASE_URL'] = 'https://developer.nrel.gov/api/reopt/v3'
      config = URBANopt::REopt::URLConfig.new
      expect(config.requires_api_key?).to be true
      ENV.delete('REOPT_BASE_URL')
    end
    
    it 'does not require API key for custom URLs' do
      ENV['REOPT_BASE_URL'] = 'http://localhost:8000/v3'
      config = URBANopt::REopt::URLConfig.new
      expect(config.requires_api_key?).to be false
      ENV.delete('REOPT_BASE_URL')
    end
  end
end