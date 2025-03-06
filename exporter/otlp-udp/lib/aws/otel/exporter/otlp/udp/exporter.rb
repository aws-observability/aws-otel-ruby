# frozen_string_literal: true

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Modifications Copyright The OpenTelemetry Authors. Licensed under the Apache License 2.0 License.

require 'socket'
require 'base64'
require 'opentelemetry'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/sdk'

DEFAULT_ENDPOINT = 'localhost:2000'
PROTOCOL_HEADER = "{\"format\":\"json\",\"version\":1}\n"
DEFAULT_FORMAT_OTEL_TRACES_BINARY_PREFIX = 'T1S'

module AWS
  module OTel
    module Exporter
      module OTLP
        module UDP
          # Class that sends data over UDP.
          class UdpExporter
            def initialize(endpoint = nil)
              @endpoint = endpoint || DEFAULT_ENDPOINT
              @host, @port = parse_endpoint(@endpoint)
              @socket = UDPSocket.new
            end

            def send_data(data, signal_prefix)
              base64_encoded_string = Base64.strict_encode64(data)
              message = "#{PROTOCOL_HEADER}#{signal_prefix}#{base64_encoded_string}"

              begin
                @socket.send(message.encode('utf-8'), 0, @host, @port)
              rescue StandardError => e
                OpenTelemetry.logger.error("Error sending UDP data: #{e}")
                raise e
              end
            end

            def shutdown
              @socket.close
            end

            private

            def parse_endpoint(endpoint)
              host, port = endpoint.split(':')
              [host, port.to_i]
            rescue StandardError => _e
              raise "Invalid endpoint: #{endpoint}"
            end
          end

          # An OpenTelemetry trace exporter that sends spans over UDP.
          class OTLPUdpSpanExporter < OpenTelemetry::SDK::Trace::Export::SpanExporter # rubocop:disable Metrics/ClassLength
            SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
            FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
            private_constant(:SUCCESS, :FAILURE)

            def initialize(endpoint = nil, signal_prefix = DEFAULT_FORMAT_OTEL_TRACES_BINARY_PREFIX)
              @endpoint = if endpoint.nil?
                            if lambda_environment?
                              xray_daemon_endpoint || DEFAULT_ENDPOINT
                            else
                              DEFAULT_ENDPOINT
                            end
                          else
                            endpoint
                          end

              @udp_exporter = AWS::OTel::Exporter::OTLP::UDP::UdpExporter.new(@endpoint)
              @signal_prefix = signal_prefix
              @shutdown = false
            end

            # Called to export sampled {OpenTelemetry::SDK::Trace::SpanData} structs.
            #
            # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
            #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
            #   exported.
            # @param [optional Numeric] timeout An optional timeout in seconds.
            # @return [Integer] the result of the export.
            def export(span_data, timeout: nil)
              return FAILURE if @shutdown

              encoded_etsr = encode(span_data)
              return FAILURE if encoded_etsr.nil?

              begin
                @udp_exporter.send_data(encoded_etsr, @signal_prefix)
                SUCCESS
              rescue StandardError => e
                OpenTelemetry.logger.error("Error exporting spans: #{e}")
                FAILURE
              end
            end

            # Called when {OpenTelemetry::SDK::Trace::TracerProvider#force_flush} is called, if
            # this exporter is registered to a {OpenTelemetry::SDK::Trace::TracerProvider}
            # object.
            #
            # @param [optional Numeric] timeout An optional timeout in seconds.
            def force_flush(timeout: nil)
              SUCCESS
            end

            # Called when {OpenTelemetry::SDK::Trace::TracerProvider#shutdown} is called, if
            # this exporter is registered to a {OpenTelemetry::SDK::Trace::TracerProvider}
            # object.
            #
            # @param [optional Numeric] timeout An optional timeout in seconds.
            def shutdown(timeout: nil)
              @udp_exporter.shutdown
              @shutdown = true
              SUCCESS
            end

            private

            def lambda_environment?
              !ENV['AWS_LAMBDA_FUNCTION_NAME'].nil?
            end

            def xray_daemon_endpoint
              ENV['AWS_XRAY_DAEMON_ADDRESS']
            end

            # The OpenTelemetry Authors code
            # https://github.com/open-telemetry/opentelemetry-ruby/blob/opentelemetry-exporter-otlp/v0.30.0/exporter/otlp/lib/opentelemetry/exporter/otlp/exporter.rb#L277-L396
            def encode(span_data) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
              Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.encode(
                Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.new(
                  resource_spans: span_data
                    .group_by(&:resource)
                    .map do |resource, span_datas|
                      Opentelemetry::Proto::Trace::V1::ResourceSpans.new(
                        resource: Opentelemetry::Proto::Resource::V1::Resource.new(
                          attributes: resource.attribute_enumerator.map { |key, value| as_otlp_key_value(key, value) }
                        ),
                        scope_spans: span_datas
                          .group_by(&:instrumentation_scope)
                          .map do |il, sds|
                            Opentelemetry::Proto::Trace::V1::ScopeSpans.new(
                              scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(
                                name: il.name,
                                version: il.version
                              ),
                              spans: sds.map { |sd| as_otlp_span(sd) }
                            )
                          end
                      )
                    end
                )
              )
            rescue StandardError => e
              OpenTelemetry.handle_error(exception: e, message: 'unexpected error in OTLP::Exporter#encode')
              nil
            end

            def as_otlp_span(span_data) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
              Opentelemetry::Proto::Trace::V1::Span.new(
                trace_id: span_data.trace_id,
                span_id: span_data.span_id,
                trace_state: span_data.tracestate.to_s,
                parent_span_id: span_data.parent_span_id == OpenTelemetry::Trace::INVALID_SPAN_ID ? nil : span_data.parent_span_id,
                name: span_data.name,
                kind: as_otlp_span_kind(span_data.kind),
                start_time_unix_nano: span_data.start_timestamp,
                end_time_unix_nano: span_data.end_timestamp,
                attributes: span_data.attributes&.map { |k, v| as_otlp_key_value(k, v) },
                dropped_attributes_count: span_data.total_recorded_attributes - span_data.attributes&.size.to_i,
                events: span_data.events&.map do |event|
                  Opentelemetry::Proto::Trace::V1::Span::Event.new(
                    time_unix_nano: event.timestamp,
                    name: event.name,
                    attributes: event.attributes&.map { |k, v| as_otlp_key_value(k, v) }
                    # TODO: track dropped_attributes_count in Span#append_event
                  )
                end,
                dropped_events_count: span_data.total_recorded_events - span_data.events&.size.to_i,
                links: span_data.links&.map do |link|
                  Opentelemetry::Proto::Trace::V1::Span::Link.new(
                    trace_id: link.span_context.trace_id,
                    span_id: link.span_context.span_id,
                    trace_state: link.span_context.tracestate.to_s,
                    attributes: link.attributes&.map { |k, v| as_otlp_key_value(k, v) }
                    # TODO: track dropped_attributes_count in Span#trim_links
                  )
                end,
                dropped_links_count: span_data.total_recorded_links - span_data.links&.size.to_i,
                status: span_data.status&.yield_self do |status|
                  Opentelemetry::Proto::Trace::V1::Status.new(
                    code: as_otlp_status_code(status.code),
                    message: status.description
                  )
                end
              )
            end

            def as_otlp_status_code(code)
              case code
              when OpenTelemetry::Trace::Status::OK then Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_OK
              when OpenTelemetry::Trace::Status::ERROR then Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_ERROR
              else Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET
              end
            end

            def as_otlp_span_kind(kind)
              case kind
              when :internal then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_INTERNAL
              when :server then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_SERVER
              when :client then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_CLIENT
              when :producer then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_PRODUCER
              when :consumer then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_CONSUMER
              else Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_UNSPECIFIED
              end
            end

            def as_otlp_key_value(key, value)
              Opentelemetry::Proto::Common::V1::KeyValue.new(key: key, value: as_otlp_any_value(value))
            rescue Encoding::UndefinedConversionError => e
              encoded_value = value.encode('UTF-8', invalid: :replace, undef: :replace, replace: '�')
              OpenTelemetry.handle_error(exception: e, message: "encoding error for key #{key} and value #{encoded_value}")
              Opentelemetry::Proto::Common::V1::KeyValue.new(key: key, value: as_otlp_any_value('Encoding Error'))
            end

            def as_otlp_any_value(value)
              result = Opentelemetry::Proto::Common::V1::AnyValue.new
              case value
              when String
                result.string_value = value
              when Integer
                result.int_value = value
              when Float
                result.double_value = value
              when true, false
                result.bool_value = value
              when Array
                values = value.map { |element| as_otlp_any_value(element) }
                result.array_value = Opentelemetry::Proto::Common::V1::ArrayValue.new(values: values)
              end
              result
            end
            # END The OpenTelemetry Authors code
          end
        end
      end
    end
  end
end
