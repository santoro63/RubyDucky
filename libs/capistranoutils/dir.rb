# A home for Capistrano-related utilities, that is, modules
# to be used within the capistrano environment.
#
# This code makes the following assumptions about its running
# environment
#
#  ** Both local and remote host have openssl installed
#
module CapistranoUtils::Dir 

  # Returns true if the remote and local versions of the filename
  # have a different md5 hash value
  def different_hash?(local_file,remote_file) 
    local_hash = `openssl dgst -md5 #{local_file} `
    remote_hash = capture( "openssl dgst -md5 #{remote_file}" )
    local_hash.split('=')[1] != remote_hash.split('=')[1]
  end

  # Makes the remote destination directory contain the same files
  # as the local source directory. Files that exist only in the 
  # destination directory are removed.
  def mirror_directory(src_dir, dest_dir)
    remote_list = capture("ls #{dest_dir}").split
    local_list = Dir.entries( "#{src_dir}").select { |f| ! f.start_with?('.') }
    new_files = local_list - remote_list
    old_files = remote_list - local_list
    changed_files = (remote_list & local_list).select do |f| 
      different_hash?( "#{src_dir}/#{f}", "#{dest_dir}/#{f}") 
    end
    old_files.each { |file| run "rm #{dest_dir}/#{file}" }
    new_files.each { |file| upload( "#{src_dir}/#{file}", "#{dest_dir}/#{file}" ) }
    changed_files.each { |file| upload( "#{src_dir}/#{file}", "#{dest_dir}/#{file}" ) }
  end
        

end
