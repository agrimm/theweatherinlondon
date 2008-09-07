class ReadController < ApplicationController

  def read
    @repository_choices = Repository.find(:all).map {|rc| [rc.short_description, rc.id]}
    @default_repository_choice = params[:repository_id].to_i
    if params[:repository_id].nil?
      hard_wired_preference = "English language Wikipedia"
      @repository_choices.each do |short_description, id_number|
        if short_description == hard_wired_preference
          @default_repository_choice = id_number
        end
      end
    end
    @markup_choices = [ ["Auto-detect (default)", "auto-detect"], ["MediaWiki formatting", "mediawiki"], ["Plain text", "plain"] ]
    if request.post?
      @errors = []
      if params[:document_text].blank?
        @errors << "Document text missing"
      else
        document_text = params[:document_text]
      end
      repository = Repository.find(params[:repository_id])
      unless repository
        @errors << "Can't find repository"
      end
      markup = params[:markup]
      unless @markup_choices.map{|pair| pair.last}.include?(markup)
        @errors << "Invalid markup choice"
      end
      if @errors.empty?
        begin
          document = Article.new_document(document_text, repository, markup)
          @parse_results = document.parse
        rescue ArgumentError => error
          if error.message == "Document has too many words"
            @errors << "Please submit a text fewer than #{Repository.maximum_allowed_document_size} words long" 
          else
            raise
          end
        end
      end
    end
  end

end
