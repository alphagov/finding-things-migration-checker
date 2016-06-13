require 'yaml'
require 'whitelist/whitelist'

RSpec.describe Whitelist do
  it "whitelists rows based on a single field" do
    whitelist = create_whitelist(
      '
      test_check:
        rules:
          - predicate:
            - b: "z"
      '
    )

    headers = %w(id a b)

    rows = [
        %w(1 a b),
        %w(2 a z),
        %w(3 a b),
    ]

    expected_rows = [
        %w(1 a b),
        %w(3 a b),
    ]

    expect(whitelist.apply('test_check', headers, rows)).to eq(expected_rows)
  end

  it "whitelists rows based on a multiple fields" do
    whitelist = create_whitelist(
      '
      test_check:
        rules:
          - predicate:
            - a: "z"
              b: "z"
      '
    )

    headers = %w(id a b)

    rows = [
        %w(1 a b),
        %w(2 a z),
        %w(3 z b),
        %w(4 z z),
    ]

    expected_rows = [
        %w(1 a b),
        %w(2 a z),
        %w(3 z b),
    ]

    expect(whitelist.apply('test_check', headers, rows)).to eq(expected_rows)
  end

  it "whitelists rows based on a disjunction of conjunctions" do
    whitelist = create_whitelist(
      '
      test_check:
        rules:
          - predicate:
            - a: "z"
              b: "z"
            - id: "3"
      '
    )

    headers = %w(id a b)

    rows = [
        %w(1 a b),
        %w(2 a z),
        %w(3 z b),
        %w(4 z z),
    ]

    expected_rows = [
        %w(1 a b),
        %w(2 a z),
    ]

    expect(whitelist.apply('test_check', headers, rows)).to eq(expected_rows)
  end

  it "doesn't whitelist rows where no predicate data is provided" do
    whitelist = create_whitelist(
      '
      test_check:
        rules:
          - predicate:
      '
    )

    headers = %w(id a b)

    rows = [
        %w(1 a b),
        %w(2 a b),
        %w(3 a c),
    ]

    expect(whitelist.apply('test_check', headers, rows)).to eq(rows)
  end


  it "doesn't whitelist rows where no rules are provided" do
    whitelist = create_whitelist(
      '
      test_check:
        rules:
      '
    )

    headers = %w(id a b)

    rows = [
        %w(1 a b),
        %w(2 a b),
        %w(3 a c),
    ]

    expect(whitelist.apply('test_check', headers, rows)).to eq(rows)
  end

  it "doesn't whitelist rows where no check data is provided" do
    whitelist = create_whitelist(
      '
      different_test_check:
        rules:
      '
    )

    headers = %w(id a b)

    rows = [
        %w(1 a b),
        %w(2 a b),
        %w(3 a c),
    ]

    expect(whitelist.apply('test_check', headers, rows)).to eq(rows)
  end

  it "constructs a conjunction predicate" do
    headers = %w(id a b)
    conj_hash = {
        'a' => 'foo',
        'b' => 'bar',
    }
    conj_predicate = Whitelist::Predicate.conjunction_for(headers, conj_hash)

    expect(conj_predicate.call([1, 'foo', 'bar'])).to eq(true)
    expect(conj_predicate.call([2, 'foo', 'bar'])).to eq(true)
    expect(conj_predicate.call([1, 'foo', 'whatever'])).to eq(false)
    expect(conj_predicate.call([1, 'whatever', 'bar'])).to eq(false)
  end

  it "constructs a disjunction predicate" do
    headers = %w(id a b)
    conj_hash_arr = [
      {
        'a' => 'foo',
        'b' => 'bar',
      },
      {
        'id' => '3'
      }
    ]
    conj_predicate = Whitelist::Predicate.predicate_for(headers, conj_hash_arr)

    expect(conj_predicate.call(%w(1 foo bar))).to eq(true)
    expect(conj_predicate.call(%w(3 foo bar))).to eq(true)
    expect(conj_predicate.call(%w(1 foo whatever))).to eq(false)
    expect(conj_predicate.call(%w(1 whatever bar))).to eq(false)
    expect(conj_predicate.call(%w(3 whatever bar))).to eq(true)
  end

  it "constructs a value-testing predicate" do
    headers = %w(id a b)
    key_value = %w(a foo)

    test_predicate = Whitelist::Predicate.test_for(headers, key_value)

    expect(test_predicate.call(%w(1 foo bar))).to eq(true)
    expect(test_predicate.call(%w(3 foo bar))).to eq(true)
    expect(test_predicate.call(%w(1 foo whatever))).to eq(true)
    expect(test_predicate.call(%w(1 whatever bar))).to eq(false)
  end

  it "detects null values using a value-testing predicate" do
    headers = %w(id a b)
    key_value = ['a', nil]

    test_predicate = Whitelist::Predicate.test_for(headers, key_value)

    expect(test_predicate.call(%w(1 foo bar))).to eq(false)
    expect(test_predicate.call(['1', nil, 'bar'])).to eq(true)
  end

  it "reports expired whitelist entries" do
    whitelist = create_whitelist(
      '
      test_check_1:
        rules:
          - expiry: "2016-05-19"
            reason: "foo"
          - expiry: "2016-06-20"
            reason: "bar"
          - expiry: "2017-07-22"
            reason: "baz"
      test_check_2:
        rules:
          - expiry: "2016-05-19"
            reason: "quux"
      '
    )

    expected_expires = [
      ['test_check_1', '2016-05-19', 'foo'],
      ['test_check_1', '2016-06-20', 'bar'],
      ['test_check_2', '2016-05-19', 'quux'],
    ]

    expect(whitelist.report_expired_entries(Date.parse('2016-07-05'))).to eq(expected_expires)
  end

  it "reports unused whitelist entries" do
    whitelist = create_whitelist(
      '
      test_check_1:
        rules:
          - expiry: "2016-05-19"
            reason: "foo"
            predicate:
              - a: "x"
          - expiry: "2016-06-20"
            reason: "bar"
            predicate:
              - a: "y"
          - expiry: "2017-07-22"
            reason: "baz"
            predicate:
              - a: "z"
      '
    )

    headers = %w(id a)

    rows = [
      %w(1 x),
      %w(2 y),
      %w(3 a),
      %w(4 b),
    ]
    expected_rows = [
      %w(3 a),
      %w(4 b),
    ]

    whitelister = whitelist.get_whitelister('test_check_1', headers)
    expect(rows.reject(&whitelister.whitelist_function)).to eq(expected_rows)
    expect(whitelister.unused_entries.size).to eq(1)
    expect(whitelister.unused_entries[0].reason).to eq("baz")
  end

  def create_whitelist(yaml_string)
    Whitelist.new(YAML.load(yaml_string))
  end
end
