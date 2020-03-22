class MoviesController < ApplicationController

  def index
    s3 = get_s3_resource
  end

  private
  def get_s3_resource
    region = 'ap-northeast-1'
    Aws::S3::Resource.new(
      region: region,
      credentials: Aws::Credentials.new(
          ENV['AWS_ACCESS_KEY'],
          ENV['AWS_SECRET_KEY']
      )
    )
  end
end
