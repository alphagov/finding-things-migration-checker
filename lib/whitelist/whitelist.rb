# The Whitelist provides a mechanism for checkers to eliminate some of their
# output before it is presented to the user and treated as an error.
#
# Each checker is provided with a predicate, which, given an array of output stings
# representing a row in the checker-specific csv output, determines whether to include that row.
#
# The `#get_whitelist_function` method is the entry point for filtering an array of rows.
# It returns a function which, applied to an array representing a row, returns whether to exclude that row.
# It takes a checker name for which to look up the ruleset and an array of column headers to allow the
# ruleset to know which indexes to examine in each row array.
#
# The ruleset for each checker may contain several rules, each with its own expiry date
# and reason for existing. Expired rules are still applied but are themselves reported on
# by the `ExpiredWhitelistEntries` checker.
# Each rule is formed of some equality tests on the row, in https://en.wikipedia.org/wiki/Disjunctive_normal_form
#
# See the default `whitelist.yml` file for an example.

class Whitelist
  def initialize(whitelist)
    @whitelist = whitelist
    @predicates = build_predicate_hash(whitelist)
  end

  def apply(check_name, headers, rows)
    whitelister = get_whitelister(check_name, headers)
    rows.reject(&whitelister.whitelist_function)
  end

  def get_whitelister(check_name, headers)
    Whitelister.new(get_or_else(@predicates, check_name, []), headers)
  end

  def get_or_else(hash, key, default)
    # when the key is present and maps to `nil`, `#fetch` returns `nil` rather than the given default
    value = hash[key]
    value ? value : default
  end

  def report_expired_entries(reference_date)
    expiries = @whitelist.flat_map do |check|
      get_or_else(check[1], 'rules', []).map do |rule|
        [check[0], rule['expiry'], rule['reason']]
      end
    end
    expiries.select { |expiry| Date.parse(expiry[1]) <= reference_date }
  end

  def self.load(whitelist_file)
    yaml = YAML.load_file(whitelist_file)
    Whitelist.new(yaml ? yaml : {})
  end

private

  def build_predicate_hash(whitelist)
    whitelist.reduce({}) do |hash, (check_name, rules_hash)|
      rules = get_or_else(rules_hash, 'rules', [])
      hash[check_name] = rules.map { |predicate_hash| build_predicate(predicate_hash) }
      hash
    end
  end

  def build_predicate(predicate_hash)
    Predicate.new(
      predicate_hash['predicate'],
      predicate_hash['reason'],
      predicate_hash['expiry'],
    )
  end

  class Predicate
    attr_reader :reason, :expiry

    def initialize(conj_hash_arr, reason, expiry)
      @conj_hash_arr = conj_hash_arr ? conj_hash_arr : []
      @reason = reason
      @expiry = expiry
    end

    def predicate_function(headers)
      Predicate.predicate_for(headers, @conj_hash_arr)
    end

    def inspect
      "{predicate: #{@conj_hash_arr}, reason: '#{@reason}', expiry: '#{@expiry}'}"
    end

    def self.predicate_for(headers, conj_hash_arr)
      conjunctions = conj_hash_arr.map { |conj_hash| Predicate.conjunction_for(headers, conj_hash) }
      lambda { |row| conjunctions.any? { |c| c.call(row) } }
    end

    def self.conjunction_for(headers, conj_hash)
      tests = conj_hash.map { |key_value| Predicate.test_for(headers, key_value) }
      lambda { |row| tests.all? { |t| t.call(row) } }
    end

    def self.test_for(headers, key_value)
      row_index = headers.find_index(key_value[0])
      if row_index.nil?
        raise ArgumentError.new("Invalid key_value #{key_value}")
      end
      lambda { |row| row[row_index] == key_value[1] }
    end
  end

  class Whitelister
    attr_reader :whitelist_function, :unused_entries

    def initialize(predicate_arr, headers)
      predicate_functions = predicate_arr.map { |predicate| [predicate, predicate.predicate_function(headers)] }
      @unused_entries = predicate_arr.dup
      @whitelist_function = lambda do |row|
        predicate_values = predicate_functions.map { |p, f| [p, f.call(row)] }

        matches = predicate_values.select { |_, v| v }.map { |p, _| p }
        @unused_entries = @unused_entries - matches

        !matches.empty?
      end
    end
  end
end
