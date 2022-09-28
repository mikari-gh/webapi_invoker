# frozen_string_literal: true

require_relative "lib/webapi_invoker/version"

Gem::Specification.new do |spec|
  spec.name          = "webapi_invoker"
  spec.version       = WebapiInvoker::VERSION
  spec.authors       = ["mikari"]
  spec.email         = ["mikari_dev@wolf.nacht.jp"]

  spec.summary       = "Invoke WebApi easily."
  spec.description   = "Invoke WebApi easily. (json/text/io/form)"
  spec.homepage      = "https://rubygems.org/gems/webapi_invoker"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.0.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mikari-gh/webapi_invoker"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  #spec.add_dependency "json", "~> 2.5", ">= 2.5.1"
  #spec.add_dependency "net-http", "~> 0.1", ">= 0.1.1"
  #spec.add_dependency "uri", "~> 0.10", ">= 0.10.1"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
