# Executo

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/executo`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'executo'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install executo

## Usage

TODO: Write usage instructions here

## Development

Run worker using `sidekiq -r boot.rb -C sidekiq.yml`

Publish jobs using:
```ruby
Executo.publish('localhost', 'ls', ['-al'])
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/executo. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Executo project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/executo/blob/master/CODE_OF_CONDUCT.md).
