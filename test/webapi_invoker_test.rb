# frozen_string_literal: true
# -*- coding: UTF-8 -*-

require "test_helper"
require "webapi_invoker"

class WebapiInvokerTest < Test::Unit::TestCase
  include WebapiInvoker
  
  test "VERSION" do
    assert do
      ::WebapiInvoker.const_defined?(:VERSION)
    end
  end

  test "access to google" do
    res = nil
    assert_nothing_raised {
      res = webapi_invoke( :get,
        url: "https://www.google.com/",
      ).expected code: 200
    }
    assert_not_nil(res)
    assert_not_nil(res.body)
    
    res = nil
    assert_nothing_raised {
      res = webapi_invoke( :get,
        url: "https://www.google.com/",
        query: {q: "\u{7ffb 8a33}"}
      ).expected code: 200
    }
    assert_not_nil(res)
    assert_not_nil(res.body)
    #puts res.body.force_encoding('UTF-8')
    
    qr1 = nil
    assert_nothing_raised {
      qr1 = webapi_invoke( :get,
        url: "https://chart.googleapis.com/chart?chs=50x50&cht=qr&chl=Hello+world&chld=L|1&choe=UTF-8",
      ).expected code: 200
    }
    assert_not_nil(qr1)
    assert_not_nil(qr1.body)
    
    qr2 = nil
    assert_nothing_raised {
      qr2 = webapi_invoke( :post,
        url: "https://chart.googleapis.com/chart",
        form: {
          chs: "50x50",
          cht: "qr",
          chl: "Hello world",
          chld: "L|1",
          choe: "UTF-8",
        }
      ).expected code: 200
    }
    assert_not_nil(qr2)
    assert_not_nil(qr2.body)
    
    assert_equal(qr1.body, qr2.body) # expected / actual
  end
  
  test "access to github" do
    res = nil
    assert_nothing_raised {
      res = webapi_invoke( :get,
        url: "https://api.github.com/feeds"
      ).expected code: 200
    }
    assert_not_nil(res)
  end
  
end
