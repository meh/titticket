class Page
	attr_reader :header, :content

	def initialize(*args, &block)
		@header  = self.class.const_get(:Header).new(*args, &block)
		@content = self.class.const_get(:Content).new(*args, &block)
	end

	def trigger!(*args)
		@header.trigger!(*args)
		@content.trigger!(*args)
	end

	module Header
		class None < Lissio::Component
			on :render do
				$document['header'].remove
			end
		end
	end
end

require 'page/index'
require 'page/event'
require 'page/order'
