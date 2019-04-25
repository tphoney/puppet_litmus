# frozen_string_literal: true

# helper functions for running puppet commands, and helpers
module PuppetLitmus::Serverspec
require 'pry'
  def idempotent_apply(manifest)
    result = bolt_apply_manifest(manifest)
    return result if result['status'] != 'success' 
    result = bolt_apply_manifest(manifest)
    return false if result['result']['report']['status'] != 'unchanged' 
  end

  def bolt_apply_manifest(manifest, opts = {})
    target_node_name = ENV['TARGET_HOST']
    raise 'manifest and manifest_file_location in the opts hash are mutually exclusive arguments, pick one' if !manifest.nil? && !opts[:manifest_file_location].nil?
    raise 'please pass a manifest or the manifest_file_location in the opts hash' if (manifest.nil? || manifest == '') && opts[:manifest_file_location].nil?

    #manifest_file_location = create_manifest_file(manifest) unless manifest.nil?
    #manifest_file_location = opts[:manifest_file_location] unless opts[:manifest_file_location].nil?
    inventory_hash = if target_node_name.nil? || target_node_name == 'localhost'
                       nil
                     else
                       inventory_hash_from_inventory_file
                     end
    #command_to_run = "puppet apply #{manifest_file_location}"
    #command_to_run += " --modulepath #{Dir.pwd}/spec/fixtures/modules" if target_node_name.nil? || target_node_name == 'localhost'
    #command_to_run += ' --detailed-exitcodes' if !opts[:catch_changes].nil? && (opts[:catch_changes] == true)
    config_data = { 'modulepath' => File.join(Dir.pwd, 'spec', 'fixtures', 'modules') }
    # apply_manifest(manifest, targets, execute: false, noop: false, config: nil, inventory: nil)

    result = apply_manifest(manifest, target_node_name, execute: true, noop: false, config: config_data, inventory: inventory_hash)
#    result = run_command(command_to_run, target_node_name, config: nil, inventory: inventory_hash)

 #   raise "apply mainfest failed\n`#{command_to_run}`\n======\n#{result}" if result.first['result']['exit_code'] != 0 && opts[:expect_failures] != true

    result.first
  end

  # creates a temp manifest file locally & remote depending on target
  def create_manifest_file(manifest)
    manifest_file = Tempfile.new(['manifest_', '.pp'])
    manifest_file.write(manifest)
    manifest_file.close
#    if target_node_name.nil? || target_node_name == 'localhost'
#      # no need to transfer
      manifest_file_location = manifest_file.path
#    else
#      # transfer to TARGET_HOST
#      inventory_hash = inventory_hash_from_inventory_file
#      manifest_file_location = "/tmp/#{File.basename(manifest_file)}"
#      result = upload_file(manifest_file.path, manifest_file_location, target_node_name, options: {}, config: nil, inventory: inventory_hash)
#      raise result.first['result'].to_s unless result.first['status'] == 'success'
#    end
    manifest_file_location
  end

  def run_shell(command_to_run, opts = {})
    inventory_hash = inventory_hash_from_inventory_file
    target_node_name = ENV['TARGET_HOST']
    result = run_command(command_to_run, target_node_name, config: nil, inventory: inventory_hash)

    raise "shell failed\n`#{command_to_run}`\n======\n#{result}" if result.first['result']['exit_code'] != 0 && opts[:expect_failures] != true

    result
  end

  # Runs a selected task against the target host. Parameters should be passed in with a hash format.
  def run_bolt_task(task_name, params)
    config_data = { 'modulepath' => File.join(Dir.pwd, 'spec', 'fixtures', 'modules') }
    inventory_hash = inventory_hash_from_inventory_file
    target_node_name = ENV['TARGET_HOST'] if target_node_name.nil?

    result = run_task(task_name, target_node_name, params, config: config_data, inventory: inventory_hash)

    raise "task failed\n`#{task_name}`\n======\n#{result}" if result.first['status'] != 'success'

    result
  end
end
