class DocumentsController < ApplicationController
  # get document by id and email
  def document
    doc = Document.find_by(id: params['id'], uploaded_by: params['email'])
    if doc.present?
      render status: 200, json: doc.to_json
    else
      render status: 404, json: {
        "messages": "Document not found!"
      }
    end
  end

  # upload document, parse through text, and save document into database
  def upload
    # get vendor from form
    # TODO: add way to reliably find company name in receipt. Given the sample set, I could
    #     look at the same line after the invoice ID each time for company name,
    #     but that doesn't scale well as company name would not be in the same spot for all
    #     possible receipts. I would be interested in discussing ways to figure out company
    #     name in the technical interview
    doc = Document.new(vendor: params['vendor'], uploaded_by: params['email'])

    text = Pdftotext.text(params['file'])
    doc.fill_from_upload(text)

    if doc.save
      render status: 200, json: {
        "id": doc.id
      }
    else
      render status: 400, json: {
        "messages": doc.errors.full_messages
      }
    end
  end
end