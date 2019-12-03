# Logstash Redfish Plugin

This is a plugin for [Logstash](https://github.com/elastic/logstash).

The plugin connect to a redfish machine and get the data from the redfish api.

## How to  use

Add the redfish input in your Logstash pipeline as follow:

```sh
  redfish {
    ip => "10.10.10.10"
    api_user => "user"
    api_key => "key"
    types => ["thermal", "power"]
  }
```
The parameters supported until now are:
- ip: IP Address of the redfish machine
- api_user: The username set in the redfish machine.
- api_key: The key of the previous user.
- types: Data that can be extracted from the redfish API, options here are: thermal, power and systems.

The output of the data will be set on the message variable. You can rescue the data and convert to a json with a simple json filter and then keep working on it:

```sh
filter {
  if [message] {
    json {
      source => [message]
      target => "message"
    }
  }
}
```
## Developing

### 1. Plugin Developement and Testing

#### Code
- To get started, you'll need JRuby with the Bundler gem installed.

- Clone from the GitHub [logstash-input-redfish](https://github.com/redBorder/logstash-input-redfish)

- Install dependencies
```sh
bundle install
```

#### Test

- Update your dependencies

```sh
bundle install
```

- Run tests

```sh
bundle exec rspec
```

### 2. Running your unpublished Plugin in Logstash

#### 2.2 Run in an installed Logstash

You can use the same **2.1** method to run your plugin in an installed Logstash by editing its `Gemfile` and pointing the `:path` to your local plugin development directory or you can build the gem and install it using:

- Build your plugin gem
```sh
gem build logstash-input-redfish.gemspec
```
- Install the plugin from the Logstash home
```sh
# Logstash 2.3 and higher
bin/logstash-plugin install --no-verify

# Prior to Logstash 2.3
bin/plugin install --no-verify

```
- Start Logstash and proceed to test the plugin

## Contributing

All contributions are welcome: ideas, patches, documentation, bug reports, complaints, and even something you drew up on a napkin.

Programming is not a required skill. Whatever you've seen about open source and maintainers or community members  saying "send patches or die" - you will not see that here.

It is more important to the community that you are able to contribute.