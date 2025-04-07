# frozen_string_literal: true

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

module AWS
  module Distro
    module OpenTelemetry
      module Exporter
        module XRay
          # UDP contains the implementation for the OTLP over UDP exporter
          module UDP
          end
        end
      end
    end
  end
end

require 'aws/distro/opentelemetry/exporter/xray/udp/exporter'
require 'aws/distro/opentelemetry/exporter/xray/udp/version'
