# frozen_string_literal: true
# -*- coding: UTF-8 -*-
=begin

  ussage
  
  require 'webapi_invoker'
  
  class API_TEST <  Test::Unit::TestCase
    
    # mixin
    include WebapiInvoker
    
    def test_APIxxx
      # The message body is json, then use json: key
      # The message body is form, then use form: key
      # Other type, set body: header: content_type:
      result = api_invoke( :post,
        url: "http://xxx",
        json: { user: "xxxx" }
      ).expected code:200
      assert result.body[:status],"suspend","status check"
    end
  end

=end

require_relative "webapi_invoker/version"
require 'net/http'
require 'json'
require 'uri'

module Net
	class HTTP
		def set_debug_output=(logger)
			set_debug_output(logger)
		end
	end
end


module WebapiInvoker
  SETTING = {logger:nil, httplog:nil}
  
  class << self
    
    def log_debug(msg)
      if API_INVOKE::SETTING[:logger] then
        API_INVOKE::SETTING[:logger].debug msg
      else
        STDERR.puts msg
      end
    end
    
  end
  
  class UnexpectedResultError < ::RuntimeError; end


  # Return request object
  def getRequest(method, path, header=nil)
    case method
    when :get
      Net::HTTP::Get.new(path, header)
    
    when :post
      Net::HTTP::Post.new(path, header)
    
    when :put
      Net::HTTP::Put.new(path, header)
    
    when :delete
      Net::HTTP::Delete.new(path, header)
      
    else
      raise UndefinedError, "undefined method #{method}"
    end
  end
  
  
  # make http request path from URI object
  def requestPath(url)
    if url.query.to_s.empty?
      url.path
    else
      "#{url.path}?#{url.query}"
    end
  end
  
  
  # return value of http response
  HttpRes = Struct.new(:code, :type, :body, :raw ) do
    def initialize(code: nil, type: nil, body: nil, raw: nil)
      super(code, type, body, raw)
    end
    
    # return value check
    def expected(exp={})
      # p self,exp
      if exp[:code] then
        expected = exp[:code]
        if expected.kind_of?(Array) then
          expected.map!{|v| v.to_i }
        else
          expected = [expected.to_i]
        end
        
        result   = self.code.to_i
        raise UnexpectedResultError, "ResponseCode(#{result}) not in #{expected.inspect}" unless expected.include?(result)
      end
      
      self
    end
    
    
    # Get HTTP header as Hash
    def headerToHash
      httpresponse = self.raw
      
      result = {}
      httpresponse.canonical_each{|name,value|
        result[name]=value
      }
      result
    end
  end
  
  # Parse HTTP response
  def resultData(response)
    
    res = HttpRes.new(
      code: response.code,
      raw:  response,
      body: response.body,
    )
    #p response.content_type.to_s.downcase
    res.type = case response.content_type.to_s.downcase
    when "application/json"
      res.body = if res.body then JSON.parse(res.body.to_s, symbolize_names: true) else nil end
      :json
      
    when "text/xml", "application/xml"
      :xml
      
    when "text/plain"
      :text
      
    when "text/csv"
      :csv
      
    when "text/html"
      :html
      
    when "application/pdf"
      res.body.force_encoding("BINARY") if res.body.respond_to?(:force_encoding)
      :pdf
      
    when "application/octet-stream"
      res.body.force_encoding("BINARY") if res.body.respond_to?(:force_encoding)
      :binary
    when ""
      if res.body.to_s.empty? then
        :empty
      else
        :unknown
      end
      
    else
      #p response.content_type
      :unknown
    end
    
    res
  end
  
  # Check IO-like object
  #
  # If it respond to read / close / eof, it will be judged as an IO-like object.
  # Does not include patterns that delegate to IO#read
  # (the reason of checking close and eof)
  #
  # @return true "obj" is an IO-like object
  # @return true "obj" is not an IO-like object  
  def like_IO?(obj)
    return (obj.respond_to?(:read) and obj.respond_to?(:close) and obj.respond_to?(:eof))
  end
  
  # make an Web API call
  #
  # @param method   HTTP request method ( :get / :post / :put / :delete )
  # @param data     request details as Hasg
  #   - url: Request URL
  #   - query: QueryString(string or hash)
  #   - header: request header
  #   - body: request body
  #     - json: Hash object or JSON string, set Content-Type: application/json as default value.
  #       - If you want test error pattern, set broken json String instead of Hash.
  #     - form: form data
  #       - key... : data...
  #         If the data item contains an IO-like object, set Content-Type: to multipart/form-data,
  #         otherwise set Content-Type: to application/x-www-form-urlencoded.
  #         If you set an IO-like object in the data item, set the filename field is obj#path's result or "dummy.bin"
  #         If the key name matched /json/, set Content-Type: to application/json as default value.
  #   - json: same as [:body][:json] (preferred)
  #   - form: same as [:body][:form] (preferred)
  #
  # @return [HttpRes] WebAPI result
  #
  def webapi_invoke(method, data)
    url      = data[:url].to_s
    query    = data[:query]
    query = if query then
      if query.kind_of?(String) then
        query
      else
        URI.encode_www_form(query)
      end
    else
      ""
    end
    uri = url + if query.empty? then
      ""
    else
      (if url[-1]=="?" then "" else "?" end) + query
    end
    url      = URI.parse(uri)
    header   = data[:header].to_h
    raw_body = if data[:body].class == String then data[:body] else nil end
    body     = data[:body].to_h
    body[:json] = data[:json] if data[:json]
    body[:form] = data[:form] if data[:form]
    retry_count = (data.dig(:retry, :repeat) or data[:retry_repeat]).to_i
    retry_wait  = (data.dig(:retry, :wait)   or data[:retry_wait] ).to_i
    user_agent  = data.dig(:user_agent)

    raise NotSupportedError, "undefined scheme: #{url}" unless ["http","https"].include?(url.scheme)
    req = getRequest(method, requestPath(url))
    
    # set request headers
    header.each{ |key, value|
      head = if key.kind_of?(Symbol) then
        key.to_s.gsub(/_/, "-").downcase
      else
        key.downcase
      end
      req[head.to_s] = value
    }
    
    # set request body
    if raw_body then
      # raw data[
      req.body = raw_body
      
    elsif body[:json] != nil then
      # set json
      req["content-type"] = "application/json" unless req["content-type"]
      
      if body[:json].kind_of?(Hash) then
        # hash
        req.body=body[:json].to_json
      else
        # string
        req.body=body[:json]
      end
      
    elsif body[:form] != nil then
      form_data = if body[:form].kind_of?(Array) then
        # If the value type is an array, use it as an argument to set_form.
        body[:form]
      else
        # If value type is hash, convert to array.
        build = []
        body[:form].each{ |key,value|
          
          send_data = nil
          send_opt  = nil
          if value.kind_of?(Array) then
            send_data = value[0]
            send_opt  = value[1]
          else
            send_data = value
          end
          send_opt = {} unless send_opt
          
          # If the key name matched /json/, set Content-Type: to application/json as default value.
          if /json/.match(key) then
            send_opt[:content_type] = "application/json" unless send_opt[:content_type]
            
            if not send_data.kind_of?(String) then
              send_data = JSON.generate(send_data)
            end
          end
          
          if like_IO?(send_data) then
            filename = if send_opt[:filename] then send_opt[:filename] elsif send_data.respond_to?(:path) then Pathname(send_data.path).basename.to_s else "dummy.bin" end
            mime = MIME::Types.type_for(filename).first
            mime = if mime then mime.to_s else "application/octet-stream" end
            
            # Set default value for file name
            send_opt[:filename]     = filename unless send_opt[:filename]
            
            # Set default value for content-type
            send_opt[:content_type] = mime unless send_opt[:content_type]
          end
          
          if send_opt then
            build << [key.to_s, send_data, send_opt]
          else
            build << [key.to_s, send_data]
          end
        }
        
        build
      end
      
      # Determine transmission format (multipart if it contains IO-like objects)
      enctype = "application/x-www-form-urlencoded"
      form_data.each{ |item|
        if like_IO?(item[1]) then
          enctype = "multipart/form-data"
        end
      }
      req.set_form(form_data, enctype)
    end
    
    res = nil
    begin
      req[:user_agent] = user_agent if user_agent
      
      res = Net::HTTP.start(
        url.host, url.port,
        use_ssl: url.scheme == 'https',
        verify_mode: OpenSSL::SSL::VERIFY_NONE,
        set_debug_output: WebapiInvoker::SETTING[:httplog],
      ){ |http|
          http.request(req)
      }
    rescue Errno::ECONNREFUSED => ex
      if retry_count > 0 then
        sleep([retry_wait,1].max)
        retry_count-=1
        retry
      end
      API_INVOKE.log_debug ex.inspect
      raise
    end
    
    resultData(res)
  end

end

