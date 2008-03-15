module FileColumn
  class PermanentUploadedFile
    
    def initialize(*args)
      super *args
      
      @dir = File.join(store_dir)
      @filename = @instance[@attr]
      @filename = nil if @filename.empty?
      
    end
    
    def relative_path_prefix
      @instance.homebase.subdomain.to_s
    end
    
    #def store_dir
    #  File.join(options[:root_path], @instance.homebase.subdomain.to_s, @instance.class.name.to_s.downcase)
    #end
  end
end