# WebapiInvoker

WebapiInvoker is a library for calling web api easier than using Net::HTTP directly.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'webapi_invoker'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install webapi_invoker

## Usage

### access google top and check response

```ruby
res = webapi_invoke( :get,
  url: "https://www.google.com/",
).expected code: 200
```

### do google search

```ruby
res = webapi_invoke( :get,
  url: "https://www.google.com/",
  query: {q: "–|–ó"}
).expected code: 200
```

### query string directly sample

```ruby
qr1 = webapi_invoke( :get,
  url: "https://chart.googleapis.com/chart?chs=50x50&cht=qr&chl=Hello+world&chld=L|1&choe=UTF-8",
)
# qr1.body is QR code PNG image
```

### post form data

```ruby
qr2 = webapi_invoke( :post,
  url: "https://chart.googleapis.com/chart",
  form: {
    chs: "50x50",
    cht: "qr",
    chl: "Hello world",
    chld: "L|1",
    choe: "UTF-8",
  }
)
# qr2.body is QR code PNG image
```

### put application/json

```ruby
qr2 = webapi_invoke( :put,
  url: "https://some.api.com/v1/index",
  json: {
    name: "abc",
    type: "book",
    size: "b5",
  }
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mikari-gh/webapi_invoker .

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
