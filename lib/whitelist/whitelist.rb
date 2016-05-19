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
    # can't use #fetch since it returns nil if the key exists but maps to nil
    value = hash[key]
    value ? value : default
  end

  def report_expired_entries(reference_date)
    expiries = @whitelist.flat_map { |check| get_or_else(check[1], 'rules', []).map { |rule| [check[0], rule['expiry'], rule['reason']]} }
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
    Whitelist.new(YAML.load_file(whitelist_file))
  end
end
