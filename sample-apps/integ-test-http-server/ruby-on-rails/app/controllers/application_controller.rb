#
# Converts from OTel hex Trace ID to X-Ray formatted hex trace ID. This is valid
# as long as we are using the `OpenTelemetry::Propagator::XRay::IDGenerator`
# in the rails initializer file.
#
# See more: `sample-apps/manual-instrumentation/ruby-on-rails/config/initializers/opentelemetry.rb`
#
# See more: https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-tracingheader
#
# @param [String] otel_trace_id_hex An OTel Trace ID String in hex format.
#
# @return [Hash] An X-Ray Trace ID with the version, timestamp component, and
# unique identifier compnent, all separated by the `-` delimiter.
#
def convert_otel_trace_id_to_xray(otel_trace_id_hex)
  xray_trace_id = "1-#{otel_trace_id_hex[0..7]}-#{otel_trace_id_hex[8..otel_trace_id_hex.length]}"
  { traceId: xray_trace_id }
end

#
# ApplicationController - Simple class of routes used to test OpenTelemetry.
#
class ApplicationController < ActionController::Base
  def test
    Faraday.get('https://aws.amazon.com/')
    puts "X-Ray Trace ID is: " + (convert_otel_trace_id_to_xray(OpenTelemetry::Trace.current_span.context.hex_trace_id))[:traceId]

    render html: (convert_otel_trace_id_to_xray(OpenTelemetry::Trace.current_span.context.hex_trace_id))[:traceId]
  end
end
