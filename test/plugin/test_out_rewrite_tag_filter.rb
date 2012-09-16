require 'helper'

class RewriteTagFilterOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    rewriterule1 domain ^www\.google\.com$ site.Google
    rewriterule2 domain ^news\.google\.com$ site.GoogleNews
    rewriterule3 agent Mac\sOS\sX agent.MacOSX
    rewriterule4 agent (Googlebot|CustomBot)-([a-zA-Z]+) agent.$1-$2
  ]

  CONFIG2 = %[
    capitalize_regex_backreference yes
    rewriterule1 domain ^www\.google\.com$ site.Google # some comment
    rewriterule2 domain ^(news)\.(google)\.com$ site.$2$1
    rewriterule3 agent Mac\sOS\sX agent.MacOSX
    rewriterule4 agent (Googlebot|CustomBot)-([a-zA-Z]+) agent.$1-$2
  ]

  def create_driver(conf=CONFIG,tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::RewriteTagFilterOutput, tag).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }
    d = create_driver %[
      rewriterule1 domain ^www.google.com$ site.Google
      rewriterule2 domain ^news.google.com$ site.GoogleNews
    ]
    d.instance.inspect
    assert_equal 'domain ^www.google.com$ site.Google', d.instance.rewriterule1
    assert_equal 'domain ^news.google.com$ site.GoogleNews', d.instance.rewriterule2
  end

  def test_emit
    d1 = create_driver(CONFIG, 'input.access')
    time = Time.parse("2012-01-02 13:14:15").to_i
    d1.run do
      d1.emit({'domain' => 'www.google.com', 'path' => '/foo/bar?key=value', 'agent' => 'Googlebot', 'response_time' => 1000000})
      d1.emit({'domain' => 'news.google.com', 'path' => '/', 'agent' => 'Googlebot-Mobile', 'response_time' => 900000})
      d1.emit({'domain' => 'map.google.com', 'path' => '/', 'agent' => 'Macintosh; Intel Mac OS X 10_7_4', 'response_time' => 900000})
      d1.emit({'domain' => 'labs.google.com', 'path' => '/', 'agent' => 'Mozilla/5.0 Googlebot-FooBar/2.1', 'response_time' => 900000})
    end
    emits = d1.emits
    assert_equal 4, emits.length
    p emits[0]
    assert_equal 'site.Google', emits[0][0] # tag
    p emits[1]
    assert_equal 'site.GoogleNews', emits[1][0] # tag
    assert_equal 'news.google.com', emits[1][2]['domain']
    p emits[2]
    assert_equal 'agent.MacOSX', emits[2][0] #tag
    p emits[3]
    assert_equal 'agent.Googlebot-FooBar', emits[3][0] #tag
  end

  def test_emit2
    d1 = create_driver(CONFIG2, 'input.access')
    time = Time.parse("2012-01-02 13:14:15").to_i
    d1.run do
      d1.emit({'domain' => 'www.google.com', 'path' => '/foo/bar?key=value', 'agent' => 'Googlebot', 'response_time' => 1000000})
      d1.emit({'domain' => 'news.google.com', 'path' => '/', 'agent' => 'Googlebot-Mobile', 'response_time' => 900000})
      d1.emit({'domain' => 'map.google.com', 'path' => '/', 'agent' => 'Macintosh; Intel Mac OS X 10_7_4', 'response_time' => 900000})
      d1.emit({'domain' => 'labs.google.com', 'path' => '/', 'agent' => 'Mozilla/5.0 Googlebot-FooBar/2.1', 'response_time' => 900000})
    end
    emits = d1.emits
    assert_equal 4, emits.length
    p emits[0]
    assert_equal 'site.Google', emits[0][0] # tag
    p emits[1]
    assert_equal 'site.GoogleNews', emits[1][0] # tag
    assert_equal 'news.google.com', emits[1][2]['domain']
    p emits[2]
    assert_equal 'agent.MacOSX', emits[2][0] #tag
    p emits[3]
    assert_equal 'agent.Googlebot-Foobar', emits[3][0] #tag
  end
end

