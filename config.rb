require_relative 'env'
require_relative 'lib/exception_mailer'

configure do
  mongoid_config_file = File.expand_path("mongoid.yml", File.dirname(__FILE__))
  if File.exists?(mongoid_config_file)
    ::Mongoid.load!(mongoid_config_file)
  end

  # Disable pagination until our clients are all ready for it
  disable :pagination
end

configure :production do
  if File.exist?("aws_secrets.yml")
    disable :show_exceptions
    use ExceptionMailer, YAML.load_file("aws_secrets.yml"),
        to: ['govuk-exceptions@digital.cabinet-office.gov.uk'],
        from: '"Winston Smith-Churchill" <winston@alphagov.co.uk>'
  end
end
