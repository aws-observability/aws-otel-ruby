require 'opentelemetry/sdk'

udp_trace_exporter = AWS::OpenTelemetry::Exporter::OTLP::UDP::OTLPUdpSpanExporter.new("127.0.0.1:2000")

# Create a simple span processor with custom configuration
simple_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
  udp_trace_exporter
)

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor(simple_processor)

  c.service_name = 'aws-otel-manual-rails-sample'

  c.id_generator = OpenTelemetry::Propagator::XRay::IDGenerator
  c.propagators = [OpenTelemetry::Propagator::XRay::TextMapPropagator.new]

  c.use 'OpenTelemetry::Instrumentation::AwsSdk', {
    suppress_internal_instrumentation: true
  }

  c.use 'OpenTelemetry::Instrumentation::Rails'
  c.use 'OpenTelemetry::Instrumentation::Rack'
  c.use 'OpenTelemetry::Instrumentation::ActionPack'
  c.use 'OpenTelemetry::Instrumentation::ActiveSupport'
  c.use 'OpenTelemetry::Instrumentation::ActionView'
  # c.use 'OpenTelemetry::Instrumentation::ActiveRecord'

  c.use 'OpenTelemetry::Instrumentation::Faraday'

  # Alternatively, we could just enable all instrumentation:
  # c.use_all({ 'OpenTelemetry::Instrumentation::ActiveRecord' => { enabled: false } })
end
