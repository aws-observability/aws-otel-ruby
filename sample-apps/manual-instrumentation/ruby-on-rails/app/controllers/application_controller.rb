def convert_otel_trace_id_to_xray(otel_trace_id_hex)
  xray_trace_id = "1-#{otel_trace_id_hex[0..7]}-#{otel_trace_id_hex[8..otel_trace_id_hex.length]}"
  { traceId: xray_trace_id }
end

#
# ApplicationController - Simple class of routes used to test OpenTelemetry.
#
class ApplicationController < ActionController::Base
  def aws_sdk_call
    s3 = Aws::S3::Client.new
    s3.list_buckets

    render json: convert_otel_trace_id_to_xray(OpenTelemetry::Trace.current_span.context.hex_trace_id)
  end

  def outgoing_http_call
    Faraday.get('https://aws.amazon.com/')

    render json: convert_otel_trace_id_to_xray(OpenTelemetry::Trace.current_span.context.hex_trace_id)
  end
end
