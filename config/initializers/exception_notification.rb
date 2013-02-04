configure :production do
  aws_secrets = File.expand_path("../aws_secrets.yml", File.dirname(__FILE__))
  if File.exist?(aws_secrets)
    disable :show_exceptions
    use ExceptionMailer, YAML.load_file(aws_secrets),
        to: ['govuk-exceptions@digital.cabinet-office.gov.uk'],
        from: '"Winston Smith-Churchill" <winston@alphagov.co.uk>',
        subject: '[Content API exception]'
  end
end
