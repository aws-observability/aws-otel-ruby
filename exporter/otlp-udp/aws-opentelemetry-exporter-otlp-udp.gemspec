# frozen_string_literal: true

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws/opentelemetry/exporter/otlp/udp/version'

Gem::Specification.new do |spec|
  spec.name        = 'aws-opentelemetry-exporter-otlp-udp'
  spec.version     = AWS::OpenTelemetry::Exporter::OTLP::UDP::VERSION
  spec.authors     = ['Amazon Web Services']

  spec.summary     = 'OTLP UDP exporter for the OpenTelemetry framework'
  spec.description = 'OTLP UDP exporter for the OpenTelemetry framework'
  spec.homepage    = 'https://github.com/aws-observability/aws-otel-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.1'

  spec.add_dependency 'base64'
  spec.add_dependency 'opentelemetry-api', '~> 1.1'
  spec.add_dependency 'opentelemetry-exporter-otlp', '~> 0.26.1'
  spec.add_dependency 'opentelemetry-sdk', '~> 1.2'

  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'faraday', '~> 0.13'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'opentelemetry-test-helpers'
  spec.add_development_dependency 'pry-byebug' unless RUBY_ENGINE == 'jruby'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop', '~> 1.65'
  spec.add_development_dependency 'simplecov', '~> 0.17'
  spec.add_development_dependency 'webmock', '~> 3.24'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yard-doctest', '~> 0.1.6'

  if spec.respond_to?(:metadata)
    spec.metadata['source_code_uri'] = 'https://github.com/aws-observability/aws-otel-ruby/tree/main/exporter/otlp-udp'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/aws-observability/aws-otel-ruby/issues'
  end
end
