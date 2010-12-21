#
# tddium support methods
#
#

require 'rubygems'
require 'highline/import'

ALREADY_CONFIGURED =<<'EOF'

tddium has already been initialized.

(settings are in %s)

Use 'tddium reset' to clear configuration, and then run 'tddium init' again.
EOF

CONFIG_FILE_PATH = File.expand_path('~/.tddium')

def init_task
  if File.exists?(CONFIG_FILE_PATH) then
    puts ALREADY_CONFIGURED % CONFIG_FILE_PATH
  else
    key = ask('Enter AWS Access Key: ')
    secret = ask('Enter AWS Secret: ')

    File.open(CONFIG_FILE_PATH, 'w', 0600) do |f|
      f.write <<EOF
aws_key: #{key}
aws_secret: #{secret}
EOF
    end
  end
end

def test_sequential_task

end
