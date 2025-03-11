# frozen_string_literal: true

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe AWS::OpenTelemetry::Exporter::OTLP::UDP::UdpExporter do
  let(:success) { OpenTelemetry::SDK::Trace::Export::SUCCESS }
  let(:endpoint) { 'localhost:3000' }
  let(:host) { 'localhost' }
  let(:port) { 3000 }
  let(:udp_exporter) { AWS::OpenTelemetry::Exporter::OTLP::UDP::UdpExporter.new(endpoint) }

  def test_parse_endpoint_correctly
    _(udp_exporter.instance_variable_get(:@endpoint)).must_equal(endpoint)
    _(udp_exporter.instance_variable_get(:@host)).must_equal(host)
    _(udp_exporter.instance_variable_get(:@port)).must_equal(port)
  end

  def test_send_udp_data_correctly
    data = [1, 2, 3].pack('C*')
    prefix = 'T1'
    encoded_data = "{\"format\":\"json\",\"version\":1}\nT1AQID"

    mock_socket = Minitest::Mock.new
    mock_socket.expect(:send, nil, [encoded_data, 0, host, port])

    UDPSocket.stub :new, mock_socket do
      exporter = AWS::OpenTelemetry::Exporter::OTLP::UDP::UdpExporter.new(endpoint)
      exporter.send_data(data, prefix)
    end

    mock_socket.verify
  end

  def test_exceptions_are_handled_and_reraised_when_sending_udp_data
    data = [1, 2, 3].pack('C*')
    prefix = 'T1'

    mock_socket = UDPSocket.new
    raises_exception = -> { raise ArgumentError 'test_exception' }
    mock_socket.stub :send, raises_exception do
      UDPSocket.stub :new, mock_socket do
        exporter = AWS::OpenTelemetry::Exporter::OTLP::UDP::UdpExporter.new(endpoint)
        assert_raises(ArgumentError) { exporter.send_data(data, prefix) }
      end
    end
  end

  def test_close_socket_on_shutdown
    mock_socket = Minitest::Mock.new
    mock_socket.expect(:close, nil, [])

    UDPSocket.stub :new, mock_socket do
      exporter = AWS::OpenTelemetry::Exporter::OTLP::UDP::UdpExporter.new(endpoint)
      exporter.shutdown
    end

    mock_socket.verify
  end

  def test_throw_when_provided_invalid_endpoint
    assert_raises(StandardError, 'Invalid endpoint: 123') do
      AWS::OpenTelemetry::Exporter::OTLP::UDP::UdpExporter.new(123)
    end
  end
end

describe AWS::OpenTelemetry::Exporter::OTLP::UDP::OTLPUdpSpanExporter do
  let(:success) { OpenTelemetry::SDK::Trace::Export::SUCCESS }
  let(:endpoint) { 'localhost:3001' }
  let(:otlp_udp_span_exporter) { AWS::OpenTelemetry::Exporter::OTLP::UDP::OTLPUdpSpanExporter.new(endpoint) }

  def test_export_spans_successfully
    prefix = 'T1'
    encoded_data = 'ABCDEF'

    mock_exporter = Minitest::Mock.new
    mock_exporter.expect(:send_data, [], [encoded_data, prefix])

    result = -1
    AWS::OpenTelemetry::Exporter::OTLP::UDP::UdpExporter.stub :new, mock_exporter do
      exporter = AWS::OpenTelemetry::Exporter::OTLP::UDP::OTLPUdpSpanExporter.new(endpoint, prefix)
      exporter.stub :encode, 'ABCDEF' do
        result = exporter.export([], timeout: 0)
      end
    end

    _(result).must_equal(success)
    mock_exporter.verify
  end

  def test_handle_serialization_failure
    prefix = 'T1'
    result = -1

    exporter = AWS::OpenTelemetry::Exporter::OTLP::UDP::OTLPUdpSpanExporter.new(endpoint, prefix)
    exporter.stub :encode, nil do
      result = exporter.export([], timeout: 0)
    end

    _(result).must_equal(OpenTelemetry::SDK::Trace::Export::FAILURE)
  end

  def test_handle_errors_during_export
    prefix = 'T1'
    raises_exception = -> { raise ArgumentError 'test_exception' }

    result = -1
    exporter = AWS::OpenTelemetry::Exporter::OTLP::UDP::OTLPUdpSpanExporter.new(endpoint, prefix)
    exporter.instance_variable_get(:@udp_exporter).stub :send_data, raises_exception do
      result = exporter.export([], timeout: 0)
    end

    _(result).must_equal(OpenTelemetry::SDK::Trace::Export::FAILURE)
  end

  def test_force_flush_without_error
    otlp_udp_span_exporter.force_flush
  end

  def test_shutdown_udp_exporter_successfully
    mock_exporter = Minitest::Mock.new
    mock_exporter.expect(:shutdown, nil, [])

    AWS::OpenTelemetry::Exporter::OTLP::UDP::UdpExporter.stub :new, mock_exporter do
      exporter = AWS::OpenTelemetry::Exporter::OTLP::UDP::OTLPUdpSpanExporter.new(endpoint)
      exporter.shutdown
    end

    mock_exporter.verify
  end

  def test_use_expected_environment_variables_to_configure_endpoint
    ENV['AWS_LAMBDA_FUNCTION_NAME'] = 'testFunctionName'
    ENV['AWS_XRAY_DAEMON_ADDRESS'] = 'someaddress:1234'

    exporter = AWS::OpenTelemetry::Exporter::OTLP::UDP::OTLPUdpSpanExporter.new
    _(exporter.instance_variable_get(:@endpoint)).must_equal('someaddress:1234')
    _(exporter.instance_variable_get(:@udp_exporter).instance_variable_get(:@host)).must_equal('someaddress')
    _(exporter.instance_variable_get(:@udp_exporter).instance_variable_get(:@port)).must_equal(1234)

    ENV.delete('AWS_XRAY_DAEMON_ADDRESS')
    ENV.delete('AWS_LAMBDA_FUNCTION_NAME')
  end
end
