class String
	def trim
		value = self.strip

		unless value.empty?
			value
		end
	end
end

class NilClass
	def trim
		nil
	end
end
