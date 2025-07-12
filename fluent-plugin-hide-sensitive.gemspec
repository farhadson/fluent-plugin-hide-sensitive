Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-hide-sensitive"
  spec.version       = "spec.version = Fluent::Plugin::HideSensitive::VERSION"
  spec.authors       = ["Farhad Kazemi"]
  spec.email         = ["farhad.kazemi89@gmail.com"]

  spec.summary       = %q{Filter plugin to hide sensitive fields}
  spec.description   = %q{A Fluentd filter plugin to move and delete sensitive keys from a nested object.}
  spec.homepage      = "https://github.com/farhadson/fluent-plugin-hide-sensitive"
  spec.license       = "MIT"
  spec.metadata = {
    "source_code_uri" => "https://github.com/farhadson/fluent-plugin-hide-sensitive",
    "bug_tracker_uri" => "https://github.com/farhadson/fluent-plugin-hide-sensitive/issues"
  }

  spec.files         = Dir["lib/**/*.rb"] + ["LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "fluentd", ">= 1.0", "< 2.0"
end
