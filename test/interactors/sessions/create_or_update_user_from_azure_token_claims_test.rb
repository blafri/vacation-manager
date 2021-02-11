# frozen_string_literal: true

require 'test_helper'

module Sessions
  # Test CreateOrUpdateUserFromTokenClaims interactor
  class CreateOrUpdateUserFromAzureTokenClaimsTest < ActiveSupport::TestCase
    test 'should be a success if the user exists' do
      claims = { 'oid' => 'azure_id_for_hr_admin', 'email' => 'blayne.farinha@thetslgroup.com',
                 'name' => 'Blayne Farinha',
                 'roles' => ['vacationPlanner.hr_admin', 'otherApp.role'] }

      result = Sessions::CreateOrUpdateUserFromAzureTokenClaims.call(claims: claims)
      assert result.success?
    end

    test 'should be a success if user does not exist' do
      claims = { 'oid' => 'oid_does_not_exist', 'email' => 'john.doe@thetslgroup.com',
                 'name' => 'John Doe' }

      result = Sessions::CreateOrUpdateUserFromAzureTokenClaims.call(claims: claims)
      assert result.success?
    end

    test 'should add the user to the context' do
      claims = { 'oid' => 'azure_id_for_hr_admin', 'email' => 'blayne.farinha@thetslgroup.com',
                 'name' => 'Blayne Farinha',
                 'roles' => ['vacationPlanner.hr_admin', 'other_role_for_another_app'] }

      result = Sessions::CreateOrUpdateUserFromAzureTokenClaims.call(claims: claims)
      assert_equal users(:hr_admin), result.user
    end

    test 'should update the user if any attributes changed' do
      claims = { 'oid' => 'azure_id_for_hr_admin', 'email' => 'blayne.new_name@thetslgroup.com',
                 'name' => 'Blayne New Name', 'roles' => ['test_role'] }

      Sessions::CreateOrUpdateUserFromAzureTokenClaims.call!(claims: claims)
      record = users(:hr_admin).reload
      assert_equal 'blayne.new_name@thetslgroup.com', record.email
      assert_equal 'Blayne New Name', record.full_name
      assert_equal ['test_role'], record.roles
    end

    test 'should create the user if user does not exist' do
      claims = { 'oid' => 'oid_does_not_exist', 'email' => 'john.doe@thetslgroup.com',
                 'name' => 'John Doe', 'roles' => ['test_role'] }

      Sessions::CreateOrUpdateUserFromAzureTokenClaims.call!(claims: claims)
      record = User.find_by!(azure_id: 'oid_does_not_exist')
      assert_equal 'john.doe@thetslgroup.com', record.email
      assert_equal 'John Doe', record.full_name
      assert_equal ['test_role'], record.roles
    end

    test 'should not be a success if a required claim is missing' do
      claims = { 'oid' => 'oid_does_not_exist', 'email' => 'john.doe@thetslgroup.com' }

      result = Sessions::CreateOrUpdateUserFromAzureTokenClaims.call(claims: claims)
      assert_not result.success?
      assert_equal({ nil => ["Required claim name was not found"] }, result.errors)
    end

    test 'should add a default value of [] if roles is not present in claims' do
      claims = { 'oid' => 'azure_id_for_hr_admin', 'email' => 'blayne.new_name@thetslgroup.com',
                 'name' => 'Blayne New Name' }

      Sessions::CreateOrUpdateUserFromAzureTokenClaims.call!(claims: claims)
      record = users(:hr_admin).reload
      assert_equal [], record.roles
    end
  end
end
