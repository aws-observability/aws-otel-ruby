# AWS Distro for OpenTelemetry Ruby - Sample App - Manual instrumentation - Ruby on Rails

This application validates the continual integration of manual instrumentation with the AWS Distro for OpenTelemetry Ruby and the AWS X-Ray back-end service. Validation is done using the [AWS Test Framework for OpenTelemetry](https://github.com/aws-observability/aws-otel-test-framework).

## Application interface

The application uses [Ruby on Rails](https://rubyonrails.org) to expose the following routes:
1. `/`
    - Ensures the application is running.
2. `/outgoing-http-call`
    - Makes a HTTP request to `aws.amazon.com`.
3. `/aws-sdk-call`
    - Makes a call to AWS S3 to list buckets for the account corresponding to the provided AWS credentials.


## Requirements

- Ruby 2.7+
- Rails 7.0+

While this example requires Ruby 2.7+, [the OpenTelemetry Ruby documentation](https://opentelemetry.io/docs/instrumentation/ruby/getting_started/#requirements) indicates compatibility with versions of Ruby 2.5 and higher.

## Running the application

For more information on running a ruby application using manual instrumentation, please refer to the [ADOT Ruby Manual Instrumentation Documentation](https://aws-otel.github.io/docs/getting-started/ruby-sdk/trace-manual-instr). In this context, the ADOT Collector is being run locally as a sidecar.

Use `LISTEN_ADDRESS=127.0.0.1:8080 rails server` to run the application directly in your terminal.

Sending metrics to Amazon CloudWatch is not yet validated. Check out the [OpenTelemetry Features Status Page](https://opentelemetry.io/status/) to learn more about timelines for metrics.

## Application structure

Although this app was created with the `ruby new ruby-on-rails --minimal` command, it has been even further stripped down to focus on the OpenTelemetry changes needed to get tracing in this ruby on rails app.

The changes needed to trace with OpenTelemetry are found in [sample-apps/manual-instrumentation/ruby-on-rails/config/initializers/opentelemetry.rb](sample-apps/manual-instrumentation/ruby-on-rails/config/initializers/opentelemetry.rb).
