# frozen_string_literal: true

require_relative '../environment'

class MaterializedPathTest < ActiveSupport::TestCase
  def test_ancestry_column_values
    assert true, "this runs if materialized path"
    return if AncestryTestDatabase.materialized_path2?

    AncestryTestDatabase.with_model do |model|
      root = model.create!
      node = model.new

      # new node
      assert_ancestry node, nil
      assert_raises(Ancestry::AncestryException) { node.child_ancestry }

      # saved
      node.save!
      assert_ancestry node, nil, child: node.id.to_s

      # changed
      node.ancestor_ids = [root.id]
      assert_ancestry node, root.id.to_s, db: nil, child: node.id.to_s

      # changed saved
      node.save!
      assert_ancestry node, root.id.to_s, child: "#{root.id}/#{node.id}"

      # reloaded
      node.reload
      assert_ancestry node, root.id.to_s, child: "#{root.id}/#{node.id}"

      # fresh node
      node = model.find(node.id)
      assert_ancestry node, root.id.to_s, child: "#{root.id}/#{node.id}"
    end
  end

  def test_ancestry_column_validation
    assert true, "this runs if materialized path"
    return if AncestryTestDatabase.materialized_path2?

    AncestryTestDatabase.with_model do |model|
      node = model.create # assuming id == 1
      ['3', '10/2', '9/4/30', model.ancestry_root].each do |value|
        node.send :write_attribute, model.ancestry_column, value
        assert node.sane_ancestor_ids?
        assert node.valid?
      end
    end
  end

  def test_ancestry_column_validation_fails
    assert true, "this runs if materialized path"
    return if AncestryTestDatabase.materialized_path2?

    AncestryTestDatabase.with_model do |model|
      node = model.create
      ['a', 'a/b', '-34'].each do |value|
        node.send :write_attribute, model.ancestry_column, value
        refute node.sane_ancestor_ids?
        refute node.valid?
      end
    end
  end

  def test_ancestry_column_validation_string_key
    assert true, "this runs if materialized path"
    return if AncestryTestDatabase.materialized_path2?

    AncestryTestDatabase.with_model(:id => :string, :primary_key_format => /[a-z]/) do |model|
      node = model.create(:id => 'z')
      ['a', 'a/b', 'a/b/c', model.ancestry_root].each do |value|
        node.send :write_attribute, model.ancestry_column, value
        assert node.sane_ancestor_ids?
        assert node.valid?
      end
    end
  end

  def test_ancestry_column_validation_string_key_fails
    assert true, "this runs if materialized path"
    return if AncestryTestDatabase.materialized_path2?

    AncestryTestDatabase.with_model(:id => :string, :primary_key_format => /[a-z]/) do |model|
      node = model.create(:id => 'z')
      ['1', '1/2', 'a-b/c'].each do |value|
        node.send :write_attribute, model.ancestry_column, value
        refute node.sane_ancestor_ids?
        refute node.valid?
      end
    end
  end

  def test_ancestry_validation_exclude_self
    assert true, "this runs if materialized path"
    return if AncestryTestDatabase.materialized_path2?

    AncestryTestDatabase.with_model do |model|
      parent = model.create!
      child = parent.children.create!
      assert_raise ActiveRecord::RecordInvalid do
        parent.parent = child
        refute parent.sane_ancestor_ids?
        parent.save!
      end
    end
  end

  def test_ancestry_column_values_with_custom_column_key
    options = {ancestry_target_column_key: :custom_key, extra_columns: {custom_key: :integer}}

    AncestryTestDatabase.with_model(options) do |model|
      root = model.create!(custom_key: 100)
      node = model.new

      # new node
      assert_ancestry node, nil
      assert_raises(Ancestry::AncestryException) { node.child_ancestry }

      # saved
      node.save!
      assert_ancestry node, nil, child: node.custom_key.to_s

      # changed
      node.ancestor_ids = [root.custom_key]
      assert_ancestry node, root.custom_key.to_s, db: nil, child: node.custom_key.to_s

      # changed saved
      node.custom_key = 200
      node.save!
      assert_ancestry node, root.custom_key.to_s, child: "#{root.custom_key}/#{node.custom_key}"

      # reloaded
      node.reload
      assert_ancestry node, root.custom_key.to_s, child: "#{root.custom_key}/#{node.custom_key}"
    end
  end

  def test_ancestry_column_validation_with_custom_column_key
    assert true, "this runs if materialized path"
    return if AncestryTestDatabase.materialized_path2?
    options = {ancestry_target_column_key: :custom_key, extra_columns: {custom_key: :integer}}

    AncestryTestDatabase.with_model(options) do |model|
      node = model.create(custom_key: 100) # assuming id == 1
      ['100', '100/200', '100/200/4', model.ancestry_root].each do |value|
        node.send :write_attribute, model.ancestry_column, value
        assert node.sane_ancestor_ids?
        assert node.valid?
      end
    end
  end

  def test_ancestry_column_validation_fails_with_custom_column_key
    assert true, "this runs if materialized path"
    return if AncestryTestDatabase.materialized_path2?
    options = {ancestry_target_column_key: :custom_key, extra_columns: {custom_key: :integer}}

    AncestryTestDatabase.with_model(options) do |model|
      node = model.create
      ['a', 'a/b', '-34'].each do |value|
        node.send :write_attribute, model.ancestry_column, value
        refute node.sane_ancestor_ids?
        refute node.valid?
      end
    end
  end

  def test_ancestry_column_validation_string_key_with_custom_column_key
    assert true, "this runs if materialized path"
    return if AncestryTestDatabase.materialized_path2?
    options = {ancestry_target_column_key: :custom_key, extra_columns: {custom_key: :string}, ancestry_target_column_key_format: /[a-z]/}

    AncestryTestDatabase.with_model(options) do |model|
      node = model.create(:id => 'z')
      ['a', 'a/b', 'a/b/c', model.ancestry_root].each do |value|
        node.send :write_attribute, model.ancestry_column, value
        assert node.sane_ancestor_ids?
        assert node.valid?
      end
    end
  end

  def test_ancestry_column_validation_string_key_fails_with_custom_column_key
    assert true, "this runs if materialized path"
    return if AncestryTestDatabase.materialized_path2?
    options = {ancestry_target_column_key: :custom_key, extra_columns: {custom_key: :string}, ancestry_target_column_key_format: /[a-z]/}

    AncestryTestDatabase.with_model(options) do |model|
      node = model.create(:id => 'z')
      ['1', '1/2', 'a-b/c'].each do |value|
        node.send :write_attribute, model.ancestry_column, value
        refute node.sane_ancestor_ids?
        refute node.valid?
      end
    end
  end
end
