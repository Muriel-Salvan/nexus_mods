# nexus_mods

Simple Ruby API letting you handle [NexusMods](https://www.nexusmods.com/) REST API.

## Install

Via gem

``` bash
$ gem install nexus_mods
```

Via a Gemfile

``` ruby
$ gem 'nexus_mods'
```

## Usage

``` ruby
require 'nexus_mods'

nexus_mods = NexusMods.new(api_key: 'sdflfkglkjewfmlkvweflkngvkndflvnelrjgn')
puts nexus_mods.mod(mod_id: 2014).name
```

## Change log

Please see [CHANGELOG](CHANGELOG.md) for more information on what has changed recently.

## Testing

Automated tests are done using rspec.

Do execute them, first install development dependencies:

```bash
bundle install
```

Then execute rspec

```bash
bundle exec rspec
```

## Contributing

Any contribution is welcome:
* Fork the github project and create pull requests.
* Report bugs by creating tickets.
* Suggest improvements and new features by creating tickets.

## Credits

- [Muriel Salvan][link-author]

## License

The BSD License. Please see [License File](LICENSE.md) for more information.
