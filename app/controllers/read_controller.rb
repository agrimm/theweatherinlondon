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
        @parse_results = Article.parse_text_document(document_text)
      end
    end
  end

end
