# nexus_mods

Simple Ruby API letting you handle [NexusMods](https://www.nexusmods.com/) REST API.

## Main features

* Get the API **limits**.
* Get the **games** information.
* Get individual **mods** and **mod files** information.
* Configurable **caching** with expiry times to save API calls to nexusmods.com.
* All served in an object-oriented **API in full Ruby**.

See the [examples](examples) for more details on how to use it.
Those examples expect that you set a valid NexusMods API key in the `NEXUS_MODS_API_KEY` environment variable.

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

- [Muriel Salvan](https://x-aeon.com/muriel)

## License

The BSD License. Please see [License File](LICENSE.md) for more information.
