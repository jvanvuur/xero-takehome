Rails.application.routes.draw do
  root "documents#documents"
  post 'upload' => "documents#upload"
  get 'document/:id' => "documents#document"
end
