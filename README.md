# Example Bootic App

A simple example app to show how to implement Bootic's OAuth2 authentication in a Ruby application.

This allows getting an access token to perform actions against the [Bootic API](https://api.bootic.net) using the Bootic's [Ruby API Client](https://github.com/bootic/bootic_client.rb).

## Installation

Clone the repo and install dependencies

    git clone https://github.com/bootic/example-bootic-app
    cd example-bootic-app
    bundle install
    
Create your app in [Bootic developer console](https://auth.bootic.net), then insert keys:

    cp config.yml.example config.yml
    nano config.yml # insert your app's client ID and secret

## Running

    bundle exec puma

