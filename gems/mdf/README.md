# MDF

The metadata formatter for Cucumber.  This customer formatter generates JSON reports that differ from the default json formatter in two ways:

1. The output from calling puts in stepdefs is captured.
2. The ability to store arbitrary data in the report.

All data is stored at the scenario level under the *meta_data* key. 

## Installation

Add this line to your application's Gemfile:

    gem 'mdf'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mdf

## Usage

Execute cucumber with *--format MDF::Formatter::Json*

Adding metadata from outside stepdefs (like your page objects for example) requires access to the formatter:

```ruby

formatter = MDF::Formatter::MetaDataFormatter.instance
formatter.puts 'some text' # goes to [:meta_data][:output]
formatter.meta_data[:some_key] = { :foo => 'bar' }  # goes to [:meta_data][:some_key]   
	
```

  


## Contributing

1. Fork it ( https://github.com/[my-github-username]/mdf/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
