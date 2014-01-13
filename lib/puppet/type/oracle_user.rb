require 'simple_resource'
require 'utils/oracle_access'

module Puppet
  #
  # Create a new type oracle_user. Oracle user, works in conjunction 
  # with the SqlResource provider
  #
  newtype(:oracle_user) do
    include SimpleResource
    include Utils::OracleAccess

    desc %q{
      This resource allows you to manage a user in an Oracle database.
    }

    ensurable

    set_command(:sql)


    to_get_raw_resources do
      sql "select * from dba_users"
    end

    on_create do
      "create user #{name}"
    end

    on_modify do
      "alter user #{name}"
    end

    on_destroy do
      "drop user #{name}"
    end

    parameter :name
    property  :user_id
    property  :password
    property  :default_tablespace
    property  :temporary_tablespace
    property  :grants
    property  :quotas

  end
end
