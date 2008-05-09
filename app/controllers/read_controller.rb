class ReadController < ApplicationController

  def read
    if request.post?
      @errors = []
      if params[:document_text].blank?
        @errors << "Document text missing"
      else
        document_text = params[:document_text]
      end
      if @errors.empty?
        begin
          @parse_results = Article.parse_text_document(document_text)
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
