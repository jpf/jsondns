version: 0.2

env:
  variables:
    AWS_REGION: "us-east-2"

phases:
  install:
    runtime-versions:
      Ruby: 2.6
  pre_build:
    commands:
      - gem install daemons
      - gem install dnsruby
      - gem install eventmachine
      - gem install rack
      - gem install sinatra
      - gem install thin
      - gem install tilt
      - gem install yajl-ruby 
 pre_build:
    commands:
      - RAILS_ENV=source :https://rubygems.org