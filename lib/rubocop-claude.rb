# frozen_string_literal: true

require_relative 'rubocop_claude/version'

require 'rubocop'

require_relative 'rubocop/cop/claude/no_fancy_unicode'
require_relative 'rubocop/cop/claude/tagged_comments'
require_relative 'rubocop/cop/claude/no_commented_code'
require_relative 'rubocop/cop/claude/no_backwards_compat_hacks'
require_relative 'rubocop/cop/claude/no_overly_defensive_code'
require_relative 'rubocop/cop/claude/explicit_visibility'
require_relative 'rubocop/cop/claude/method_parameter_shadowing'
require_relative 'rubocop/cop/claude/mystery_regex'

module RubocopClaude
  class Error < StandardError; end
end
