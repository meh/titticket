require 'opal'
require 'time'

require 'browser'
require 'browser/effects'
require 'browser/console'

require 'lissio'
require 'lissio/adapter/storage'

require 'helpers'
require 'components'
require 'models'
require 'pages'

class Titticket < Lissio::Application
	def initialize
		super

		route '/' do
			loading!

			Events.fetch.then {|events|
				load Page::Index.new(events)
			}.fail { |e|
				load Page::Error.new(e)
			}
		end

		route '/event/:id' do |params|
			loading!

			Page::Event.load(params[:id].to_i).trace {|*args|
				load Page::Event.new(*args)
			}.fail { |e|
				load Page::Error.new(e)
			}
		end

		route '/ticket/:id' do |params|
			Ticket.fetch(params[:id].to_i).then {|ticket|
				element.content = ticket.inspect
			}.fail { |e|
				load Page::Error.new(e)
			}
		end

		route '/order/:id/success' do |params|
			Order.fetch(params[:id]).then {|order|
				load Page::Order::Success.new(order)
			}.fail { |e|
				load Page::Error.new(e)
			}
		end

		route '/order/failure' do
			load Page::Order::Failure.new
		end

		route '/order/cancel' do
			load Page::Order::Cancel.new
		end

		missing do
			load Page::Error.new
		end

		# Custom links.
		route '/italian-embassy-2017' do
			router.match '/event/1'
		end
	end

	def loading!
		element.at_css('.container').tap {|container|
			container.inner_dom = Component::Loader.new.render
		}
	end

	def load(component)
		@current.trigger! 'page:unload' if @current
		@current = component

		element.at_css('header').tap {|header|
			header.inner_dom = @current.header.render
			header.show
		}

		element.at_css('.container').tap {|container|
			container.inner_dom = @current.content.render
		}

		@current.trigger! 'page:load'
	end

	html do
		header.sticky
		div.container

#		footer.sticky do
#			span "Sponsored by Faffanifaffofa Foffina."
#		end
	end

	css do
		media '(max-width: 1024px)' do
			rule '& > .container' do
				padding 0
			end
		end

		rule 'header' do
			display :none
		end
	end
end
