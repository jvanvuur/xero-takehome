Rails.application.routes.draw do
  root "documents#documents"
  post 'upload' => "documents#upload"
end
