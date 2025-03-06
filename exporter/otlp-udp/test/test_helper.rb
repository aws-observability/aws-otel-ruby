# frozen_string_literal: true

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

if RUBY_ENGINE == 'ruby'
  require 'simplecov'
  SimpleCov.start
end

require 'pry'

require 'opentelemetry-test-helpers'
require 'aws/otel/exporter/otlp/udp'
require 'minitest/autorun'
require 'webmock/minitest'

OpenTelemetry.logger = Logger.new(File::NULL)
