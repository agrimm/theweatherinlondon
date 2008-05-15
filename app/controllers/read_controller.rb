class ReadController < ApplicationController

  def read
    @repository_choices = Repository.find(:all).map {|rc| [rc.short_description, rc.id]}
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
      if @errors.empty?
        begin
          @parse_results = Article.parse_text_document(document_text, repository)
        rescue ArgumentError => error
          if error.message == "Document has too many words"
            @errors << "Please submit a text fewer than #{Article.maximum_allowed_document_size} words long" 
          else
            raise
          end
        end
      end
    end
  end

end
