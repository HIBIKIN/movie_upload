class S3filesController < ApplicationController

  def initialize
    super
    @region = 'ap-northeast-1'  # ①で作成したバケットのリージョン
    @bucketname = 'movie-upload-test'  # ①で作成したバケットの名前
    @s3 = get_s3_resource # S3リソースオブジェクトの生成
  end

  def new
    @s3file = S3file.new()
  end

  def create
    # ポストされたfileデータを取得
    file = params[:s3file]["key"]
    filename = file.original_filename

    #  一時保存用のパスにファイルを保存 
    file_path = "tmp/s3/#{filename}"
    File.binwrite(file_path, file.read)

    # バケット名を指定
    bucket = @s3.bucket(@bucketname)

    # バケットに保存する際の一意の識別名（ファイル名）を指定 
    key = filename
    # S3にアップロードする際に特定のディレクトリに入れたい場合は、filename の先頭に
    # ディレクトリ名を追加してください
    # 例：key = "dir1/dir2/#{filename}"）
    object = bucket.object(key)

    # upload_fileメソッドを使って、S3上のバケットにファイルをアップロードする 
    # 　第一引数 = 一時保存してあるファイルのパス 
    # 　第二引数 = オプション(aclはアクセス権) 
    object.upload_file(file_path, acl:'public-read')

    # アップロードしたファイルのキーをDBに保存 
    s3file = S3file.new(key: key)
    s3file.save

    redirect_to root_path
  end

  def destroy
    s3file = S3file.find(params[:id]) #テーブルからデータを取り出す
    key = s3file.key  # キー（ファイル名）取得 

    bucket = @s3.bucket(@backetname) # バケット指定
    object = bucket.object(key)  # キー指定
    object.delete  # オブジェクト（ファイル）削除

    s3file.destroy
    redirect_to s3files_path, flash: {notice: "ファイル [#{key}] を削除しました"}
  end

  private
    def get_s3_resource
      # Cloud9(EC2)使用の場合
      # Aws::S3::Resource.new(region: @region)

      # Cloud9(EC2)以外のサーバーを使用している場合
      Aws::S3::Resource.new(
        region: @region,
        credentials: Aws::Credentials.new(
            # 2-2.(3).2. で登録したアクセスキーとシークレットキー
            ENV['AWS_ACCESS_KEY'],
            ENV['AWS_SECRET_KEY']
            )
      )
    end
end
