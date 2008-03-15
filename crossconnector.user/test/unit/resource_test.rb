# An enormous thanks goes to Sebastian Kanthak
# for his work on FileColumn 
# http://www.kanthak.net/opensource/file_column/
# 
# These tests have been adapted from the ones included in 
# the FileColumn plugin located in 
# vendor/plugins/file_column/test
# 
# Tests should continue to work even if FileColumn plugin
# is updated. 

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../abstract_unit'
require File.dirname(__FILE__) + '/../fixtures/resource'

class TempHomebase < ActiveRecord::Base
  set_table_name 'homebases'
end

class ResourceTest < Test::Unit::TestCase
  fixtures :subscription_plans, :homebases, :users, :resources, :addresses, :groups, :addresses_groups, :addresses_resources, :groups_resources

  def setup
    # we define the file_columns here so that we can change
    # settings easily in a single test

    Resource.file_column :file
    Image.file_column :file
    Homebase.file_column :logo

    clear_validations
    
    Homebase.current_homebase = homebases(:haiti_homebase)
  end
  
  def teardown
    FileUtils.rm_rf File.dirname(__FILE__)+"/public/logo/"
    FileUtils.rm_rf File.dirname(__FILE__)+"/public/file/"
    FileUtils.rm_rf File.dirname(__FILE__)+"/public/my_store_dir/"
  end
  
  def test_column_write_method
    assert Resource.new.respond_to?("file=")
    assert Image.new.respond_to?("file=")
    assert Homebase.new.respond_to?("logo=")
  end
  
  def test_column_read_method
    assert Resource.new.respond_to?("file")
    assert Image.new.respond_to?("file")
    assert Homebase.new.respond_to?("logo")
  end
  
  def test_sanitize_filename
    assert_equal "test.jpg", FileColumn::sanitize_filename("test.jpg")
    assert FileColumn::sanitize_filename("../../very_tricky/foo.bar") !~ /[\\\/]/, "slashes not removed"
    assert_equal "__foo", FileColumn::sanitize_filename('`*foo')
    assert_equal "foo.txt", FileColumn::sanitize_filename('c:\temp\foo.txt')
    assert_equal "_.", FileColumn::sanitize_filename(".")
  end
  
  def test_default_options
    e = Resource.new
    assert_match %r{/file_column/resource/file}, e.file_options[:store_dir]
    assert_match %r{/file_column/resource/file/tmp}, e.file_options[:tmp_base_dir]
  end
  
  def test_assign_without_save_with_tempfile
    do_test_assign_without_save(:tempfile)
  end
  
  def test_assign_without_save_with_stringio
    do_test_assign_without_save(:stringio)
  end
  
  def do_test_assign_without_save(upload_type)
    e = Resource.new
    e.file = uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png", upload_type)
    assert e.file.is_a?(String), "#{e.file.inspect} is not a String"
    assert File.exists?(e.file)
    assert FileUtils.identical?(e.file, file_path("skanthak.png"))
  end
  
  def test_filename_preserved
    e = Resource.new
    e.file = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "local_filename.jpg")
    assert_equal "local_filename.jpg", File.basename(e.file)
  end
  
  def test_filename_stored_in_attribute
    e = Resource.new("file" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    assert_equal "kerb.jpg", e["file"]
  end
  
  def test_extension_added
    e = Resource.new
    e.file = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "local_filename")
    assert_equal "local_filename.jpg", File.basename(e.file)
    assert_equal "local_filename.jpg", e["file"]
  end
  
  def test_no_extension_without_content_type
    e = Resource.new
    e.file = uploaded_file(file_path("skanthak.png"), "something/unknown", "local_filename")
    assert_equal "local_filename", File.basename(e.file)
    assert_equal "local_filename", e["file"]
  end
  
  def test_extension_unknown_type
    e = Resource.new
    e.file = uploaded_file(file_path("kerb.jpg"), "not/known", "local_filename")
    assert_equal "local_filename", File.basename(e.file)
    assert_equal "local_filename", e["file"]
  end

  def test_extension_unknown_type_with_extension
    e = Resource.new
    e.file = uploaded_file(file_path("kerb.jpg"), "not/known", "local_filename.abc")
    assert_equal "local_filename.abc", File.basename(e.file)
    assert_equal "local_filename.abc", e["file"]
  end
  
  def test_extension_corrected
    e = Resource.new
    e.file = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "local_filename.jpeg")
    assert_equal "local_filename.jpg", File.basename(e.file)
    assert_equal "local_filename.jpg", e["file"]
  end
  
  def test_double_extension
    e = Resource.new
    e.file = uploaded_file(file_path("kerb.jpg"), "application/x-tgz", "local_filename.tar.gz")
    assert_equal "local_filename.tar.gz", File.basename(e.file)
    assert_equal "local_filename.tar.gz", e["file"]
  end
  
  FILE_UTILITY = "/usr/bin/file"

  def test_get_content_type_with_file
    Resource.file_column :file, :file_exec => FILE_UTILITY

    # run this test only if the machine we are running on
    # has the file utility installed
    if File.executable?(FILE_UTILITY)
      e = Resource.new
      file = FileColumn::TempUploadedFile.new(e, "file")
      file.instance_variable_set :@dir, File.dirname(file_path("kerb.jpg"))
      file.instance_variable_set :@filename, File.basename(file_path("kerb.jpg"))
      
      assert_equal "image/jpeg", file.get_content_type
    else
      puts "Warning: Skipping test_get_content_type_with_file test as '#{options[:file_exec]}' does not exist"
    end
  end
  
  def test_fix_extension_with_file
    Resource.file_column :file, :file_exec => FILE_UTILITY

    # run this test only if the machine we are running on
    # has the file utility installed
    if File.executable?(FILE_UTILITY)
      e = Resource.new(:file => uploaded_file(file_path("skanthak.png"), "", "skanthak.jpg"))
      
      assert_equal "skanthak.png", File.basename(e.file)
    else
      puts "Warning: Skipping test_fix_extension_with_file test as '#{options[:file_exec]}' does not exist"
    end
  end
  
  def test_do_not_fix_file_extensions
    Resource.file_column :file, :fix_file_extensions => false
    e = Resource.new(:file => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb"))
    assert_equal "kerb", File.basename(e.file)
  end
  
  def test_correct_extension
    e = Resource.new
    file = FileColumn::TempUploadedFile.new(e, "file")
    
    assert_equal "filename.jpg", file.correct_extension("filename.jpeg","jpg")
    assert_equal "filename.tar.gz", file.correct_extension("filename.jpg","tar.gz")
    assert_equal "filename.jpg", file.correct_extension("filename.tar.gz","jpg")
    assert_equal "Protokoll_01.09.2005.doc", file.correct_extension("Protokoll_01.09.2005","doc")
    assert_equal "strange.filenames.exist.jpg", file.correct_extension("strange.filenames.exist","jpg")
    assert_equal "another.strange.one.jpg", file.correct_extension("another.strange.one.png","jpg")
    assert_equal "excel_file.xls", file.correct_extension("excel_file","xls")
    assert_equal "word_document.doc", file.correct_extension("word_document","doc")
    
  end
  
  def test_assign_with_save
    Homebase.current_homebase = Homebase.find(1)
    e = Resource.new
    e.file = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg")
    tmp_file_path = e.file
    assert e.save
    assert File.exists?(e.file)
    assert FileUtils.identical?(e.file, file_path("kerb.jpg"))
    assert_equal "#{e.id}/kerb.jpg", e.file_relative_path
    assert !File.exists?(tmp_file_path), "temporary file '#{tmp_file_path}' not removed"
    assert !File.exists?(File.dirname(tmp_file_path)), "temporary directory '#{File.dirname(tmp_file_path)}' not removed"
    
    local_path = e.file
    e = Resource.find(e.id)
    assert_equal local_path, e.file
  end
  
  def test_dir_methods
    Resource.file_column :file, {:store_dir => :my_store_dir, :root_path => App::CONFIG[:app_ftp_root]}
    e = Resource.new
    e.file = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg")
    e.save
    
    assert_equal File.expand_path(File.join(App::CONFIG[:app_ftp_root], "my_store_dir", e.id.to_s)),
    e.file_dir
    assert_equal File.join(e.id.to_s), 
    e.file_relative_dir
  end
  
  def test_store_dir_callback
    Resource.file_column :file, {:store_dir => :my_store_dir, :root_path => App::CONFIG[:app_ftp_root]}
    e = Resource.new
    e.file = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg")    
    assert e.save
    assert_equal File.expand_path(File.join(App::CONFIG[:app_ftp_root], "my_store_dir", e.id.to_s)), e.file_dir   
  end
  
  def test_tmp_dir_with_store_dir_callback
    Resource.file_column :file, {:store_dir => :my_store_dir, :root_path => App::CONFIG[:app_ftp_root]}
    e = Resource.new
    e.file = upload(f("kerb.jpg"))
    
    assert_equal File.expand_path(File.join(App::CONFIG[:app_ftp_root], "my_store_dir", "tmp")), File.expand_path(File.join(e.file_dir,".."))
  end
  
  def test_invalid_store_dir_callback
    Resource.file_column :file, {:store_dir => :my_store_dir_doesnt_exit}    
    e = Resource.new
    assert_raise(ArgumentError) {
      e.file = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg")
      e.save
    }
  end
  
  def test_subdir_parameter
    e = Resource.new
    assert_nil e.file("thumb")
    assert_nil e.file_relative_path("thumb")
    assert_nil e.file(nil)
    e.file = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg")
    assert_equal "kerb.jpg", File.basename(e.file("thumb"))
    assert_equal "kerb.jpg", File.basename(e.file_relative_path("thumb"))
    assert_equal File.join(e.file_dir,"thumb","kerb.jpg"), e.file("thumb")
    assert_match %r{/thumb/kerb\.jpg$}, e.file_relative_path("thumb") 
    assert_equal e.file, e.file(nil)
    assert_equal e.file_relative_path, e.file_relative_path(nil)
  end
  
  
  
  def test_absolute_path_outside_rails_root
    # We might want to store a file on another file system
    Homebase.current_homebase = Homebase.find(1)
    Resource.file_column :file, {:store_dir => File.join(App::CONFIG[:app_ftp_root], Homebase.current_homebase.subdomain, "files"), :root_path => "/usr/home/ryenski/AppFTPRoot"}
    e = Resource.new
    e.file = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg")
    assert File.exists?(e.file)
    assert e.file !~ /\.\./, "#{e.file} is not a simple path"
    #assert_equal "foo", e.file
    assert_match %r{/Library/WebServer/AppFTPRoot/haiti/files}, e.file
  end
  
  def test_cleanup_after_destroy
    e = Resource.new("file" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    assert e.save
    local_path = e.file
    assert File.exists?(local_path)
    assert e.destroy
    assert !File.exists?(local_path), "'#{local_path}' still exists although entry was destroyed"
    assert !File.exists?(File.dirname(local_path))
  end
  
  def test_keep_tmp_file
    e = Resource.new("file" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    e.validation_should_fail = true
    assert !e.save, "e should not save due to validation errors"
    assert File.exists?(local_path = e.file)
    file_temp = e.file_temp
    e = Resource.new("file_temp" => file_temp)
    assert_equal local_path, e.file
    assert e.save
    assert FileUtils.identical?(e.file, file_path("kerb.jpg"))
  end
  
  def test_keep_tmp_file_with_existing_file
    e = Resource.new("file" =>uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    assert e.save
    assert File.exists?(local_path = e.file)
    e = Resource.find(e.id)
    e.file = uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png")
    e.validation_should_fail = true
    assert !e.save
    temp_path = e.file_temp
    e = Resource.find(e.id)
    e.file_temp = temp_path
    assert e.save
    
    assert FileUtils.identical?(e.file, file_path("skanthak.png"))
    assert !File.exists?(local_path), "old file has not been deleted"
  end
  
  def test_replace_tmp_file_temp_first
    do_test_replace_tmp_file([:file_temp, :file])
  end
  
  def test_replace_tmp_file_temp_last
    do_test_replace_tmp_file([:file, :file_temp])
  end
  
  def do_test_replace_tmp_file(order)
    e = Resource.new("file" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    e.validation_should_fail = true
    assert !e.save
    file_temp = e.file_temp
    temp_path = e.file
    new_img = uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png")
    e = Resource.new
    for method in order
      case method
      when :file_temp then e.file_temp = file_temp
      when :file then e.file = new_img
      end
    end
    assert e.save
    assert FileUtils.identical?(e.file, file_path("skanthak.png")), "'#{e.file}' is not the expected 'skanthak.png'"
    assert !File.exists?(temp_path), "temporary file '#{temp_path}' is not cleaned up"
    assert !File.exists?(File.dirname(temp_path)), "temporary directory not cleaned up"
    assert e.file_just_uploaded?
  end
  
  def test_replace_file_on_saved_object
    e = Resource.new("file" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    assert e.save
    old_file = e.file
    e = Resource.find(e.id)
    e.file = uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png")
    assert e.save
    assert FileUtils.identical?(file_path("skanthak.png"), e.file)
    assert old_file != e.file
    assert !File.exists?(old_file), "'#{old_file}' has not been cleaned up"
  end
  
  def test_edit_without_touching_file
    e = Resource.new("file" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    assert e.save
    e = Resource.find(e.id)
    assert e.save
    assert FileUtils.identical?(file_path("kerb.jpg"), e.file)
  end
  
  def test_save_without_file
    e = Resource.new
    assert e.save
    e.reload
    assert_nil e.file
  end
  
  def test_delete_saved_file
    e = Resource.new("file" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    assert e.save
    local_path = e.file
    e.file = nil
    assert_nil e.file
    assert File.exists?(local_path), "file '#{local_path}' should not be deleted until transaction is saved"
    assert e.save
    assert_nil e.file
    assert !File.exists?(local_path)
    e.reload
    assert e["file"].blank?
    e = Resource.find(e.id)
    assert_nil e.file
  end
  
  def test_delete_tmp_file
    e = Resource.new("file" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    local_path = e.file
    e.file = nil
    assert_nil e.file
    assert !File.exists?(local_path)
  end
  
  def test_delete_nonexistant_file
    r = Resource.new
    r.file = nil
    assert r.save
    assert_nil r.file
  end
  
  def test_delete_file_on_non_null_column
    
    e = Resource.new("file" => upload(f("skanthak.png")))
    assert e.save

    local_path = e.file
    assert File.exists?(local_path)
    e.file = nil
    assert e.save
    assert !File.exists?(local_path)
  end
  
  def test_ie_filename
    e = Resource.new("file" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", 'c:\files\kerb.jpg'))
    assert e.file_relative_path =~ /^tmp\/[\d\.]+\/kerb\.jpg$/, "relative path '#{e.file_relative_path}' was not as expected"
    assert File.exists?(e.file)
  end
  
  def test_just_uploaded?
    e = Resource.new("file" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", 'c:\files\kerb.jpg'))
    assert e.file_just_uploaded?
    assert e.save
    assert e.file_just_uploaded?
    
    e = Resource.new("file" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", 'kerb.jpg'))
    temp_path = e.file_temp
    e = Resource.new("file_temp" => temp_path)
    assert !e.file_just_uploaded?
    assert e.save
    assert !e.file_just_uploaded?
  end
  
  def test_empty_tmp
    e = Resource.new
    e.file_temp = ""
    assert_nil e.file
  end
  
  def test_empty_tmp_with_file
    e = Resource.new
    e.file_temp = ""
    e.file = uploaded_file(file_path("kerb.jpg"), "image/jpeg", 'c:\files\kerb.jpg')
    local_path = e.file
    assert File.exists?(local_path)
    e.file_temp = ""
    assert local_path, e.file
  end
  
  def test_empty_filename
    e = Resource.new
    assert_nil e["file"]
    assert_nil e.file
    assert_nil e["file"]
    assert_nil e.file
  end
  
  def test_with_two_models
    #Homebase.current_homebase = Homebase.find(1)
    e = Resource.new(:file => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    h = Image.new(:file => uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png"))
    assert e.save
    assert h.save
    assert_match %{/resource/file/}, e.file
    assert_match %{/image/file/}, h.file
    assert FileUtils.identical?(e.file, file_path("kerb.jpg"))
    assert FileUtils.identical?(h.file, file_path("skanthak.png"))
    
    #assert_equal "foo", "#{file_path("skanthak.png")} \n #{h.logo}"
    #assert_equal "foo", e.file
  end

  def test_no_file_uploaded
    e = Resource.new
    assert_nothing_raised { e.file =
        uploaded_file(nil, "application/octet-stream", "", :stringio) }
    assert_equal nil, e.file
  end
  
  # when safari submits a form where no file has been
  # selected, it does not transmit a content-type and
  # the result is an empty string ""
  def test_no_file_uploaded_with_safari
    e = Resource.new
    assert_nothing_raised { e.file = "" }
    assert_equal nil, e.file
  end

  def test_detect_wrong_encoding
    e = Resource.new
    assert_raise(TypeError) { e.file ="img42.jpg" }
  end
  
  def test_serializable_before_save
    e = Resource.new
    e.file = uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png")
    assert_nothing_raised { 
      flash = Marshal.dump(e) 
      e = Marshal.load(flash)
    }
    assert File.exists?(e.file)
  end
  
  def test_should_call_after_upload_on_new_upload
    Resource.file_column :file, :after_upload => [:after_assign]
    e = Resource.new
    e.file = upload(f("skanthak.png"))
    assert e.after_assign_called?
  end

  def test_should_call_user_after_save_on_save
    e = Resource.new(:file => upload(f("skanthak.png")))
    assert e.save
    
    assert_kind_of FileColumn::PermanentUploadedFile, e.send(:file_state)
    assert e.after_save_called?
  end
  
  def test_assign_standard_files
    e = Resource.new
    e.file = File.new(file_path('skanthak.png'))
    
    assert_equal 'skanthak.png', File.basename(e.file)
    assert FileUtils.identical?(file_path('skanthak.png'), e.file)
    
    assert e.save
  end
  
  def test_validates_filesize
    Resource.validates_filesize_of :file, :in => 50.kilobytes..100.kilobytes

    e = Resource.new(:file => upload(f("kerb.jpg")))
    assert e.save

    e.file = upload(f("skanthak.png"))
    assert !e.save
    assert e.errors.invalid?("file")
  end
  
  
  def test_validates_file_format_simple
    e = Resource.new(:file => upload(f("skanthak.png")))
    assert e.save
    
    Resource.validates_file_format_of :file, :in => ["jpg"]

    e.file = upload(f("kerb.jpg"))
    assert e.save

    e.file = upload(f("mysql.sql"))
    assert !e.save
    assert e.errors.invalid?("file")
    
  end

  def do_permission_test(uploaded_file, permissions=0641)
    Resource.file_column :file, :permissions => 0641
    
    e = Resource.new(:file => uploaded_file)
    assert e.save

    assert_equal 0641, (File.stat(e.file).mode & 0777)
  end

  def test_permissions_with_small_file
    do_permission_test upload(f("skanthak.png"), :guess, :stringio)
  end

  def test_permission_with_big_file
    do_permission_test upload(f("kerb.jpg"))
  end

  def test_permission_that_overrides_umask
    do_permission_test upload(f("skanthak.png"), :guess, :stringio), 0666
    do_permission_test upload(f("kerb.jpg")), 0666
  end

end


# Tests for moving temp dir to permanent dir
class FileColumnMoveTest < Test::Unit::TestCase
  
  def setup
    # we define the file_columns here so that we can change
    # settings easily in a single test

    Resource.file_column :file
    Homebase.current_homebase = Homebase.find(1)
  end
  
  def teardown
    FileUtils.rm_rf File.dirname(__FILE__)+"/public/entry/"
  end

  def test_should_move_additional_files_from_tmp
    e = Resource.new
    e.file = uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png")
    FileUtils.cp file_path("kerb.jpg"), File.dirname(e.file)
    assert e.save
    dir = File.dirname(e.file)
    assert File.exists?(File.join(dir, "skanthak.png"))
    assert File.exists?(File.join(dir, "kerb.jpg"))
  end

  def test_should_move_direcotries_on_save
    e = Resource.new(:file => upload(f("skanthak.png")))
    
    FileUtils.mkdir( e.file_dir+"/foo" )
    FileUtils.cp file_path("kerb.jpg"), e.file_dir+"/foo/kerb.jpg"
    
    assert e.save

    assert File.exists?(e.file)
    assert File.exists?(File.dirname(e.file)+"/foo/kerb.jpg")
  end

  def test_should_overwrite_dirs_with_files_on_reupload
    e = Resource.new(:file => upload(f("skanthak.png")))

    FileUtils.mkdir( e.file_dir+"/kerb.jpg")
    FileUtils.cp file_path("kerb.jpg"), e.file_dir+"/kerb.jpg/"
    assert e.save

    e.file = upload(f("kerb.jpg"))
    assert e.save

    assert File.file?(e.file_dir+"/kerb.jpg")
  end

  def test_should_overwrite_files_with_dirs_on_reupload
    e = Resource.new(:file => upload(f("skanthak.png")))

    assert e.save
    assert File.file?(e.file_dir+"/skanthak.png")

    e.file = upload(f("kerb.jpg"))
    FileUtils.mkdir(e.file_dir+"/skanthak.png")
    
    assert e.save
    assert File.file?(e.file_dir+"/kerb.jpg")
    assert !File.file?(e.file_dir+"/skanthak.png")
    assert File.directory?(e.file_dir+"/skanthak.png")
  end
  
  
  
  
  def test_assign_permalinks
    Homebase.current_homebase = Homebase.find(1)
    p = Project.new(:name => "New Project to test permalinks")
    assert_equal true, p.save
    p.reload
    assert_equal "new-project-to-test-permalinks", p.permalink
  end
  
  def test_assign_permalinks_in_homebase_scope
    Homebase.current_homebase = Homebase.find(1)
    p1 = Project.create(:name => "New Project With Permalinks")
    
    Homebase.current_homebase = Homebase.find(2)
    p2 = Project.create(:name => "New Project With Permalinks")
    
    Homebase.current_homebase = Homebase.find(1)
    p3 = Project.create(:name => "New Project With Permalinks")
    
    Homebase.current_homebase = Homebase.find(2)
    p4 = Project.create(:name => "New Project With Permalinks")
    
    p1.reload; p2.reload; p3.reload; p4.reload
    
    assert_equal "new-project-with-permalinks", p1.permalink
    assert_equal "new-project-with-permalinks", p2.permalink
    assert_equal "new-project-with-permalinks-2", p3.permalink
    assert_equal "new-project-with-permalinks-2", p4.permalink
  end

end

