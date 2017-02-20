module HashArrays
  class ::Array
    def where(args)
      select {|hash|
        args.all? {|key, value|
          hash[key].is_a?(String) ? !hash[key].match(value).nil? : hash[key] == value
        }
      }
    end
  end
end
