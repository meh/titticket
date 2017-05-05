require 'lissio/adapter/rest'
require 'time'

class REST < Lissio::Adapter::REST
	URL = 'https://example.com'

	def initialize(*args, &block)
		super(*args) {|_|
			_.base "#{URL}/v1"

			_.http do |req|
				req.headers.clear
			end

			if block.arity == 0
				instance_exec(&block)
			else
				block.call(_)
			end if block
		}
	end
end

require 'model/amount'
require 'model/payment'

require 'model/question'
require 'model/answer'

require 'model/event'
require 'model/events'

require 'model/ticket'
require 'model/purchase'
require 'model/order'
