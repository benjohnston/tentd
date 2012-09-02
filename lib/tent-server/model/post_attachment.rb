module TentServer
  module Model
    class PostAttachment
      include DataMapper::Resource

      storage_names[:default] = "post_attachments"

      property :id, Serial
      property :category, String
      property :type, String
      property :name, String
      property :data, BinaryString
      property :size, Integer
      timestamps :at

      belongs_to :post, 'TentServer::Model::Post'
    end
  end
end