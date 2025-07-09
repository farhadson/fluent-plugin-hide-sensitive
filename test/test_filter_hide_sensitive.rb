require 'test/unit'
require 'fluent/test'
require 'fluent/test/driver/filter'
require_relative '../lib/fluent/plugin/filter_hide_sensitive'

class HideSensitiveFilterTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  def create_driver(conf = {})
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::HideSensitiveFilter).configure(conf)
  end

  def test_filter_removes_and_moves_keys
    d = create_driver({
      'sensitive_keys' => 'token,pass',
      'search_path' => 'log.data.message',
      'output_key' => 'hidden_keys'
    })

    input = {
      'log' => {
        'data' => {
          'message' => {
            'token' => 'secret123',
            'pass' => 'hunter2',
            'other' => 'visible'
          }
        }
      }
    }

    expected = input.dup
    expected['log']['data']['message'].delete('token')
    expected['log']['data']['message'].delete('pass')
    expected['hidden_keys'] = {
      'token' => 'secret123',
      'pass' => 'hunter2'
    }

    assert_equal expected, d.filter('test', Time.now.to_i, input)
  end
end
