module Hashicorptools
  module Ec2Utilities
    def current_ami(tag = tag_name)
      amis(tag).first
    end

    def amis(tag = tag_name)
      sort_by_created_at(  ec2.images.with_owner('self').tagged(tag).to_a, tag )
    end

    def ec2
      ec2 = AWS::EC2.new
    end

    def image_created_at(image, tag= tag_name)
      if image
        image.tags.to_h[tag].to_i
      else
        0
      end
    end

    def sort_by_created_at(collection, tag = tag_name)
      collection.sort{|a, b| self.image_created_at(b, tag) <=> self.image_created_at(a, tag) }
    end
  end
end
