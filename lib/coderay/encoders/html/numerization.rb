module CodeRay
	module Encoders

	class HTML
		
		module Output

			def numerize *args
				clone.numerize!(*args)
			end

			NUMERIZABLE_WRAPPINGS = {
				:table => [:div, :page],
				:inline => :all,
				:list => [:div, :page],
				nil => :all
			}
			
			def numerize! mode = :table, options = {}
				return self unless mode

				options = DEFAULT_OPTIONS.merge options

				start = options[:line_number_start]
				unless start.is_a? Integer
					raise ArgumentError, "Invalid value %p for :line_number_start; Integer expected." % start
				end
				
				allowed_wrappings = NUMERIZABLE_WRAPPINGS[mode]
				unless allowed_wrappings == :all or allowed_wrappings.include? options[:wrap]
					raise ArgumentError, "Can't numerize, :wrap must be in %p, but is %p" % [NUMERIZABLE_WRAPPINGS, options[:wrap]]
				end
				
				bold_every = options[:bold_every]
				bolding = 
					if bold_every == :no_bolding or bold_every == 0
						proc { |line| line.to_s }
					elsif bold_every.is_a? Integer
						proc do |line|
							if line % bold_every == 0
								"<strong>#{line}</strong>"  # every bold_every-th number in bold
							else
								line.to_s
							end
						end
					else
						raise ArgumentError, "Invalid value %p for :bolding; :no_bolding or Integer expected." % bolding
					end
				
				line_count = count("\n")
				line_count += 1 if self[-1] != ?\n

				case mode				
				when :inline
					max_width = (start + line_count).to_s.size
					line = start
					gsub!(/^/) do
						line_number = bolding.call line
						line += 1
						"<span class=\"no\">#{ line_number.rjust(max_width) }</span>  "
					end
					#wrap! :div
					
				when :table
					# This is really ugly.
					# Because even monospace fonts seem to have different heights when bold, 
					# I make the newline bold, both in the code and the line numbers.
					# FIXME Still not working perfect for Mr. Internet Exploder
					# FIXME Firefox struggles with very long codes (> 200 lines)
					line_numbers = (start ... start + line_count).to_a.map(&bolding).join("\n")
					line_numbers << "\n"  # also for Mr. MS Internet Exploder :-/
					line_numbers.gsub!(/\n/) { "<tt>\n</tt>" }
					
					line_numbers_table_tpl = TABLE.apply('LINE_NUMBERS', line_numbers)
					gsub!(/\n/) { "<tt>\n</tt>" }
					wrap_in! line_numbers_table_tpl
					@wrapped_in = :div
					
				when :list
					opened_tags = []
					gsub!(/^.*$\n?/) do |line|
						line.chomp!
						
						open = opened_tags.join
						line.scan(%r!<(/)?span[^>]*>?!) do |close,|
							if close
								opened_tags.pop
							else
								opened_tags << $&
							end
						end
						close = '</span>' * opened_tags.size
						
						"<li>#{open}#{line}#{close}</li>"
					end
					wrap_in! LIST
					@wrapped_in = :div
					
				else
					raise ArgumentError, "Unknown value %p for mode: expected one of %p" %
						[mode, NUMERIZABLE_WRAPPINGS.keys - [:all]]
				end

				self
			end

		end

	end

end
end