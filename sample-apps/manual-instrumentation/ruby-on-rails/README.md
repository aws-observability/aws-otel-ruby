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

This section describes the decisions made when designing the sample apps instrumented with ADOT Ruby.

### A minimal app

Although this app was created with the `rails new ruby-on-rails --minimal` command, it has been even further stripped down to focus on the OpenTelemetry changes needed to get tracing in this ruby on rails app.

The changes needed to trace with OpenTelemetry are found in [sample-apps/manual-instrumentation/ruby-on-rails/config/initializers/opentelemetry.rb](sample-apps/manual-instrumentation/ruby-on-rails/config/initializers/opentelemetry.rb).

### Running the app in `production` for tests

We build our application for a `production` environment because of https://github.com/aws-observability/aws-otel-ruby/pull/10.

However, to allow for a `production` environment, the rails app requires a "secret_base_key". Otherwise it will flood the log output with warnings thereby hiding useful logs.

To solve this, we added **dummy credentials** which don't do anything. Because this is an example, **we directly commit the security credentials in the Dockerfile** but this is **NOT GOOD PRACTICE FOR REAL PRODUCTION ENVIRONMENTS**. We allow it to be like this because we want this demo to work out-of-the-box for any public user.

You can confirm the credentials work and view the encrypted contents of the sample app by doing the following command:

```bash
$ cd sample-apps/manual-instrumentation/ruby-on-rails
$ RAILS_MASTER_KEY=<KEY_IN_SAMPLE-APP_DOCKERFILE> bin/rails credentials:edit
```

This will show the following contents:

```yaml
# NOTE: DO NOT USE THIS IN PRODUCTION ENVIRONMENTS, WE ONLY SET THIS TO SIMULATE A REAL RAILS APP.

# Used as the base secret for all MessageVerifiers in Rails, including the one protecting cookies.
secret_key_base: DO_NOT_STORE_A_SECRET_THIS_IS_JUST_FOR_AN_EXAMPLE
```

We cannot use something like `RAILS_MASTER_KEY=DUMMY_KEY` because the rails app would fail to start in the test with the following message:

```yaml
app_1 | 2022-02-04 22:18:51 +0000 Rack app ("GET /outgoing-http-call" - (172.18.0.4)): #<ActiveSupport::MessageEncryptor::InvalidMessage: ActiveSupport::MessageEncryptor::InvalidMessage>
```
