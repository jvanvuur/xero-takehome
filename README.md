# xero-takehome

## Run Project
Use docker-compose to run the project. It will bring up two containers, a web app container and a database container.
```
  docker-compose up -d
  docker-compose run web rake db:create # Create databases.
  docker-compose run web rake db:migrate # Run migrations.
```
After running the above commands, the project can be found running at the following URL:
```
  http://localhost:3000/
```

## Important Files
```
# file that contains the routes
bills/config/routes.rb

# controller than handles the URL requests
bills/app/controllers/documents_controller.rb

# model that contains the logic around parsing documents
bills/app/models/document.rb

# file that contains the unit tests around parsing documents
/biles/spec/models/document_spec.rb

# files that contain the HTML and JS frontend code
/bills/app/views/documents/documents.html.erb
/bills/app/views/layouts/application.html.erb
```