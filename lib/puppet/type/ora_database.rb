require 'pathname'
$:.unshift(Pathname.new(__FILE__).dirname.parent.parent)
$:.unshift(Pathname.new(__FILE__).dirname.parent.parent.parent.parent + 'easy_type' + 'lib')
require 'easy_type'
require 'ora_utils/oracle_access'
require 'ora_utils/ora_tab'


module Puppet
  newtype(:ora_database) do
    include EasyType
    include ::OraUtils::OracleAccess


    desc "This resource allows you to manage an Oracle Database."

    set_command(:sql)

    ensurable

    to_get_raw_resources do
      available_database.collect {|e| EasyType::Helpers::InstancesResults['name',e]}
    end

    on_create do | command_builder |
      create_directories
      create_init_ora_file
      add_oratab_entry

      statement = template('puppet:///modules/oracle/create_database.sql.erb', binding)
      command_builder.add(statement, :sid => name) 
    end

    on_modify do | command_builder |
      info "database modification not yet implemented"
    end

    on_destroy do | command_builder |
      Puppet
      statement = template('puppet:///modules/oracle/drop_database.sql.erb', binding)
      FileUtils.rm_rf "#{oracle_base}/admin/#{name}"
      FileUtils.rm_rf "#{oracle_home}/dbs/init#{name}.ora"
      FileUtils.rm_rf "#{oracle_base}/cfgtoolslog/dbca/#{name}"
      nil
    end

    parameter :name
    parameter :system_password
    parameter :sys_password
    parameter :init_ora_content
    parameter :timeout
    parameter :control_file
    property  :maxdatafiles
    property  :maxinstances
    property  :character_set
    property  :national_character_set
    property  :tablespace_type
    property  :logfile
    property  :logfile_groups
    property  :maxlogfiles
    property  :maxlogmembers
    property  :maxloghistory
    property  :archivelog
    property  :force_logging
    property  :extent_management
    property  :datafiles
    property  :sysaux_datafiles
    group(:default_tablespace_group) do
      property  :default_tablespace_type
      property  :default_tablespace_name
      property  :default_tablespace_datafiles
      property  :default_tablespace_extent_management
    end
    group(:default_temporary_tablespace_group) do
      property  :default_temporary_tablespace_type
      property  :default_temporary_tablespace_name
      property  :default_temporary_tablespace_datafiles
      property  :default_temporary_tablespace_extent_management
    end
    group(:undo_tablespace_group) do
      property  :undo_tablespace_type
      property  :undo_tablespace_name
      property  :undo_tablespace_datafiles
    end
		parameter :oracle_home
		parameter :oracle_base
		parameter :oracle_user
		parameter :install_group
		parameter :autostart
    # -- end of attributes -- Leave this comment if you want to use the scaffolder


    private

    def create_directories
      make_oracle_directory oracle_base
      make_oracle_directory oracle_home
      make_oracle_directory "#{oracle_home}/dbs"
      make_oracle_directory "#{oracle_base}/admin/#{name}"
      make_oracle_directory "#{oracle_base}/admin/#{name}/adump"
      make_oracle_directory "#{oracle_base}/admin/#{name}/ddump"
      make_oracle_directory "#{oracle_base}/admin/#{name}/hdump"
      make_oracle_directory "#{oracle_base}/admin/#{name}/pfile"
      make_oracle_directory "#{oracle_base}/admin/#{name}/scripts"
      make_oracle_directory "#{oracle_base}/cfgtoollogs/dbca/#{name}"
    end

    def create_init_ora_file
      File.open(init_ora_path, 'w') { |f| f.write(init_ora_content) }
      ownened_by_oracle( init_ora_path)
      Puppet.debug "File #{init_ora_path} created with specified init.ora content"
    end

    def add_oratab_entry
      oratab = OraUtils::OraTab.new
      oratab.ensure_entry(name, oracle_home, autostart)
    end

    def make_oracle_directory(path)
      Puppet.debug "creating directory #{path}"
      FileUtils.mkdir_p path
      ownened_by_oracle(path)
    end

    def ownened_by_oracle(*path)
      Puppet.debug "Setting ownership for #{path}"
      FileUtils.chmod 0775, path
      FileUtils.chown oracle_user, install_group, path
    end

    def init_ora_path
      "#{oracle_home}/dbs/init#{name}.ora"
    end

    #
    # For now use a hard coded Oracle base path
    #
    def self.available_database
      Pathname.glob('/opt/oracle/admin/*').collect {|e| e.basename.to_s}
    end
  end
end