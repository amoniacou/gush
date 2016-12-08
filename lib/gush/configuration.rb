module Gush
  class Configuration
    attr_accessor :concurrency, :namespace, :redis_url, :environment

    def self.from_json(json)
      new(Gush::JSON.decode(json, symbolize_keys: true))
    end

    def initialize(hash = {})
      redis            = Sidekiq.redis {|conn| conn}
      self.concurrency = hash.fetch(:concurrency, Sidekiq.redis_pool.instance_variable_get(:@size))
      url, namespace = if redis.is_a?(::Redis)
                         [redis.client.options[:url], 'gush']
                       else
                         [redis.redis.client.options[:url], "#{redis.namespace}gush"]
                       end
      self.redis_url   = hash.fetch(:redis_url, url || 'redis://localhost:6379')
      self.namespace   = hash.fetch(:namespace, namespace)
      self.gushfile    = hash.fetch(:gushfile, 'Gushfile.rb')
      self.environment = hash.fetch(:environment, ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development')
    end

    def gushfile=(path)
      @gushfile = Pathname(path)
    end

    def gushfile
      @gushfile.realpath
    end

    def to_hash
      {
        concurrency: concurrency,
        namespace:   namespace,
        redis_url:   redis_url,
        environment: environment
      }
    end

    def to_json
      Gush::JSON.encode(to_hash)
    end
  end
end
