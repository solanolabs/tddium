#
# tddium support methods
#
#

require 'rubygems'
require 'highline/import'

ALREADY_CONFIGURED =<<'EOF'

tddium has already been initialized.

(settings are in %s)

Use 'tddium config' to change settings.
EOF

def init_task
  path = File.expand_path('~/.tddium')

  if File.exists?(path) then
    puts ALREADY_CONFIGURED % path
  else
    key = ask('Enter AWS Access Key: ')
    secret = ask('Enter AWS Secret: ')

    File.open(path, 'w', 0600) do |f|
      f.write <<EOF
aws_key: #{key}
aws_secret: #{secret}
EOF
    end
  end
end
