module NiceHttpManageRequest

  ######################################################
  # private method to manage Request
  #   input:
  #     3 args: path, data, headers
  #     1 arg:  Hash containg at least keys :path and :data
  #             In case :data not supplied and :data_examples array supplied, it will be taken the first example as :data.
  #   output:
  #     path, data, headers
  ######################################################
  def manage_request(*arguments)
    require "json"
    begin
      content_type_included = false
      path = ""
      data = ""

      @response = Hash.new()
      headers_t = @headers.dup()
      cookies_to_set_str = ""
      if arguments.size == 3
        path = arguments[0]
      elsif arguments.size == 1 and arguments[0].kind_of?(Hash)
        path = arguments[0][:path]
      elsif arguments.size == 1 and arguments[0].kind_of?(String)
        path = arguments[0].to_s()
      end
      path = (@prepath + path).gsub('//','/') unless path.nil? or path.start_with?('http:') or path.start_with?('https:')
      @cookies.each { |cookie_path, cookies_hash|
        cookie_path = "" if cookie_path == "/"
        path_to_check = path
        if path == "/" or path[-1] != "/"
          path_to_check += "/"
        end
        if path_to_check.scan(/^#{cookie_path}\//).size > 0
          cookies_hash.each { |key, value|
            cookies_to_set_str += "#{key}=#{value}; "
          }
        end
      }
      headers_t["Cookie"] = cookies_to_set_str

      method_s = caller[0].to_s().scan(/:in `(.*)'/).join

      if arguments.size == 3
        data = arguments[1]
        if arguments[2].kind_of?(Hash)
          headers_t.merge!(arguments[2])
        end
      elsif arguments.size == 1 and arguments[0].kind_of?(Hash)
        if arguments[0][:data].nil?
          if arguments[0].keys.include?(:data)
            data = ""
          elsif arguments[0].keys.include?(:data_examples) and
                arguments[0][:data_examples].kind_of?(Array)
            data = arguments[0][:data_examples][0] #the first example by default
          else
            data = ""
          end
        else
          data = arguments[0][:data]
        end
        if arguments[0].include?(:headers)
          headers_t.merge!(arguments[0][:headers])
        end

        if headers_t["Content-Type"].to_s() == "" and headers_t["content-type"].to_s() == "" and
           headers_t[:"content-type"].to_s() == "" and headers_t[:"Content-Type"].to_s() == ""
          content_type_included = false
        elsif headers_t["content-type"].to_s() != ""
          content_type_included = true
          headers_t["Content-Type"] = headers_t["content-type"]
        elsif headers_t[:"content-type"].to_s() != ""
          content_type_included = true
          headers_t["Content-Type"] = headers_t[:"content-type"]
          headers_t.delete(:"content-type")
        elsif headers_t[:"Content-Type"].to_s() != ""
          content_type_included = true
          headers_t["Content-Type"] = headers_t[:"Content-Type"]
          headers_t.delete(:"Content-Type")
        elsif headers_t["Content-Type"].to_s() != ""
          content_type_included = true
        end
        if !content_type_included and data.kind_of?(Hash)
          headers_t["Content-Type"] = "application/json"
          content_type_included = true
        end
        # to be backwards compatible since before was :values
        if arguments[0].include?(:values) and !arguments[0].include?(:values_for)
          arguments[0][:values_for] = arguments[0][:values]
        end
        if content_type_included and (!headers_t["Content-Type"][/text\/xml/].nil? or
                                      !headers_t["Content-Type"]["application/soap+xml"].nil? or
                                      !headers_t["Content-Type"][/application\/jxml/].nil?)
          if arguments[0].include?(:values_for)
            arguments[0][:values_for].each { |key, value|
              data = NiceHttpUtils.set_value_xml_tag(key.to_s(), data, value.to_s(), true)
            }
          end
        elsif content_type_included and !headers_t["Content-Type"][/application\/json/].nil? and data.to_s() != ""
          require "json"
          if data.kind_of?(String)
            if arguments[0].include?(:values_for)
              arguments[0][:values_for].each { |key, value|
                data.gsub!(/"(#{key})":\s*"([^"]*)"/,'"\1": "'+value+'"')  # "key":"value"
                data.gsub!(/(#{key}):\s*"([^"]*)"/,'\1: "'+value+'"')  # key:"value"
                data.gsub!(/(#{key}):\s*'([^']*)'/,'\1: \''+value+"'")  # key:'value'
                data.gsub!(/"(#{key})":\s*(\w+)/,'"\1": '+value)  # "key":456
                data.gsub!(/(#{key}):\s*(\w+)/,'\1: '+value)  # key:456
              }
            end
          elsif data.kind_of?(Hash)
            data_n = Hash.new()
            data.each { |key, value|
              data_n[key.to_s()] = value
            }
            if arguments[0].include?(:values_for)
              #req[:values_for][:loginName] or req[:values_for]["loginName"]
              new_values_hash = Hash.new()
              arguments[0][:values_for].each { |kv, vv|
                if data_n.keys.include?(kv.to_s())
                  new_values_hash[kv.to_s()] = vv
                end
              }
              data_n.merge!(new_values_hash)
            end
            data = data_n.to_json()
          elsif data.kind_of?(Array)
            data_arr = Array.new()
            data.each_with_index { |row, indx|
              unless row.kind_of?(Hash)
                @logger.fatal("Wrong format on request application/json, be sure is a Hash, Array of Hashes or JSON string")
                return :error, :error, :error
              end
              data_n = Hash.new()
              row.each { |key, value|
                data_n[key.to_s()] = value
              }
              if arguments[0].include?(:values_for)
                #req[:values_for][:loginName] or req[:values_for]["loginName"]
                new_values_hash = Hash.new()
                if arguments[0][:values_for].kind_of?(Hash) #values[:mykey][3]
                  arguments[0][:values_for].each { |kv, vv|
                    if data_n.keys.include?(kv.to_s()) and !vv[indx].nil?
                      new_values_hash[kv.to_s()] = vv[indx]
                    end
                  }
                elsif arguments[0][:values_for].kind_of?(Array) #values[5][:mykey]
                  if !arguments[0][:values_for][indx].nil?
                    arguments[0][:values_for][indx].each { |kv, vv|
                      if data_n.keys.include?(kv.to_s())
                        new_values_hash[kv.to_s()] = vv
                      end
                    }
                  end
                else
                  @logger.fatal("Wrong format on request application/json when supplying values, the data is an array of Hashes but the values supplied are not")
                  return :error, :error, :error
                end
                data_n.merge!(new_values_hash)
              end
              data_arr.push(data_n)
            }
            data = data_arr.to_json()
          else
            @logger.fatal("Wrong format on request application/json, be sure is a Hash, Array of Hashes or JSON string")
            return :error, :error, :error
          end
        elsif content_type_included and arguments[0].include?(:values_for)
          if arguments[0][:values_for].kind_of?(Hash) and arguments[0][:values_for].keys.size > 0
            if !headers_t.nil? and headers_t.kind_of?(Hash) and headers_t["Content-Type"] != "application/x-www-form-urlencoded" and headers_t["content-type"] != "application/x-www-form-urlencoded"
              @logger.warn(":values_for key given without a valid content-type or data for request. No values modified on the request")
            end
          end
        end
      elsif arguments.size == 1 and arguments[0].kind_of?(String)
        #path=arguments[0].to_s()
        data = ""
      else
        @logger.fatal("Invalid number of arguments or wrong arguments in #{method_s}")
        return :error, :error, :error
      end
      if headers_t.keys.include?("Content-Type") and !headers_t["Content-Type"]["multipart/form-data"].nil? and headers_t["Content-Type"] != ["multipart/form-data"] #only for the case raw multipart request
        encoding = "UTF-8"
        data_s = ""
      else
        encoding = data.to_s().scan(/encoding='(.*)'/i).join
        if encoding.to_s() == ""
          encoding = data.to_s().scan(/charset='(.*)'/i).join
        end
        if encoding.to_s() == "" and headers_t.include?("Content-Type")
          encoding = headers_t["Content-Type"].scan(/charset='?(.*)'?/i).join
          if encoding.to_s() == ""
            encoding = headers_t["Content-Type"].scan(/encoding='?(.*)'?/i).join
          end
        end

        begin
          data_s = JSON.pretty_generate(JSON.parse(data))
        rescue
          data_s = data
        end
        data_s = data_s.to_s().gsub("<", "&lt;")
      end
      if headers_t.keys.include?("Accept-Encoding")
        headers_t["Accept-Encoding"].gsub!("gzip", "") #removed so the response is in plain text
      end

      headers_ts = ""
      headers_t.each { |key, val| headers_ts += key.to_s + ":" + val.to_s() + ", " }
      message = "#{method_s} REQUEST: \npath= " + path.to_s() + "\n"
      message += "headers= " + headers_ts.to_s() + "\n"
      message += "data= " + data_s.to_s() + "\n"
      message = @message_server + "\n" + message
      if path.to_s().scan(/^https?:\/\//).size > 0 and path.to_s().scan(/^https?:\/\/#{@host}/).size == 0
        # the path is for another server than the current
      else
        self.class.last_request = message
        @logger.info(message)
      end

      if data.to_s() != "" and encoding.to_s().upcase != "UTF-8" and encoding != ""
        data = data.to_s().encode(encoding, "UTF-8")
      end
      return path, data, headers_t
    rescue Exception => stack
      @logger.fatal(stack)
      @logger.fatal("manage_request Error on method #{method_s} . path:#{path.to_s()}. data:#{data.to_s()}. headers:#{headers_t.to_s()}")
      return :error
    end
  end

end