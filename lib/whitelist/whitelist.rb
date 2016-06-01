# The Whitelist provides a mechanism for checkers to eliminate some of their
# output before it is presented to the user and treated as an error.
#
# Each checker is provided with a predicate, which, given an array of output stings
# representing a row in the checker-specific csv output, determines whether to include that row.
#
# The `#apply` method is the entry point for filtering an array of rows.
# In addition to the rows to be filtered, it takes a checker name for which to look up the ruleset
# and an array of column headers to allow the ruleset to know which indexes to examine in each row array.
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
  end

  def apply(check_name, headers, rows)
    check = get_or_else(@whitelist, check_name, {})
    rules = get_or_else(check, 'rules', [])
    rule_predicates = rules.map { |rule| Whitelist.predicate_for(headers, get_or_else(rule, 'predicate', [])) }
    rows.reject { |row| rule_predicates.any? { |r| r.call(row) } }
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

  def self.predicate_for(headers, conj_hash_arr)
    conjunctions = conj_hash_arr.map { |conj_hash| Whitelist.conjunction_for(headers, conj_hash) }
    lambda { |row| conjunctions.any? { |c| c.call(row) } }
  end

  def self.conjunction_for(headers, conj_hash)
    tests = conj_hash.map { |key_value| Whitelist.test_for(headers, key_value) }
    lambda { |row| tests.all? { |t| t.call(row) } }
  end

  def self.test_for(headers, key_value)
    row_index = headers.find_index(key_value[0])
    lambda { |row| row[row_index] == key_value[1] }
  end

  def self.load(whitelist_file)
    yaml = YAML.load_file(whitelist_file)
    Whitelist.new(yaml ? yaml : {})
  end
end
